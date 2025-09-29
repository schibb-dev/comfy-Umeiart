#!/bin/bash

# Dual GPU ComfyUI Manager
# This script helps manage both ComfyUI instances

echo "🎮 Dual GPU ComfyUI Manager"
echo "========================================"
echo "Available GPUs:"
nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv,noheader,nounits | while read line; do
    echo "  GPU $line"
done
echo ""

echo "Available Commands:"
echo "  1) Start GPU 0 instance (Port 8188)"
echo "  2) Start GPU 1 instance (Port 8189)"
echo "  3) Start both instances"
echo "  4) Stop all instances"
echo "  5) Check status"
echo "  6) Open GPU 0 in browser"
echo "  7) Open GPU 1 in browser"
echo "  8) Exit"
echo ""

read -p "Choose an option (1-8): " choice

case $choice in
    1)
        echo "🚀 Starting ComfyUI on GPU 0..."
        gnome-terminal --title="ComfyUI GPU 0" -- bash -c "cd /home/yuji/Code/Umeiart && ./start_comfyui_gpu0.sh; exec bash"
        ;;
    2)
        echo "🚀 Starting ComfyUI on GPU 1..."
        gnome-terminal --title="ComfyUI GPU 1" -- bash -c "cd /home/yuji/Code/Umeiart && ./start_comfyui_gpu1.sh; exec bash"
        ;;
    3)
        echo "🚀 Starting both ComfyUI instances..."
        gnome-terminal --title="ComfyUI GPU 0" -- bash -c "cd /home/yuji/Code/Umeiart && ./start_comfyui_gpu0.sh; exec bash"
        sleep 2
        gnome-terminal --title="ComfyUI GPU 1" -- bash -c "cd /home/yuji/Code/Umeiart && ./start_comfyui_gpu1.sh; exec bash"
        ;;
    4)
        echo "🛑 Stopping all ComfyUI instances..."
        pkill -f "python main.py"
        echo "✅ All instances stopped"
        ;;
    5)
        echo "📊 Checking ComfyUI status..."
        if pgrep -f "python.*main.py" > /dev/null; then
            echo "✅ ComfyUI instances running:"
            pgrep -f "python.*main.py" | while read pid; do
                cmd=$(ps -p $pid -o args= 2>/dev/null)
                if echo "$cmd" | grep -q "8188"; then
                    echo "  GPU 0 Instance (PID $pid): Port 8188"
                elif echo "$cmd" | grep -q "8189"; then
                    echo "  GPU 1 Instance (PID $pid): Port 8189"
                else
                    echo "  ComfyUI Instance (PID $pid): Unknown port"
                fi
            done
        else
            echo "❌ No ComfyUI instances running"
        fi
        ;;
    6)
        echo "🌐 Opening GPU 0 in browser..."
        xdg-open http://localhost:8188 2>/dev/null || firefox http://localhost:8188 2>/dev/null || chromium-browser http://localhost:8188 2>/dev/null || echo "Please manually open http://localhost:8188 in your browser"
        ;;
    7)
        echo "🌐 Opening GPU 1 in browser..."
        xdg-open http://localhost:8189 2>/dev/null || firefox http://localhost:8189 2>/dev/null || chromium-browser http://localhost:8189 2>/dev/null || echo "Please manually open http://localhost:8189 in your browser"
        ;;
    8)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        ;;
esac
