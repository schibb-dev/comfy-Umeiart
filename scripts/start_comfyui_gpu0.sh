#!/bin/bash

# ComfyUI GPU 0 Launcher
# This script starts ComfyUI on GPU 0

echo "🚀 Starting ComfyUI on GPU 0..."
echo "📍 Instance: ComfyUI_GPU0"
echo "🎮 GPU: RTX 5060 Ti (GPU 0)"
echo "🌐 Web UI: http://localhost:8188"
echo "=================================================="

# Ensure working directory exists
WORKDIR="/home/yuji/Code/Umeiart/ComfyUI_GPU0"
if [ ! -d "$WORKDIR" ]; then
    echo "❌ Workdir not found: $WORKDIR"
    exit 1
fi
cd "$WORKDIR"

# Set CUDA device to GPU 0
export CUDA_VISIBLE_DEVICES=0

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

# Start ComfyUI with GPU 0 in background
echo "🐍 Using Python: $PYTHON"
"$PYTHON" main.py --listen 0.0.0.0 --port 8188 --cuda-device 0 &

# Wait for HTTP readiness on port 8188 (up to 90s)
PORT=8188
TIMEOUT=90
echo "⏳ Waiting for ComfyUI to become ready on :$PORT (timeout ${TIMEOUT}s)..."
start_ts=$(date +%s)
while true; do
    if curl -fsS "http://localhost:${PORT}" >/dev/null 2>&1; then
        echo "✅ ComfyUI is up on http://localhost:${PORT}"
        break
    fi
    now_ts=$(date +%s)
    elapsed=$(( now_ts - start_ts ))
    if [ $elapsed -ge $TIMEOUT ]; then
        echo "⚠️  Timed out waiting for ComfyUI on :$PORT. You can try opening the URL manually."
        break
    fi
    sleep 1
done

# Wait a moment for ComfyUI to start
sleep 5

# Launch browser
echo "🌐 Opening browser..."
xdg-open http://localhost:8188 2>/dev/null || firefox http://localhost:8188 2>/dev/null || chromium-browser http://localhost:8188 2>/dev/null || echo "Please manually open http://localhost:8188 in your browser"

# Wait for the background process
wait
