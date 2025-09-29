#!/bin/bash

# ComfyUI GPU 0 Launcher
# This script starts ComfyUI on GPU 0

echo "🚀 Starting ComfyUI on GPU 0..."
echo "📍 Instance: ComfyUI_GPU0"
echo "🎮 GPU: RTX 5060 Ti (GPU 0)"
echo "🌐 Web UI: http://localhost:8188"
echo "=================================================="

cd /home/yuji/Code/Umeiart/ComfyUI_GPU0

# Set CUDA device to GPU 0
export CUDA_VISIBLE_DEVICES=0

# Activate virtual environment
source venv/bin/activate

# Start ComfyUI with GPU 0 in background
python main.py --listen 0.0.0.0 --port 8188 --cuda-device 0 &

# Wait a moment for ComfyUI to start
sleep 5

# Launch browser
echo "🌐 Opening browser..."
xdg-open http://localhost:8188 2>/dev/null || firefox http://localhost:8188 2>/dev/null || chromium-browser http://localhost:8188 2>/dev/null || echo "Please manually open http://localhost:8188 in your browser"

# Wait for the background process
wait
