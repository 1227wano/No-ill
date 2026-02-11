#!/usr/bin/env python3
"""
YOLO 객체 감지 노드 (TensorRT 최적화)

기능:
- TensorRT 엔진을 사용한 실시간 객체 감지
- 3개 클래스: desk(책상), lying(누워있음), others(서있거나 앉음)
- 객체 추적 및 클래스 안정화
- 낙상 감지 시 자동 캡처

토픽:
- 발행: /person_x (Int32) - 감지된 사람들의 평균 X 좌표
       /person_y (Int32) - 감지된 사람들의 평균 Y 좌표
       /object_type (String) - 감지된 객체 타입
       /accident_cap (Bool) - 캡처 완료 상태
       /test_beep (String) - 카메라 초기화 비프
- 구독: /capture_command (Bool) - 캡처 명령
       /is_chatting (Bool) - 대화 상태
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import Int32, String, Bool
import cv2
import numpy as np
import os
import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit
from ament_index_python.packages import get_package_share_directory
from collections import deque, defaultdict
import time
from typing import List, Dict, Tuple, Optional


class YoloDetectorNode(Node):
    """TensorRT 기반 YOLO 객체 감지 및 추적 노드"""

    # 클래스 상수
    CLASSES = ["desk", "lying", "others"]
    MODEL_WIDTH = 224
    MODEL_HEIGHT = 224
    CAMERA_WIDTH = 224
    CAMERA_HEIGHT = 160

    # 감지 파라미터
    CONFIDENCE_THRESHOLD = 0.70
    NMS_THRESHOLD = 0.4
    MAX_DISAPPEARED = 15
    HISTORY_SIZE = 15
    STABLE_CLASS_MIN = 5
    TRACKER_DISTANCE_THRESHOLD = 50

    def __init__(self):
        super().__init__('yolo_detector_node')

        # 상태 변수 초기화
        self.is_chatting = False
        self.prev_is_chatting = False
        self.current_frame = None
        self.save_path = os.path.expanduser('~/Downloads')

        # 추적 변수 초기화
        self.next_object_id = 0
        self.objects: Dict[int, Tuple[int, int]] = {}
        self.disappeared: Dict[int, int] = {}
        self.history = defaultdict(lambda: deque(maxlen=self.HISTORY_SIZE))

        # ROS2 초기화
        self._init_publishers()
        self._init_subscribers()

        # TensorRT 엔진 로드
        self._init_tensorrt()

        # 카메라 초기화
        self._init_camera()

        # 메인 타이머 (20Hz)
        self.timer = self.create_timer(0.05, self.inference_loop)

        self.get_logger().info(
            f'[YOLO] Started | model={self.MODEL_WIDTH}x{self.MODEL_HEIGHT} | '
            f'classes={",".join(self.CLASSES)}'
        )

        # 카메라 테스트 (TTS 비프 후)
        time.sleep(1.5)
        self._test_camera()

    # =====================================================
    # 초기화 함수들
    # =====================================================

    def _init_publishers(self):
        """ROS2 퍼블리셔 초기화"""
        self.pub_x = self.create_publisher(Int32, 'person_x', 10)
        self.pub_y = self.create_publisher(Int32, 'person_y', 10)
        self.pub_type = self.create_publisher(String, 'object_type', 10)
        self.pub_cap_status = self.create_publisher(Bool, 'accident_cap', 10)
        self.pub_test_beep = self.create_publisher(String, 'test_beep', 10)

    def _init_subscribers(self):
        """ROS2 서브스크라이버 초기화"""
        self.sub_capture = self.create_subscription(
            Bool,
            'capture_command',
            self._capture_callback,
            10
        )

        self.sub_is_chatting = self.create_subscription(
            Bool,
            'is_chatting',
            self._is_chatting_callback,
            10
        )

    def _init_tensorrt(self):
        """TensorRT 엔진 초기화"""
        package_share_dir = get_package_share_directory('yolo_detector')
        engine_path = os.path.join(package_share_dir, 'models', 'best.engine')

        if not os.path.exists(engine_path):
            self.get_logger().error(f'TensorRT engine not found: {engine_path}')
            raise FileNotFoundError(f'TensorRT engine not found: {engine_path}')

        self.get_logger().info(f'Loading TensorRT engine: {engine_path}')

        # TensorRT 로거 및 런타임
        self.logger = trt.Logger(trt.Logger.ERROR)

        with open(engine_path, "rb") as f:
            runtime = trt.Runtime(self.logger)
            self.engine = runtime.deserialize_cuda_engine(f.read())

        self.trt_context = self.engine.create_execution_context()

        # CUDA 버퍼 할당
        self.inputs, self.outputs, self.bindings, self.stream = self._allocate_buffers(self.engine)

        self.get_logger().info('✓ TensorRT engine loaded successfully')

    def _allocate_buffers(self, engine):
        """CUDA 버퍼 할당"""
        inputs, outputs, bindings = [], [], []
        stream = cuda.Stream()

        for i in range(engine.num_io_tensors):
            name = engine.get_tensor_name(i)
            shape = engine.get_tensor_shape(name)
            size = trt.volume(shape)
            dtype = trt.nptype(engine.get_tensor_dtype(name))

            # 호스트 및 디바이스 메모리 할당
            host_mem = cuda.pagelocked_empty(size, dtype)
            device_mem = cuda.mem_alloc(host_mem.nbytes)
            bindings.append(int(device_mem))

            # 입출력 구분
            if engine.get_tensor_mode(name) == trt.TensorIOMode.INPUT:
                inputs.append({'host': host_mem, 'device': device_mem})
            else:
                outputs.append({'host': host_mem, 'device': device_mem})

            self.trt_context.set_tensor_address(name, int(device_mem))

        return inputs, outputs, bindings, stream

    def _init_camera(self):
        """카메라 초기화"""
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.CAMERA_WIDTH)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.CAMERA_HEIGHT)

        if not self.cap.isOpened():
            self.get_logger().error('Failed to open camera')
            raise RuntimeError('Failed to open camera')

    def _test_camera(self):
        """카메라 초기화 테스트"""
        ret, test_frame = self.cap.read()

        if ret:
            self.get_logger().info('[YOLO] Camera OK')

            # 비프 요청
            beep_msg = String()
            beep_msg.data = "CAMERA_OK"
            self.pub_test_beep.publish(beep_msg)
        else:
            self.get_logger().error('[YOLO] Camera FAILED')

    # =====================================================
    # 콜백 함수들
    # =====================================================

    def _is_chatting_callback(self, msg: Bool):
        """대화 상태 콜백
        
        대화 시작 시 "others"를 10회 발행하여
        person_override_node가 추적을 멈추도록 함
        """
        self.prev_is_chatting = self.is_chatting
        self.is_chatting = msg.data

        # 대화 시작 시점
        if self.is_chatting and not self.prev_is_chatting:
            self.get_logger().info('[YOLO] Chat mode, publishing "others"')

            others_msg = String()
            others_msg.data = "others"

            for _ in range(10):
                self.pub_type.publish(others_msg)

    def _capture_callback(self, msg: Bool):
        """응급 캡처 콜백
        
        낙상 감지 시 emergency_response_node가 요청
        """
        if msg.data and self.current_frame is not None:
            file_name = os.path.join(self.save_path, "N0111.jpg")
            cv2.imwrite(file_name, self.current_frame)

            self.get_logger().info(f'[YOLO] Captured: {file_name}')

            # 캡처 완료 알림
            cap_msg = Bool()
            cap_msg.data = True
            self.pub_cap_status.publish(cap_msg)

    # =====================================================
    # 추론 및 감지
    # =====================================================

    def inference_loop(self):
        """메인 추론 루프 (20Hz)"""
        # 프레임 읽기
        ret, frame = self.cap.read()
        if not ret:
            return

        # 전처리
        input_canvas, pad_y = self._letterbox_transform(frame)
        input_data = self._preprocess_frame(input_canvas)

        # TensorRT 추론
        output = self._run_inference(input_data)

        # 후처리 및 감지
        detections = self._postprocess_output(output, pad_y)

        # 객체 추적 및 발행
        self._track_and_publish(detections, input_canvas, pad_y)

        # 현재 프레임 저장 (캡처용)
        self.current_frame = input_canvas.copy()

        # 시각화 (개발용)
        self._display_frame(input_canvas)

    def _letterbox_transform(self, frame: np.ndarray) -> Tuple[np.ndarray, int]:
        """레터박스 변환 (224x160 → 224x224)"""
        resized = cv2.resize(frame, (self.CAMERA_WIDTH, self.CAMERA_HEIGHT))

        # 검은색 캔버스 생성
        canvas = np.zeros((self.MODEL_HEIGHT, self.MODEL_WIDTH, 3), dtype=np.uint8)

        # 중앙에 배치
        y_offset = (self.MODEL_HEIGHT - self.CAMERA_HEIGHT) // 2
        canvas[y_offset:y_offset+self.CAMERA_HEIGHT, 0:self.CAMERA_WIDTH] = resized

        return canvas, y_offset

    def _preprocess_frame(self, frame: np.ndarray) -> np.ndarray:
        """프레임 전처리 (정규화 및 CHW 변환)"""
        # BGR → RGB
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # HWC → CHW, 정규화
        data = rgb.transpose((2, 0, 1)).astype(np.float16) / 255.0

        return np.ascontiguousarray(data)

    def _run_inference(self, input_data: np.ndarray) -> np.ndarray:
        """TensorRT 추론 실행"""
        # 입력 데이터 복사
        np.copyto(self.inputs[0]['host'], input_data.ravel())

        # H2D 복사
        cuda.memcpy_htod_async(
            self.inputs[0]['device'],
            self.inputs[0]['host'],
            self.stream
        )

        # 추론 실행
        self.trt_context.execute_async_v3(stream_handle=self.stream.handle)

        # D2H 복사
        cuda.memcpy_dtoh_async(
            self.outputs[0]['host'],
            self.outputs[0]['device'],
            self.stream
        )

        # 동기화
        self.stream.synchronize()

        # 출력 reshape (7, N)
        output = self.outputs[0]['host'].reshape(7, -1)

        return output

    def _postprocess_output(
            self,
            output: np.ndarray,
            pad_y: int
    ) -> List[Dict]:
        """출력 후처리 및 NMS"""
        boxes, confs, class_ids, centroids = [], [], [], []

        # 클래스 확률 (4:7, N)
        probs = output[4:, :]
        max_probs = np.max(probs, axis=0)

        # 신뢰도 필터링
        mask = max_probs > self.CONFIDENCE_THRESHOLD
        candidates = output[:, mask]

        if candidates.shape[1] == 0:
            return []

        # 바운딩 박스 추출
        for i in range(candidates.shape[1]):
            cx, cy, w, h = candidates[:4, i]
            scores = candidates[4:, i]
            cls_id = np.argmax(scores)

            # 패딩 보정
            real_cx, real_cy = cx, cy - pad_y

            bx = int(real_cx - w/2)
            by = int(real_cy - h/2)
            bw = int(w)
            bh = int(h)

            boxes.append([bx, by, bw, bh])
            confs.append(float(scores[cls_id]))
            class_ids.append(int(cls_id))

        # NMS
        indices = cv2.dnn.NMSBoxes(
            boxes,
            confs,
            self.CONFIDENCE_THRESHOLD,
            self.NMS_THRESHOLD
        )

        # 최종 감지 결과
        detections = []
        if len(indices) > 0:
            for i in indices.flatten():
                center = (
                    boxes[i][0] + boxes[i][2] // 2,
                    boxes[i][1] + boxes[i][3] // 2
                )

                detections.append({
                    'box': boxes[i],
                    'class': class_ids[i],
                    'conf': confs[i],
                    'center': center
                })

        return detections

    # =====================================================
    # 객체 추적
    # =====================================================

    def _track_and_publish(
            self,
            detections: List[Dict],
            canvas: np.ndarray,
            pad_y: int
    ):
        """객체 추적 및 결과 발행"""
        if not detections:
            # 감지 없음: 사라진 객체 처리
            self._handle_disappeared()
            return

        # 중심점 추출
        centroids = np.array([det['center'] for det in detections])

        # 추적 업데이트
        self._update_tracker(centroids)

        # 매칭 및 발행
        all_centers = []

        for object_id, object_center in self.objects.items():
            # 가장 가까운 감지 결과 찾기
            best_match = self._find_best_match(object_center, detections)

            if best_match is None:
                continue

            # 히스토리 업데이트
            self.history[object_id].append(best_match['class'])

            # 안정화된 클래스 결정
            stable_class = self._get_stable_class(object_id, best_match['class'])
            obj_name = self.CLASSES[stable_class]

            # 책상은 무시
            if obj_name == "desk":
                continue

            all_centers.append(best_match['center'])

            # 객체 타입 발행 (대화 중이 아닐 때만)
            if not self.is_chatting:
                type_msg = String()
                type_msg.data = obj_name
                self.pub_type.publish(type_msg)

            # 시각화
            self._draw_detection(
                canvas,
                best_match['box'],
                object_id,
                obj_name,
                pad_y
            )

        # 평균 좌표 발행
        if all_centers:
            avg_x = int(np.mean([c[0] for c in all_centers]))
            avg_y = int(np.mean([c[1] for c in all_centers]))

            self.pub_x.publish(Int32(data=avg_x))
            self.pub_y.publish(Int32(data=avg_y))

    def _find_best_match(
            self,
            object_center: Tuple[int, int],
            detections: List[Dict]
    ) -> Optional[Dict]:
        """가장 가까운 감지 결과 찾기"""
        best_match = None
        min_dist = self.TRACKER_DISTANCE_THRESHOLD

        for det in detections:
            dist = np.linalg.norm(
                np.array(object_center) - np.array(det['center'])
            )

            if dist < min_dist:
                min_dist = dist
                best_match = det

        return best_match

    def _get_stable_class(self, object_id: int, current_class: int) -> int:
        """히스토리 기반 안정화된 클래스 반환"""
        recent = list(self.history[object_id])

        if len(recent) > self.STABLE_CLASS_MIN:
            # 다수결
            return max(set(recent), key=recent.count)
        else:
            # 히스토리 부족 시 현재 클래스
            return current_class

    def _handle_disappeared(self):
        """사라진 객체 처리"""
        for object_id in list(self.disappeared.keys()):
            self.disappeared[object_id] += 1

            if self.disappeared[object_id] > self.MAX_DISAPPEARED:
                self._deregister(object_id)

    def _update_tracker(self, centroids: np.ndarray):
        """객체 추적 업데이트 (헝가리안 알고리즘)"""
        # 감지 없음
        if len(centroids) == 0:
            self._handle_disappeared()
            return

        # 추적 객체 없음: 모두 등록
        if len(self.objects) == 0:
            for i in range(len(centroids)):
                self._register(centroids[i])
            return

        # 거리 행렬 계산
        object_ids = list(self.objects.keys())
        object_centroids = np.array(list(self.objects.values()))

        D = np.linalg.norm(
            object_centroids[:, np.newaxis] - centroids,
            axis=2
        )

        # 헝가리안 매칭
        rows = D.min(axis=1).argsort()
        cols = D.argmin(axis=1)[rows]

        used_rows, used_cols = set(), set()

        for (row, col) in zip(rows, cols):
            if row in used_rows or col in used_cols:
                continue

            object_id = object_ids[row]
            self.objects[object_id] = tuple(centroids[col])
            self.disappeared[object_id] = 0

            used_rows.add(row)
            used_cols.add(col)

        # 매칭 안 된 추적 객체: disappeared 증가
        for row in set(range(D.shape[0])).difference(used_rows):
            object_id = object_ids[row]
            self.disappeared[object_id] += 1

            if self.disappeared[object_id] > self.MAX_DISAPPEARED:
                self._deregister(object_id)

        # 매칭 안 된 감지 결과: 새로 등록
        for col in set(range(D.shape[1])).difference(used_cols):
            self._register(centroids[col])

    def _register(self, centroid: np.ndarray):
        """새 객체 등록"""
        self.objects[self.next_object_id] = tuple(centroid)
        self.disappeared[self.next_object_id] = 0
        self.next_object_id += 1

    def _deregister(self, object_id: int):
        """객체 등록 해제"""
        del self.objects[object_id]
        del self.disappeared[object_id]

        if object_id in self.history:
            del self.history[object_id]

    # =====================================================
    # 시각화
    # =====================================================

    def _draw_detection(
            self,
            canvas: np.ndarray,
            box: List[int],
            object_id: int,
            obj_name: str,
            pad_y: int
    ):
        """감지 결과 그리기"""
        bx, by, bw, bh = box

        # 색상: lying=빨강, others=초록
        color = (0, 0, 255) if obj_name == "lying" else (0, 255, 0)

        # 바운딩 박스
        cv2.rectangle(
            canvas,
            (bx, by + pad_y),
            (bx + bw, by + bh + pad_y),
            color,
            2
        )

        # 라벨
        label = f"ID:{object_id} {obj_name}"
        cv2.putText(
            canvas,
            label,
            (bx, by + pad_y - 10),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            color,
            2
        )

    def _display_frame(self, canvas: np.ndarray):
        """프레임 표시 (개발용, 디스플레이 있을 때만)"""
        if os.environ.get('DISPLAY'):
            try:
                cv2.imshow("Jetson YOLO 224x224 (Padded)", canvas)
                cv2.waitKey(1)
            except cv2.error:
                pass

    # =====================================================
    # 정리
    # =====================================================

    def __del__(self):
        """소멸자: 리소스 해제"""
        if hasattr(self, 'cap'):
            self.cap.release()

        # CUDA 메모리 해제
        if hasattr(self, 'inputs'):
            for inp in self.inputs:
                if hasattr(inp['device'], 'free'):
                    inp['device'].free()

        if hasattr(self, 'outputs'):
            for out in self.outputs:
                if hasattr(out['device'], 'free'):
                    out['device'].free()

        if os.environ.get('DISPLAY'):
            cv2.destroyAllWindows()


def main(args=None):
    rclpy.init(args=args)
    node = YoloDetectorNode()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
