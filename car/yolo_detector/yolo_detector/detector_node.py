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

class YoloDetectorNode(Node):
    def __init__(self):
        super().__init__('yolo_detector_node')
        
        # ROS2 Publishers
        self.pub_x = self.create_publisher(Int32, 'person_x', 10)
        self.pub_y = self.create_publisher(Int32, 'person_y', 10)
        self.pub_type = self.create_publisher(String, 'object_type', 10)
        self.pub_cap_status = self.create_publisher(Bool, 'accident_cap', 10)
        self.pub_test_beep = self.create_publisher(String, 'test_beep', 10)

        # ROS2 Subscriber
        self.sub_capture = self.create_subscription(
            Bool,
            'capture_command',
            self.capture_callback,
            10)

        self.sub_is_chatting = self.create_subscription(
            Bool,
            'is_chatting',
            self.is_chatting_callback,
            10)

        # is_chatting 상태 변수
        self.is_chatting = False
        self.prev_is_chatting = False

        # TensorRT 설정
        package_share_dir = get_package_share_directory('yolo_detector')
        engine_path = os.path.join(package_share_dir, 'models', 'best.engine')
        
        self.logger = trt.Logger(trt.Logger.ERROR)
        with open(engine_path, "rb") as f:
            runtime = trt.Runtime(self.logger)
            self.engine = runtime.deserialize_cuda_engine(f.read())
        
        self.trt_context = self.engine.create_execution_context()
        self.inputs, self.outputs, self.bindings, self.stream = self.allocate_buffers(self.engine)
        
        self.classes = ["desk", "lying", "others"]
        self.model_w = 224
        self.model_h = 224
        
        # 상태 변수
        self.current_frame = None
        self.save_path = os.path.expanduser('~/Downloads')
        
        # 트래킹 관련 변수
        self.next_object_id = 0
        self.objects = {}
        self.disappeared = {}
        self.max_disappeared = 15
        self.history = defaultdict(lambda: deque(maxlen=15))
        
        # 카메라 설정 및 테스트
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 224)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 160)
        
        self.timer = self.create_timer(0.05, self.inference_loop)
        self.get_logger().info('YOLOv11: Emergency Capture Mode Enabled.')
        
        # 카메라 초기화 테스트 (TTS 비프 후 실행)
        time.sleep(1.5)  # TTS 비프 2회 끝날 때까지 대기
        self.test_camera()

    def test_camera(self):
        """카메라 초기화 테스트"""
        ret, test_frame = self.cap.read()
        if ret:
            self.get_logger().info("✓✓✓ CAMERA INITIALIZED ✓✓✓")
            # 비프 요청
            beep_msg = String()
            beep_msg.data = "CAMERA_OK"
            self.pub_test_beep.publish(beep_msg)
        else:
            self.get_logger().error("✗✗✗ CAMERA FAILED ✗✗✗")

    def is_chatting_callback(self, msg):
        """is_chatting 토픽 콜백"""
        self.prev_is_chatting = self.is_chatting
        self.is_chatting = msg.data

        if self.is_chatting and not self.prev_is_chatting:
            self.get_logger().info('is_chatting=True: Publishing 10 "others"')
            for _ in range(10):
                self.pub_type.publish(String(data="others"))

    def capture_callback(self, msg):
        """capture_command 토픽이 True이면 캡처 수행"""
        if msg.data is True and self.current_frame is not None:
            file_name = os.path.join(self.save_path, "N0111.jpg")
            cv2.imwrite(file_name, self.current_frame)
            self.get_logger().info(f'Emergency Capture Saved: {file_name}')
            
            cap_msg = Bool()
            cap_msg.data = True
            self.pub_cap_status.publish(cap_msg)

    def allocate_buffers(self, engine):
        inputs, outputs, bindings = [], [], []
        stream = cuda.Stream()
        for i in range(engine.num_io_tensors):
            name = engine.get_tensor_name(i)
            shape = engine.get_tensor_shape(name)
            size = trt.volume(shape)
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

    def letterbox_224(self, frame):
        resized = cv2.resize(frame, (224, 160))
        canvas = np.zeros((224, 224, 3), dtype=np.uint8)
        y_offset = (224 - 160) // 2
        canvas[y_offset:y_offset+160, 0:224] = resized
        return canvas, y_offset

    def inference_loop(self):
        ret, frame = self.cap.read()
        if not ret: return

        input_canvas, pad_y = self.letterbox_224(frame)
        
        input_rgb = cv2.cvtColor(input_canvas, cv2.COLOR_BGR2RGB)
        input_data = input_rgb.transpose((2, 0, 1)).astype(np.float16) / 255.0
        input_data = np.ascontiguousarray(input_data)

        np.copyto(self.inputs[0]['host'], input_data.ravel())
        cuda.memcpy_htod_async(self.inputs[0]['device'], self.inputs[0]['host'], self.stream)
        self.trt_context.execute_async_v3(stream_handle=self.stream.handle)
        cuda.memcpy_dtoh_async(self.outputs[0]['host'], self.outputs[0]['device'], self.stream)
        self.stream.synchronize()

        output = self.outputs[0]['host'].reshape(7, -1)
        boxes, confs, class_ids, centroids = [], [], [], []

        probs = output[4:, :]
        max_probs = np.max(probs, axis=0)
        mask = max_probs > 0.70 
        candidates = output[:, mask]

        if candidates.shape[1] > 0:
            for i in range(candidates.shape[1]):
                cx, cy, w, h = candidates[:4, i]
                scores = candidates[4:, i]
                cls_id = np.argmax(scores)
                
                real_cx, real_cy = cx, cy - pad_y 
                bx, by = int(real_cx - w/2), int(real_cy - h/2)
                bw, bh = int(w), int(h)
                
                boxes.append([bx, by, bw, bh])
                confs.append(float(scores[cls_id]))
                class_ids.append(int(cls_id))

            indices = cv2.dnn.NMSBoxes(boxes, confs, 0.70, 0.4)
            final_detections = []
            if len(indices) > 0:
                for i in indices.flatten():
                    final_detections.append({
                        'box': boxes[i],
                        'class': class_ids[i],
                        'center': (boxes[i][0] + boxes[i][2]//2, boxes[i][1] + boxes[i][3]//2)
                    })
                    centroids.append(final_detections[-1]['center'])

            self.update_tracker(np.array(centroids))

            all_centers = []

            for objectID, object_center in self.objects.items():
                best_match = None
                min_dist = 50
                for det in final_detections:
                    dist = np.linalg.norm(np.array(object_center) - np.array(det['center']))
                    if dist < min_dist:
                        min_dist = dist
                        best_match = det

                if best_match:
                    self.history[objectID].append(best_match['class'])
                    recent = list(self.history[objectID])
                    stable_cls = max(set(recent), key=recent.count) if len(recent) > 5 else best_match['class']
                    
                    obj_name = self.classes[stable_cls]

                    if obj_name == "desk":
                        continue

                    all_centers.append(best_match['center'])

                    bx, by, bw, bh = best_match['box']
                    
                    if not self.is_chatting:
                        self.pub_type.publish(String(data=obj_name))

                    color = (0, 0, 255) if obj_name == "lying" else (0, 255, 0)
                    cv2.rectangle(input_canvas, (bx, by + pad_y), (bx+bw, by+bh+pad_y), color, 2)
                    cv2.putText(input_canvas, f"ID:{objectID} {obj_name}", (bx, by + pad_y - 10), 
                                cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

            if all_centers:
                avg_x = int(np.mean([c[0] for c in all_centers]))
                avg_y = int(np.mean([c[1] for c in all_centers]))
                self.pub_x.publish(Int32(data=avg_x))
                self.pub_y.publish(Int32(data=avg_y))

        self.current_frame = input_canvas.copy()

        cv2.imshow("Jetson YOLO 224x224 (Padded)", input_canvas)
        cv2.waitKey(1)

    def register(self, centroid):
        self.objects[self.next_object_id] = centroid
        self.disappeared[self.next_object_id] = 0
        self.next_object_id += 1

    def deregister(self, objectID):
        del self.objects[objectID]
        del self.disappeared[objectID]
        if objectID in self.history: del self.history[objectID]

    def update_tracker(self, centroids):
        if len(centroids) == 0:
            for objectID in list(self.disappeared.keys()):
                self.disappeared[objectID] += 1
                if self.disappeared[objectID] > self.max_disappeared:
                    self.deregister(objectID)
            return
        if len(self.objects) == 0:
            for i in range(len(centroids)):
                self.register(centroids[i])
        else:
            objectIDs = list(self.objects.keys())
            objectCentroids = list(self.objects.values())
            D = np.linalg.norm(np.array(objectCentroids)[:, np.newaxis] - centroids, axis=2)
            rows = D.min(axis=1).argsort()
            cols = D.argmin(axis=1)[rows]
            usedRows, usedCols = set(), set()
            for (row, col) in zip(rows, cols):
                if row in usedRows or col in usedCols: continue
                objectID = objectIDs[row]
                self.objects[objectID] = centroids[col]
                self.disappeared[objectID] = 0
                usedRows.add(row)
                usedCols.add(col)
            for row in set(range(D.shape[0])).difference(usedRows):
                objectID = objectIDs[row]
                self.disappeared[objectID] += 1
                if self.disappeared[objectID] > self.max_disappeared:
                    self.deregister(objectID)
            for col in set(range(D.shape[1])).difference(usedCols):
                self.register(centroids[col])

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