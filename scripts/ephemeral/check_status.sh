#!/bin/bash

# ComfyUI Status Checker
echo "🎮 ComfyUI Dual GPU Status"
echo "========================================"

echo "📊 GPU Status:"
nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits | while IFS=',' read -r index name mem_used mem_total util; do
    echo "  GPU $index: $name"
    echo "    Memory: ${mem_used}MB / ${mem_total}MB"
    echo "    Utilization: ${util}%"
done

echo ""
echo "🌐 ComfyUI Instances:"

# Check for ComfyUI processes and their ports
gpu0_running=false
gpu1_running=false

# Check port 8188 (GPU 0)
if lsof -i :8188 >/dev/null 2>&1; then
    pid=$(lsof -t -i :8188)
    echo "  ✅ GPU 0 Instance (PID $pid): Running on port 8188"
    echo "       URL: http://localhost:8188"
    gpu0_running=true
else
    echo "  ❌ GPU 0 Instance: Not running"
fi

# Check port 8189 (GPU 1)
if lsof -i :8189 >/dev/null 2>&1; then
    pid=$(lsof -t -i :8189)
    echo "  ✅ GPU 1 Instance (PID $pid): Running on port 8189"
    echo "       URL: http://localhost:8189"
    gpu1_running=true
else
    echo "  ❌ GPU 1 Instance: Not running"
fi

# Check for any other ComfyUI processes (not on our expected ports)
other_processes=""
for pid in $(pgrep -f "python.*main.py"); do
    # Check if this PID is already listed as GPU 0 or GPU 1
    if [ "$pid" != "$(lsof -t -i :8188 2>/dev/null)" ] && [ "$pid" != "$(lsof -t -i :8189 2>/dev/null)" ]; then
        other_processes="$other_processes $pid"
    fi
done

if [ -n "$other_processes" ]; then
    echo "  ℹ️  Other ComfyUI processes detected:"
    for pid in $other_processes; do
        echo "    PID $pid: Running (unknown port)"
    done
fi

echo ""
echo "📁 Shared Models Directory:"
if [ -L "/home/yuji/Code/Umeiart/ComfyUI_GPU0/models" ]; then
    echo "  ✅ GPU 0 models: Linked to shared directory"
else
    echo "  ❌ GPU 0 models: Not linked properly"
fi

if [ -L "/home/yuji/Code/Umeiart/ComfyUI_GPU1/models" ]; then
    echo "  ✅ GPU 1 models: Linked to shared directory"
else
    echo "  ❌ GPU 1 models: Not linked properly"
fi

echo ""
echo "🚀 Quick Start Commands:"
echo "  ./start_comfyui_gpu0.sh    # Start GPU 0 instance"
echo "  ./start_comfyui_gpu1.sh    # Start GPU 1 instance"
echo "  ./comfyui_manager.sh       # Interactive manager"
