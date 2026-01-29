#!/bin/bash

# =============================================================================
# Jetson Orin Nano 시뮬레이션 환경 - 의존성 설치 스크립트
# =============================================================================

set -e

echo "=========================================="
echo " 의존성 설치 시작"
echo "=========================================="

# 기본 시스템 패키지
echo "[1/7] 시스템 패키지 설치..."
apt update && apt install -y \
    python3-pip \
    python3-dev \
    ffmpeg \
    libsm6 \
    libxext6 \
    git \
    wget \
    curl

# pip 업그레이드
pip3 install --upgrade pip

# 기본 Python 패키지
echo "[2/7] 기본 Python 패키지 설치..."
pip3 install \
    numpy \
    psutil \
    pynvml

# OpenCV
echo "[3/7] OpenCV 설치..."
pip3 install opencv-python-headless

# PyTorch (CUDA 11.8)
echo "[4/7] PyTorch 설치..."
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# 객체 인식 - YOLOv8
echo "[5/7] YOLOv8 설치..."
pip3 install ultralytics

# STT - Whisper
echo "[6/7] Whisper (STT) 설치..."
pip3 install openai-whisper

# TTS - gTTS (한국어 지원)
echo "[7/7] gTTS (TTS) 설치..."
pip3 install gtts

# 모델 사전 다운로드 (선택사항)
echo ""
echo "=========================================="
echo " 모델 사전 다운로드"
echo "=========================================="

echo "YOLOv8n 모델 다운로드..."
python3 -c "from ultralytics import YOLO; YOLO('yolov8n.pt')" 2>/dev/null || true

echo "Whisper base 모델 다운로드..."
python3 -c "import whisper; whisper.load_model('base')" 2>/dev/null || true

echo ""
echo "=========================================="
echo " 설치 완료!"
echo "=========================================="
echo ""
echo "테스트 실행:"
echo "  cd /workspace"
echo "  python3 integrated_load_test.py -d 60"
echo ""
echo "설정 변경:"
echo "  vi /workspace/config.py"
echo ""
