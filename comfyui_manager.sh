#!/bin/bash

# Dual GPU ComfyUI Manager
# This script helps manage both ComfyUI instances

# Resolve script path helper
resolve_script() {
    # $1 = script filename
    if [ -f "/home/yuji/Code/Umeiart/$1" ]; then
        echo "/home/yuji/Code/Umeiart/$1"
        return 0
    fi
    if [ -f "/home/yuji/Code/Umeiart/scripts/$1" ]; then
        echo "/home/yuji/Code/Umeiart/scripts/$1"
        return 0
    fi
    echo ""
    return 1
}

# Resolve python interpreter path (mirror start scripts)
resolve_python() {
    # $1 = instance dir name (e.g., ComfyUI_GPU0)
    local inst_dir="/home/yuji/Code/Umeiart/$1"
    if [ -x "/home/yuji/Code/Umeiart/ComfyUI/venv/bin/python" ]; then
        echo "/home/yuji/Code/Umeiart/ComfyUI/venv/bin/python"
        return 0
    fi
    if [ -x "$inst_dir/venv/bin/python" ]; then
        echo "$inst_dir/venv/bin/python"
        return 0
    fi
    if command -v python3 >/dev/null 2>&1; then
        echo "$(command -v python3)"
        return 0
    fi
    if command -v python >/dev/null 2>&1; then
        echo "$(command -v python)"
        return 0
    fi
    echo ""
    return 1
}

# Function to count running ComfyUI instances
count_comfyui_instances() {
    pgrep -f "python.*main.py" | wc -l
}

# Function to get detailed instance information
get_instance_info() {
    local instances=()
    pgrep -f "python.*main.py" | while read pid; do
        local cmd=$(ps -p $pid -o args= 2>/dev/null)
        local port="unknown"
        local gpu="unknown"
        
        if echo "$cmd" | grep -q "8188"; then
            port="8188"
            gpu="GPU 0"
        elif echo "$cmd" | grep -q "8189"; then
            port="8189"
            gpu="GPU 1"
        fi
        
        echo "$pid:$port:$gpu"
    done
}

# Function to check for orphaned instances
check_orphaned_instances() {
    local orphaned=()
    local instances=$(get_instance_info)
    
    while IFS=':' read -r pid port gpu; do
        if [[ "$port" == "unknown" ]]; then
            orphaned+=("$pid")
        fi
    done <<< "$instances"
    
    echo "${orphaned[@]}"
}

# Function to display current status
show_status() {
    local count=$(count_comfyui_instances)
    echo "📊 ComfyUI Status:"
    echo "   Total instances running: $count"
    
    # Show which Python interpreters would be used
    local gpu0_python=$(resolve_python "ComfyUI_GPU0")
    local gpu1_python=$(resolve_python "ComfyUI_GPU1")
    if [ -n "$gpu0_python" ]; then
        echo "   GPU 0 Python: $gpu0_python"
    else
        echo "   GPU 0 Python: not found"
    fi
    if [ -n "$gpu1_python" ]; then
        echo "   GPU 1 Python: $gpu1_python"
    else
        echo "   GPU 1 Python: not found"
    fi
    
    if [[ $count -gt 0 ]]; then
        echo "   Instance details:"
        get_instance_info | while IFS=':' read -r pid port gpu; do
            echo "     PID $pid: $gpu (Port $port)"
        done
        
        # Check for orphaned instances
        local orphaned=($(check_orphaned_instances))
        if [[ ${#orphaned[@]} -gt 0 ]]; then
            echo "   ⚠️  Orphaned instances detected:"
            for pid in "${orphaned[@]}"; do
                echo "     PID $pid: Unknown configuration"
            done
        fi
    else
        echo "   ❌ No ComfyUI instances running"
    fi
}

echo "🎮 Dual GPU ComfyUI Manager"
echo "========================================"
echo "Available GPUs:"
nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv,noheader,nounits | while read line; do
    echo "  GPU $line"
done
echo ""

# Show current status
show_status
echo ""

echo "Available Commands:"
echo "  1) Start GPU 0 instance (Port 8188)"
echo "  2) Start GPU 1 instance (Port 8189)"
echo "  3) Start both instances"
echo "  4) Stop all instances"
echo "  5) Check status"
echo "  6) Kill orphaned instances"
echo "  7) Open GPU 0 in browser"
echo "  8) Open GPU 1 in browser"
echo "  9) Exit"
echo ""

read -p "Choose an option (1-9): " choice

case $choice in
    1)
        # Check if GPU 0 instance already exists
        if pgrep -f "python.*main.py.*8188" > /dev/null; then
            echo "⚠️  GPU 0 instance is already running on port 8188"
            read -p "Do you want to restart it? (y/n): " restart
            if [[ $restart == "y" || $restart == "Y" ]]; then
                echo "🛑 Stopping existing GPU 0 instance..."
                pkill -f "python.*main.py.*8188"
                sleep 2
            else
                echo "❌ Cancelled"
                exit 0
            fi
        fi
        
        # Check total instance count
        count=$(count_comfyui_instances)
        if [[ $count -ge 2 ]]; then
            echo "⚠️  Warning: You already have $count instances running. Starting more than 2 instances may cause resource conflicts."
            read -p "Continue anyway? (y/n): " continue_anyway
            if [[ $continue_anyway != "y" && $continue_anyway != "Y" ]]; then
                echo "❌ Cancelled"
                exit 0
            fi
        fi
        
        gpu0_script=$(resolve_script "start_comfyui_gpu0.sh")
        if [ -z "$gpu0_script" ]; then
            echo "❌ Could not find start script for GPU 0 (expected start_comfyui_gpu0.sh in root or scripts/)"
            exit 1
        fi
        gpu0_python=$(resolve_python "ComfyUI_GPU0")
        if [ -z "$gpu0_python" ]; then
            echo "⚠️  No Python interpreter found for GPU 0. The start script may fail."
        else
            echo "🐍 GPU 0 Python: $gpu0_python"
        fi
        echo "🚀 Starting ComfyUI on GPU 0..."
        gnome-terminal --title="ComfyUI GPU 0" -- bash -c "cd /home/yuji/Code/Umeiart && bash \"$gpu0_script\"; exec bash"
        ;;
    2)
        # Check if GPU 1 instance already exists
        if pgrep -f "python.*main.py.*8189" > /dev/null; then
            echo "⚠️  GPU 1 instance is already running on port 8189"
            read -p "Do you want to restart it? (y/n): " restart
            if [[ $restart == "y" || $restart == "Y" ]]; then
                echo "🛑 Stopping existing GPU 1 instance..."
                pkill -f "python.*main.py.*8189"
                sleep 2
            else
                echo "❌ Cancelled"
                exit 0
            fi
        fi
        
        # Check total instance count
        count=$(count_comfyui_instances)
        if [[ $count -ge 2 ]]; then
            echo "⚠️  Warning: You already have $count instances running. Starting more than 2 instances may cause resource conflicts."
            read -p "Continue anyway? (y/n): " continue_anyway
            if [[ $continue_anyway != "y" && $continue_anyway != "Y" ]]; then
                echo "❌ Cancelled"
                exit 0
            fi
        fi
        
        gpu1_script=$(resolve_script "start_comfyui_gpu1.sh")
        if [ -z "$gpu1_script" ]; then
            echo "❌ Could not find start script for GPU 1 (expected start_comfyui_gpu1.sh in root or scripts/)"
            exit 1
        fi
        gpu1_python=$(resolve_python "ComfyUI_GPU1")
        if [ -z "$gpu1_python" ]; then
            echo "⚠️  No Python interpreter found for GPU 1. The start script may fail."
        else
            echo "🐍 GPU 1 Python: $gpu1_python"
        fi
        echo "🚀 Starting ComfyUI on GPU 1..."
        gnome-terminal --title="ComfyUI GPU 1" -- bash -c "cd /home/yuji/Code/Umeiart && bash \"$gpu1_script\"; exec bash"
        ;;
    3)
        # Check if instances already exist
        gpu0_running=$(pgrep -f "python.*main.py.*8188" | wc -l)
        gpu1_running=$(pgrep -f "python.*main.py.*8189" | wc -l)
        
        if [[ $gpu0_running -gt 0 || $gpu1_running -gt 0 ]]; then
            echo "⚠️  Some instances are already running:"
            if [[ $gpu0_running -gt 0 ]]; then
                echo "   GPU 0 (Port 8188)"
            fi
            if [[ $gpu1_running -gt 0 ]]; then
                echo "   GPU 1 (Port 8189)"
            fi
            read -p "Do you want to restart all instances? (y/n): " restart_all
            if [[ $restart_all == "y" || $restart_all == "Y" ]]; then
                echo "🛑 Stopping all existing instances..."
                pkill -f "python main.py"
                sleep 3
            else
                echo "❌ Cancelled"
                exit 0
            fi
        fi
        
        gpu0_script=$(resolve_script "start_comfyui_gpu0.sh")
        gpu1_script=$(resolve_script "start_comfyui_gpu1.sh")
        if [ -z "$gpu0_script" ] || [ -z "$gpu1_script" ]; then
            echo "❌ Could not find required start scripts. Ensure start_comfyui_gpu0.sh and start_comfyui_gpu1.sh are in root or scripts/."
            exit 1
        fi
        gpu0_python=$(resolve_python "ComfyUI_GPU0")
        gpu1_python=$(resolve_python "ComfyUI_GPU1")
        [ -n "$gpu0_python" ] && echo "🐍 GPU 0 Python: $gpu0_python" || echo "⚠️  No Python interpreter found for GPU 0."
        [ -n "$gpu1_python" ] && echo "🐍 GPU 1 Python: $gpu1_python" || echo "⚠️  No Python interpreter found for GPU 1."
        echo "🚀 Starting both ComfyUI instances..."
        gnome-terminal --title="ComfyUI GPU 0" -- bash -c "cd /home/yuji/Code/Umeiart && bash \"$gpu0_script\"; exec bash"
        sleep 2
        gnome-terminal --title="ComfyUI GPU 1" -- bash -c "cd /home/yuji/Code/Umeiart && bash \"$gpu1_script\"; exec bash"
        ;;
    4)
        count=$(count_comfyui_instances)
        if [[ $count -eq 0 ]]; then
            echo "ℹ️  No ComfyUI instances are currently running"
        else
            echo "🛑 Stopping all ComfyUI instances ($count found)..."
            pkill -f "python main.py"
            sleep 2
            
            # Verify all instances stopped
            remaining=$(count_comfyui_instances)
            if [[ $remaining -eq 0 ]]; then
                echo "✅ All instances stopped successfully"
            else
                echo "⚠️  $remaining instances may still be running. You may need to kill them manually."
            fi
        fi
        ;;
    5)
        show_status
        ;;
    6)
        orphaned=($(check_orphaned_instances))
        if [[ ${#orphaned[@]} -eq 0 ]]; then
            echo "ℹ️  No orphaned instances found"
        else
            echo "🧹 Found ${#orphaned[@]} orphaned instance(s):"
            for pid in "${orphaned[@]}"; do
                echo "   PID $pid"
            done
            echo ""
            read -p "Do you want to kill these orphaned instances? (y/n): " kill_orphaned
            if [[ $kill_orphaned == "y" || $kill_orphaned == "Y" ]]; then
                for pid in "${orphaned[@]}"; do
                    echo "🛑 Killing orphaned instance PID $pid..."
                    kill $pid 2>/dev/null || echo "   Failed to kill PID $pid"
                done
                sleep 1
                echo "✅ Orphaned instances cleanup completed"
            else
                echo "❌ Cancelled"
            fi
        fi
        ;;
    7)
        echo "🌐 Opening GPU 0 in browser..."
        xdg-open http://localhost:8188 2>/dev/null || firefox http://localhost:8188 2>/dev/null || chromium-browser http://localhost:8188 2>/dev/null || echo "Please manually open http://localhost:8188 in your browser"
        ;;
    8)
        echo "🌐 Opening GPU 1 in browser..."
        xdg-open http://localhost:8189 2>/dev/null || firefox http://localhost:8189 2>/dev/null || chromium-browser http://localhost:8189 2>/dev/null || echo "Please manually open http://localhost:8189 in your browser"
        ;;
    9)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        ;;
esac
