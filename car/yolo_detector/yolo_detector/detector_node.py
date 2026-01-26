import rclpy
from rclpy.node import Node
from std_msgs.msg import Float32, String
import cv2
import numpy as np
import os
import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit
from ament_index_python.packages import get_package_share_directory

class YoloDetectorNode(Node):
    def __init__(self):
        super().__init__('yolo_detector_node')
        
        # 토픽 발행자 설정
        self.pub_x = self.create_publisher(Float32, 'person_x', 10)
        self.pub_y = self.create_publisher(Float32, 'person_y', 10)
        self.pub_type = self.create_publisher(String, 'object_type', 10)

        # 모델 경로 설정 및 TensorRT 엔진 로드
        package_share_dir = get_package_share_directory('yolo_detector')
        engine_path = os.path.join(package_share_dir, 'models', 'best.engine')
        
        self.logger = trt.Logger(trt.Logger.ERROR)
        with open(engine_path, "rb") as f:
            runtime = trt.Runtime(self.logger)
            self.engine = runtime.deserialize_cuda_engine(f.read())
        
        self.trt_context = self.engine.create_execution_context()
        
        # [카메라 설정] 160x120 해상도 고정
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 160)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 120)
        self.cap.set(cv2.CAP_PROP_FPS, 30)
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

        # 버퍼 및 클래스 정의
        self.inputs, self.outputs, self.bindings, self.stream = self.allocate_buffers(self.engine)
        self.classes = ["Lying", "others"] 
        self.input_w, self.input_h = 160, 160 # 모델 학습 크기
        
        # 30 FPS 수준으로 타이머 실행 (0.033초)
        self.timer = self.create_timer(0.033, self.inference_loop)
        self.get_logger().info('YOLO Detector: 160x120 Input -> 160x160 TRT Inference Start.')

    def allocate_buffers(self, engine):
        inputs, outputs, bindings = [], [], []
        stream = cuda.Stream()
        for i in range(engine.num_io_tensors):
            name = engine.get_tensor_name(i)
            size = trt.volume(engine.get_tensor_shape(name))
            dtype = trt.nptype(engine.get_tensor_dtype(name))
            host_mem = cuda.pagelocked_empty(size, dtype)
            device_mem = cuda.mem_alloc(host_mem.nbytes)
            bindings.append(int(device_mem))
            if engine.get_tensor_mode(name) == trt.TensorIOMode.INPUT:
                inputs.append({'host': host_mem, 'device': device_mem})
            else:
                outputs.append({'host': host_mem, 'device': device_mem})
            self.trt_context.set_tensor_address(name, int(device_mem))
        return inputs, outputs, bindings, stream

    def inference_loop(self):
        ret, frame = self.cap.read()
        if not ret: return

        raw_h, raw_w = frame.shape[:2] # 120, 160
        
        # 1. 전처리: 160x120 -> 160x160 리사이즈 및 정규화
        input_image = cv2.resize(frame, (self.input_w, self.input_h))
        input_image = cv2.cvtColor(input_image, cv2.COLOR_BGR2RGB)
        input_image = input_image.transpose((2, 0, 1)).astype(np.float32) / 255.0
        input_data = np.ascontiguousarray(input_image)

        # 2. 추론 실행
        np.copyto(self.inputs[0]['host'], input_data.ravel())
        cuda.memcpy_htod_async(self.inputs[0]['device'], self.inputs[0]['host'], self.stream)
        self.trt_context.execute_async_v3(stream_handle=self.stream.handle)
        cuda.memcpy_dtoh_async(self.outputs[0]['host'], self.outputs[0]['device'], self.stream)
        self.stream.synchronize()

        # 3. 후처리: [6, 525] 출력 해석
        output = self.outputs[0]['host'].reshape(6, 525)
        conf_scores = np.max(output[4:, :], axis=0)
        conf_mask = conf_scores > 0.45
        filtered_output = output[:, conf_mask]

        if filtered_output.shape[1] > 0:
            boxes, confs, class_ids = [], [], []
            for i in range(filtered_output.shape[1]):
                scores = filtered_output[4:, i]
                class_id = np.argmax(scores)
                cx, cy, w, h = filtered_output[:4, i]
                
                # 좌표 복원 (160x160 추론 좌표 -> 160x120 영상 좌표)
                bx = int((cx - w/2) * (raw_w / self.input_w))
                by = int((cy - h/2) * (raw_h / self.input_h))
                bw = int(w * (raw_w / self.input_w))
                bh = int(h * (raw_h / self.input_h))
                
                boxes.append([bx, by, bw, bh])
                confs.append(float(scores[class_id]))
                class_ids.append(int(class_id))

            # NMS(Non-Maximum Suppression) 적용
            indices = cv2.dnn.NMSBoxes(boxes, confs, 0.45, 0.4)
            if len(indices) > 0:
                for i in indices.flatten():
                    bx, by, bw, bh = boxes[i]
                    
                    # 4점의 평균 = 중앙 좌표 계산
                    center_x = float(bx + (bw / 2))
                    center_y = float(by + (bh / 2))
                    obj_name = self.classes[class_ids[i]]

                    # ROS2 토픽 발행
                    self.pub_x.publish(Float32(data=center_x))
                    self.pub_y.publish(Float32(data=center_y))
                    self.pub_type.publish(String(data=obj_name))

                    # 디버깅용 시각화
                    cv2.rectangle(frame, (bx, by), (bx+bw, by+bh), (0, 255, 0), 2)
                    cv2.circle(frame, (int(center_x), int(center_y)), 3, (0, 0, 255), -1)
                    cv2.putText(frame, f"{obj_name}", (bx, by-5), 
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)

        cv2.imshow("Detection (160x120)", frame)
        cv2.waitKey(1)

    def __del__(self):
        if hasattr(self, 'cap'): self.cap.release()
        cv2.destroyAllWindows()

def main(args=None):
    rclpy.init(args=args)
    node = YoloDetectorNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt: pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
