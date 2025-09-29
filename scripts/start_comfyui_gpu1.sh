#!/bin/bash

# ComfyUI GPU 1 Launcher
# This script starts ComfyUI on GPU 1

echo "🚀 Starting ComfyUI on GPU 1..."
echo "📍 Instance: ComfyUI_GPU1"
echo "🎮 GPU: RTX 5060 Ti (GPU 1)"
echo "🌐 Web UI: http://localhost:8189"
echo "=================================================="

cd /home/yuji/Code/Umeiart/ComfyUI_GPU1

# Set CUDA device to GPU 1
export CUDA_VISIBLE_DEVICES=1

# Activate virtual environment
source venv/bin/activate

# Start ComfyUI with GPU 1 in background
python main.py --listen 0.0.0.0 --port 8189 --cuda-device 1 &

# Wait a moment for ComfyUI to start
sleep 5

# Launch browser
echo "🌐 Opening browser..."
xdg-open http://localhost:8189 2>/dev/null || firefox http://localhost:8189 2>/dev/null || chromium-browser http://localhost:8189 2>/dev/null || echo "Please manually open http://localhost:8189 in your browser"

# Wait for the background process
wait
