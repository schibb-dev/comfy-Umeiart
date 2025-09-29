#!/bin/bash

# ============================================================================
# ComfyUI Smart Restart Script
# Detects if ComfyUI is running and restarts it, or starts it if not running
# ============================================================================

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
VENV_DIR="$COMFYUI_DIR/venv"
MAIN_SCRIPT="$COMFYUI_DIR/main.py"
PROCESS_NAME="python3 main.py"

echo "🔄 ComfyUI Smart Restart Script"
echo "==============================="
echo

# Function to check if ComfyUI is running
is_comfyui_running() {
    pgrep -f "$PROCESS_NAME" > /dev/null 2>&1
}

# Function to get ComfyUI process info
get_comfyui_process() {
    pgrep -f "$PROCESS_NAME"
}

# Function to kill ComfyUI processes
kill_comfyui() {
    local pids=$(get_comfyui_process)
    if [[ -n "$pids" ]]; then
        echo "🛑 Stopping ComfyUI processes: $pids"
        echo "$pids" | xargs kill -TERM
        
        # Wait for graceful shutdown
        echo "⏳ Waiting for graceful shutdown..."
        sleep 3
        
        # Check if still running and force kill if necessary
        local remaining_pids=$(get_comfyui_process)
        if [[ -n "$remaining_pids" ]]; then
            echo "⚠️  Force killing remaining processes: $remaining_pids"
            echo "$remaining_pids" | xargs kill -KILL
            sleep 1
        fi
        
        echo "✅ ComfyUI stopped"
    else
        echo "ℹ️  ComfyUI is not running"
    fi
}

# Function to start ComfyUI
start_comfyui() {
    echo "🚀 Starting ComfyUI with SageAttention..."
    echo "   Directory: $COMFYUI_DIR"
    echo "   URL: http://127.0.0.1:8188"
    echo
    
    cd "$COMFYUI_DIR"
    source "$VENV_DIR/bin/activate"
    
    # Start ComfyUI in background with SageAttention
    nohup python3 main.py --use-sage-attention --auto-launch > comfyui.log 2>&1 &
    
    # Get the process ID
    local pid=$!
    echo "✅ ComfyUI started with PID: $pid"
    echo "📝 Logs are being written to: $COMFYUI_DIR/comfyui.log"
    echo "🌐 ComfyUI should be available at: http://127.0.0.1:8188"
    echo
    
    # Wait a moment and check if it's still running
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        echo "🎉 ComfyUI is running successfully!"
    else
        echo "❌ ComfyUI failed to start. Check the log file for errors."
        echo "📄 Last few lines of log:"
        tail -10 "$COMFYUI_DIR/comfyui.log" 2>/dev/null || echo "No log file found"
    fi
}

# Function to show status
show_status() {
    if is_comfyui_running; then
        local pids=$(get_comfyui_process)
        echo "✅ ComfyUI is running (PID: $pids)"
        echo "🌐 Available at: http://127.0.0.1:8188"
    else
        echo "❌ ComfyUI is not running"
    fi
}

# Function to show logs
show_logs() {
    if [[ -f "$COMFYUI_DIR/comfyui.log" ]]; then
        echo "📄 ComfyUI Logs (last 20 lines):"
        echo "================================"
        tail -20 "$COMFYUI_DIR/comfyui.log"
    else
        echo "📄 No log file found at $COMFYUI_DIR/comfyui.log"
    fi
}

# Main script logic
case "${1:-restart}" in
    "start")
        if is_comfyui_running; then
            echo "⚠️  ComfyUI is already running!"
            show_status
        else
            start_comfyui
        fi
        ;;
    "stop")
        kill_comfyui
        ;;
    "restart")
        echo "🔄 Restarting ComfyUI..."
        kill_comfyui
        sleep 2
        start_comfyui
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  start    - Start ComfyUI (if not already running)"
        echo "  stop     - Stop ComfyUI"
        echo "  restart  - Restart ComfyUI (default)"
        echo "  status   - Show ComfyUI status"
        echo "  logs     - Show recent logs"
        echo "  help     - Show this help message"
        echo
        echo "Examples:"
        echo "  $0                # Restart ComfyUI"
        echo "  $0 start          # Start ComfyUI"
        echo "  $0 stop           # Stop ComfyUI"
        echo "  $0 status         # Check if running"
        echo "  $0 logs           # View logs"
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo
echo "💡 Tip: Use '$0 help' for more options"
