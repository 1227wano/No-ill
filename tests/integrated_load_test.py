#!/usr/bin/env python3
"""
Jetson Orin Nano 통합 부하 테스트
- 2D 라이다 주행 시뮬레이션
- 화상통화 (영상 스트리밍)
- 객체 인식 모델
- STT/TTS 모델

모든 기능을 동시에 실행하여 리소스 부하를 측정합니다.

설정 변경: config.py 파일을 수정하세요.
"""

import threading
import time
import os
import sys
from dataclasses import dataclass
from typing import Optional
import argparse

# 설정 파일 로드
try:
    from config import (
        GPU_MEMORY_FRACTION,
        OBJECT_DETECTION,
        STT,
        TTS_CONFIG,
        VIDEO,
        LIDAR,
        TEST_TEXTS,
    )
    print("[Config] config.py 로드 완료")
except ImportError:
    print("[Config] config.py 없음 - 기본 설정 사용")
    GPU_MEMORY_FRACTION = 0.375
    OBJECT_DETECTION = {"type": "yolo", "yolo_model": "yolov8n.pt", "input_size": (640, 640), "inference_interval": 0.1}
    STT = {"type": "whisper", "whisper_model": "base", "language": "ko", "process_interval": 3.0}
    TTS_CONFIG = {"type": "coqui", "coqui_model": "tts_models/ko/css10/vits", "synthesis_interval": 2.0}
    VIDEO = {"source": None, "width": 1280, "height": 720, "target_fps": 30}
    LIDAR = {"scan_rate": 10, "num_points": 360, "max_range": 10.0, "use_ros2": False}
    TEST_TEXTS = ["안녕하세요.", "오늘 기분이 어떠세요?", "도움이 필요하시면 말씀해주세요."]


@dataclass
class ResourceUsage:
    cpu_percent: float
    memory_mb: float
    gpu_memory_mb: float
    gpu_util_percent: float


class ResourceMonitor:
    """리소스 사용량 모니터링"""

    def __init__(self):
        self.running = False
        self.history = []

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._monitor_loop)
        self.thread.start()

    def stop(self):
        self.running = False
        self.thread.join()

    def _monitor_loop(self):
        try:
            import psutil
            import pynvml
            pynvml.nvmlInit()
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
        except ImportError:
            print("[Monitor] psutil 또는 pynvml이 설치되지 않음. 모니터링 비활성화.")
            return
        except Exception as e:
            print(f"[Monitor] GPU 모니터링 초기화 실패: {e}")
            return

        while self.running:
            try:
                cpu = psutil.cpu_percent()
                mem = psutil.Process().memory_info().rss / 1024 / 1024
                mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
                util = pynvml.nvmlDeviceGetUtilizationRates(handle)

                usage = ResourceUsage(
                    cpu_percent=cpu,
                    memory_mb=mem,
                    gpu_memory_mb=mem_info.used / 1024 / 1024,
                    gpu_util_percent=util.gpu
                )
                self.history.append(usage)

                print(f"\r[Resource] CPU: {cpu:5.1f}% | RAM: {mem:7.1f}MB | "
                      f"GPU Mem: {mem_info.used/1024/1024:7.1f}MB | GPU Util: {util.gpu:3d}%",
                      end="", flush=True)
            except Exception as e:
                pass
            time.sleep(1)

        pynvml.nvmlShutdown()

    def get_summary(self):
        if not self.history:
            return None
        return {
            "cpu_avg": sum(h.cpu_percent for h in self.history) / len(self.history),
            "cpu_max": max(h.cpu_percent for h in self.history),
            "memory_avg_mb": sum(h.memory_mb for h in self.history) / len(self.history),
            "memory_max_mb": max(h.memory_mb for h in self.history),
            "gpu_memory_avg_mb": sum(h.gpu_memory_mb for h in self.history) / len(self.history),
            "gpu_memory_max_mb": max(h.gpu_memory_mb for h in self.history),
            "gpu_util_avg": sum(h.gpu_util_percent for h in self.history) / len(self.history),
            "gpu_util_max": max(h.gpu_util_percent for h in self.history),
        }


class LidarSimulator:
    """2D 라이다 주행 시뮬레이션"""

    def __init__(self):
        self.running = False
        self.scan_count = 0
        self.config = LIDAR

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._run)
        self.thread.start()
        print(f"[Lidar] 시작 (rate: {self.config['scan_rate']}Hz)")

    def stop(self):
        self.running = False
        self.thread.join()
        print(f"[Lidar] 종료 - 총 {self.scan_count} 스캔 처리")

    def _run(self):
        import numpy as np
        interval = 1.0 / self.config['scan_rate']

        while self.running:
            angles = np.linspace(0, 2 * np.pi, self.config['num_points'])
            distances = np.random.uniform(0.5, self.config['max_range'], self.config['num_points'])
            obstacles = distances[distances < 1.0]

            # 경로 계획 시뮬레이션
            grid = np.zeros((100, 100))
            for i in range(10):
                x, y = np.random.randint(0, 100, 2)
                grid[x, y] = 1
            path_cost = np.sum(grid) + np.random.random() * 10

            self.scan_count += 1
            time.sleep(interval)


class VideoStreamer:
    """화상통화 영상 스트리밍 시뮬레이션"""

    def __init__(self):
        self.running = False
        self.frame_count = 0
        self.config = VIDEO

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._run)
        self.thread.start()
        print(f"[Video] 시작 (target: {self.config['target_fps']}fps, {self.config['width']}x{self.config['height']})")

    def stop(self):
        self.running = False
        self.thread.join()
        print(f"[Video] 종료 - 총 {self.frame_count} 프레임 처리")

    def _run(self):
        import numpy as np
        try:
            import cv2
            use_cv2 = True
        except ImportError:
            use_cv2 = False
            print("[Video] OpenCV 없음 - 더미 프레임 사용")

        cap = None
        source = self.config.get('source') or self.config.get('test_video')
        if use_cv2 and source:
            cap = cv2.VideoCapture(source)
            if cap.isOpened():
                print(f"[Video] 영상 소스 로드: {source}")

        interval = 1.0 / self.config['target_fps']

        while self.running:
            if cap and cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                    continue
            else:
                frame = np.random.randint(0, 255,
                    (self.config['height'], self.config['width'], 3), dtype=np.uint8)

            if use_cv2:
                _, encoded = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
            else:
                encoded = frame.tobytes()[:10000]

            self.frame_count += 1
            time.sleep(interval)

        if cap:
            cap.release()


class ObjectDetector:
    """객체 인식 모델"""

    def __init__(self):
        self.running = False
        self.detection_count = 0
        self.model = None
        self.config = OBJECT_DETECTION

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._run)
        self.thread.start()
        print(f"[ObjectDetection] 시작 (type: {self.config['type']})")

    def stop(self):
        self.running = False
        self.thread.join()
        print(f"[ObjectDetection] 종료 - 총 {self.detection_count} 추론 수행")

    def _load_model(self):
        try:
            import torch
            torch.cuda.set_per_process_memory_fraction(GPU_MEMORY_FRACTION)

            if self.config['type'] == 'yolo':
                from ultralytics import YOLO
                model_path = self.config['yolo_model']
                self.model = YOLO(model_path)
                print(f"[ObjectDetection] YOLO 모델 로드: {model_path}")

            elif self.config['type'] == 'custom_torch':
                model_path = self.config['custom_model_path']
                self.model = torch.load(model_path)
                self.model.eval()
                if torch.cuda.is_available():
                    self.model = self.model.cuda()
                print(f"[ObjectDetection] 커스텀 PyTorch 모델 로드: {model_path}")

            elif self.config['type'] == 'custom_tflite':
                import tensorflow as tf
                model_path = self.config['tflite_model_path']
                self.model = tf.lite.Interpreter(model_path=model_path)
                self.model.allocate_tensors()
                print(f"[ObjectDetection] TFLite 모델 로드: {model_path}")

            return True
        except Exception as e:
            print(f"[ObjectDetection] 모델 로드 실패: {e}")
            print("[ObjectDetection] 더미 모드로 실행")
            return False

    def _run(self):
        import numpy as np
        model_loaded = self._load_model()
        input_size = self.config['input_size']
        interval = self.config['inference_interval']

        while self.running:
            dummy_image = np.random.randint(0, 255, (input_size[0], input_size[1], 3), dtype=np.uint8)

            if model_loaded and self.model:
                if self.config['type'] == 'yolo':
                    results = self.model(dummy_image, verbose=False)
                elif self.config['type'] == 'custom_torch':
                    import torch
                    with torch.no_grad():
                        x = torch.from_numpy(dummy_image).permute(2, 0, 1).unsqueeze(0).float()
                        if torch.cuda.is_available():
                            x = x.cuda()
                        _ = self.model(x)
                elif self.config['type'] == 'custom_tflite':
                    input_details = self.model.get_input_details()
                    self.model.set_tensor(input_details[0]['index'],
                        dummy_image.astype(np.float32)[np.newaxis, ...])
                    self.model.invoke()
            else:
                # 더미 GPU 부하
                try:
                    import torch
                    if torch.cuda.is_available():
                        x = torch.randn(1, 3, input_size[0], input_size[1]).cuda()
                        for _ in range(10):
                            x = torch.nn.functional.conv2d(x, torch.randn(64, 3, 3, 3).cuda(), padding=1)
                        del x
                        torch.cuda.synchronize()
                except:
                    pass

            self.detection_count += 1
            time.sleep(interval)


class STTService:
    """STT (Speech-to-Text) 서비스"""

    def __init__(self):
        self.running = False
        self.transcription_count = 0
        self.model = None
        self.config = STT

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._run)
        self.thread.start()
        print(f"[STT] 시작 (type: {self.config['type']})")

    def stop(self):
        self.running = False
        self.thread.join()
        print(f"[STT] 종료 - 총 {self.transcription_count} 변환 수행")

    def _load_model(self):
        try:
            import torch
            torch.cuda.set_per_process_memory_fraction(GPU_MEMORY_FRACTION)

            if self.config['type'] == 'whisper':
                import whisper
                model_size = self.config['whisper_model']
                self.model = whisper.load_model(model_size)
                print(f"[STT] Whisper {model_size} 모델 로드 완료")

            elif self.config['type'] == 'custom':
                model_path = self.config['custom_model_path']
                self.model = torch.load(model_path)
                self.model.eval()
                if torch.cuda.is_available():
                    self.model = self.model.cuda()
                print(f"[STT] 커스텀 모델 로드: {model_path}")

            return True
        except Exception as e:
            print(f"[STT] 모델 로드 실패: {e}")
            print("[STT] 더미 모드로 실행")
            return False

    def _run(self):
        import numpy as np
        model_loaded = self._load_model()
        interval = self.config['process_interval']

        while self.running:
            dummy_audio = np.random.randn(16000 * 3).astype(np.float32)

            if model_loaded and self.model:
                if self.config['type'] == 'whisper':
                    result = self.model.transcribe(dummy_audio, language=self.config['language'])
                else:
                    import torch
                    with torch.no_grad():
                        x = torch.from_numpy(dummy_audio).unsqueeze(0)
                        if torch.cuda.is_available():
                            x = x.cuda()
                        _ = self.model(x)
            else:
                try:
                    import torch
                    if torch.cuda.is_available():
                        x = torch.randn(1, 80, 3000).cuda()
                        for _ in range(5):
                            x = torch.nn.functional.relu(x)
                        del x
                        torch.cuda.synchronize()
                except:
                    pass
                time.sleep(0.5)

            self.transcription_count += 1
            time.sleep(interval)


class TTSService:
    """TTS (Text-to-Speech) 서비스"""

    def __init__(self):
        self.running = False
        self.synthesis_count = 0
        self.tts = None
        self.tts_type = None
        self.config = TTS_CONFIG

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._run)
        self.thread.start()
        print(f"[TTS] 시작 (type: {self.config['type']})")

    def stop(self):
        self.running = False
        self.thread.join()
        print(f"[TTS] 종료 - 총 {self.synthesis_count} 합성 수행")

    def _load_model(self):
        try:
            if self.config['type'] == 'gtts':
                from gtts import gTTS
                self.tts_type = 'gtts'
                print(f"[TTS] gTTS 로드 완료 (lang: {self.config.get('gtts_lang', 'ko')})")
                return True

            elif self.config['type'] == 'coqui':
                import torch
                torch.cuda.set_per_process_memory_fraction(GPU_MEMORY_FRACTION)
                from TTS.api import TTS
                model_name = self.config['coqui_model']
                self.tts = TTS(model_name=model_name, progress_bar=False)
                self.tts_type = 'coqui'
                print(f"[TTS] Coqui TTS 모델 로드: {model_name}")
                return True

            elif self.config['type'] == 'custom':
                import torch
                torch.cuda.set_per_process_memory_fraction(GPU_MEMORY_FRACTION)
                model_path = self.config['custom_model_path']
                self.tts = torch.load(model_path)
                self.tts.eval()
                if torch.cuda.is_available():
                    self.tts = self.tts.cuda()
                self.tts_type = 'custom'
                print(f"[TTS] 커스텀 모델 로드: {model_path}")
                return True

        except Exception as e:
            print(f"[TTS] 모델 로드 실패: {e}")
            print("[TTS] 더미 모드로 실행")
            return False

    def _run(self):
        import numpy as np
        import io
        model_loaded = self._load_model()
        interval = self.config['synthesis_interval']
        text_idx = 0

        while self.running:
            text = TEST_TEXTS[text_idx % len(TEST_TEXTS)]

            if model_loaded:
                if self.tts_type == 'gtts':
                    from gtts import gTTS
                    lang = self.config.get('gtts_lang', 'ko')
                    tts = gTTS(text=text, lang=lang)
                    # 메모리에 저장 (파일 생성 안 함)
                    fp = io.BytesIO()
                    tts.write_to_fp(fp)
                elif self.tts_type == 'coqui' and self.tts:
                    wav = self.tts.tts(text)
                elif self.tts_type == 'custom' and self.tts:
                    import torch
                    with torch.no_grad():
                        pass
            else:
                try:
                    import torch
                    if torch.cuda.is_available():
                        x = torch.randn(1, 256, 100).cuda()
                        for _ in range(5):
                            x = torch.nn.functional.relu(x)
                        del x
                        torch.cuda.synchronize()
                except:
                    pass
                time.sleep(0.3)

            self.synthesis_count += 1
            text_idx += 1
            time.sleep(interval)


def run_integrated_test(duration: int = 60):
    """통합 부하 테스트 실행"""

    print("=" * 60)
    print(" Jetson Orin Nano 통합 부하 테스트")
    print("=" * 60)
    print(f"테스트 시간: {duration}초")
    print(f"GPU 메모리 제한: {GPU_MEMORY_FRACTION * 100:.1f}%")
    print("=" * 60)

    # GPU 설정
    try:
        import torch
        if torch.cuda.is_available():
            torch.cuda.set_per_process_memory_fraction(GPU_MEMORY_FRACTION)
            total_mem = torch.cuda.get_device_properties(0).total_memory
            print(f"[GPU] {torch.cuda.get_device_name(0)}")
            print(f"[GPU] 메모리 제한: {total_mem * GPU_MEMORY_FRACTION / 1024**3:.1f}GB")
        else:
            print("[GPU] CUDA 사용 불가")
    except ImportError:
        print("[GPU] PyTorch 미설치")

    print("=" * 60)
    print()

    # 설정 출력
    print("[설정]")
    print(f"  객체 인식: {OBJECT_DETECTION['type']} ({OBJECT_DETECTION.get('yolo_model', OBJECT_DETECTION.get('custom_model_path', 'N/A'))})")
    print(f"  STT: {STT['type']} ({STT.get('whisper_model', STT.get('custom_model_path', 'N/A'))})")
    print(f"  TTS: {TTS_CONFIG['type']} ({TTS_CONFIG.get('coqui_model', TTS_CONFIG.get('custom_model_path', 'N/A'))})")
    print(f"  라이다: {LIDAR['scan_rate']}Hz")
    print(f"  영상: {VIDEO['width']}x{VIDEO['height']} @ {VIDEO['target_fps']}fps")
    print()

    # 서비스 초기화
    monitor = ResourceMonitor()
    lidar = LidarSimulator()
    video = VideoStreamer()
    detector = ObjectDetector()
    stt = STTService()
    tts = TTSService()

    # 시작
    print("[시작] 모든 서비스 시작...")
    print()

    monitor.start()
    time.sleep(1)

    lidar.start()
    video.start()
    detector.start()
    stt.start()
    tts.start()

    print()
    print(f"[실행 중] {duration}초 동안 테스트...")
    print()

    try:
        time.sleep(duration)
    except KeyboardInterrupt:
        print("\n[중단] 사용자에 의해 중단됨")

    # 종료
    print()
    print()
    print("[종료] 모든 서비스 종료...")

    lidar.stop()
    video.stop()
    detector.stop()
    stt.stop()
    tts.stop()
    monitor.stop()

    # 결과
    print()
    print("=" * 60)
    print(" 테스트 결과")
    print("=" * 60)

    summary = monitor.get_summary()
    if summary:
        print(f"CPU 사용률:     평균 {summary['cpu_avg']:.1f}% / 최대 {summary['cpu_max']:.1f}%")
        print(f"RAM 사용량:     평균 {summary['memory_avg_mb']:.1f}MB / 최대 {summary['memory_max_mb']:.1f}MB")
        print(f"GPU 메모리:     평균 {summary['gpu_memory_avg_mb']:.1f}MB / 최대 {summary['gpu_memory_max_mb']:.1f}MB")
        print(f"GPU 사용률:     평균 {summary['gpu_util_avg']:.1f}% / 최대 {summary['gpu_util_max']:.1f}%")

    print()
    print("처리량:")
    print(f"  - 라이다 스캔:    {lidar.scan_count}회 ({lidar.scan_count/duration:.1f}/초)")
    print(f"  - 영상 프레임:    {video.frame_count}회 ({video.frame_count/duration:.1f}/초)")
    print(f"  - 객체 인식:      {detector.detection_count}회 ({detector.detection_count/duration:.1f}/초)")
    print(f"  - STT 변환:       {stt.transcription_count}회")
    print(f"  - TTS 합성:       {tts.synthesis_count}회")

    print()
    print("=" * 60)
    print(" Jetson Orin Nano 대비 평가")
    print("=" * 60)

    if summary:
        gpu_mem_limit = 6 * 1024
        if summary['gpu_memory_max_mb'] > gpu_mem_limit:
            print(f"[WARNING] GPU 메모리 초과! ({summary['gpu_memory_max_mb']:.0f}MB > {gpu_mem_limit}MB)")
            print("         -> Jetson에서 OOM 발생 가능")
        else:
            print(f"[OK] GPU 메모리 사용량 적정 ({summary['gpu_memory_max_mb']:.0f}MB / {gpu_mem_limit}MB)")

        ram_limit = 8 * 1024
        if summary['memory_max_mb'] > ram_limit * 0.9:
            print(f"[WARNING] RAM 사용량 높음! ({summary['memory_max_mb']:.0f}MB)")
            print("         -> Jetson에서 메모리 부족 가능")
        else:
            print(f"[OK] RAM 사용량 적정 ({summary['memory_max_mb']:.0f}MB / {ram_limit}MB)")

    print()
    print("참고: GPU 연산 속도는 RTX가 Jetson보다 빠르므로,")
    print("     실제 Jetson에서는 처리량이 더 낮을 수 있습니다.")
    print("=" * 60)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Jetson Orin Nano 통합 부하 테스트")
    parser.add_argument("-d", "--duration", type=int, default=60, help="테스트 시간 (초)")
    args = parser.parse_args()

    run_integrated_test(duration=args.duration)
