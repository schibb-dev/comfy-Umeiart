#!/bin/bash

# ComfyUI GPU 1 Launcher
# This script starts ComfyUI on GPU 1

echo "🚀 Starting ComfyUI on GPU 1..."
echo "📍 Instance: ComfyUI_GPU1"
echo "🎮 GPU: RTX 5060 Ti (GPU 1)"
echo "🌐 Web UI: http://localhost:8189"
echo "=================================================="

# Ensure working directory exists
WORKDIR="/home/yuji/Code/Umeiart/ComfyUI_GPU1"
if [ ! -d "$WORKDIR" ]; then
    echo "❌ Workdir not found: $WORKDIR"
    exit 1
fi
cd "$WORKDIR"

# Set CUDA device to GPU 1
export CUDA_VISIBLE_DEVICES=1

# Resolve python interpreter (prefer shared venv)
PYTHON=""
if [ -x "/home/yuji/Code/Umeiart/ComfyUI/venv/bin/python" ]; then
    PYTHON="/home/yuji/Code/Umeiart/ComfyUI/venv/bin/python"
elif [ -x "$WORKDIR/venv/bin/python" ]; then
    PYTHON="$WORKDIR/venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON="python"
else
    echo "❌ No Python interpreter found. Please install python3 or set up venv."
    exit 1
fi

# Start ComfyUI with GPU 1 in background
echo "🐍 Using Python: $PYTHON"
"$PYTHON" main.py --listen 0.0.0.0 --port 8189 --cuda-device 1 &

# Wait a moment for ComfyUI to start
sleep 5

# Launch browser
echo "🌐 Opening browser..."
xdg-open http://localhost:8189 2>/dev/null || firefox http://localhost:8189 2>/dev/null || chromium-browser http://localhost:8189 2>/dev/null || echo "Please manually open http://localhost:8189 in your browser"

# Wait for the background process
wait
