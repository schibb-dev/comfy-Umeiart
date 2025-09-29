#!/bin/bash

# Basic ComfyUI installer for Linux
echo "[INFO] Starting ComfyUI installation..."

# Check if Python is available
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] Python 3 is required but not installed."
    echo "Please install Python 3 and try again."
    exit 1
fi

# Check if pip is available (try different variations)
pipCmd=""
if command -v pip3 >/dev/null 2>&1; then
    pipCmd="pip3"
elif command -v pip >/dev/null 2>&1; then
    pipCmd="pip"
elif python3 -m pip --version >/dev/null 2>&1; then
    pipCmd="python3 -m pip"
else
    echo "[ERROR] No pip installation found."
    echo "Please install pip or pip3 and try again."
    echo "You can install it with: sudo apt install python3-pip"
    exit 1
fi

echo "[INFO] Using pip command: $pipCmd"

# Create ComfyUI directory
ComfyUIPath="$1/ComfyUI"
if [[ ! -d "$ComfyUIPath" ]]; then
    echo "[INFO] Creating ComfyUI directory: $ComfyUIPath"
    mkdir -p "$ComfyUIPath"
fi

cd "$ComfyUIPath"

# Clone ComfyUI repository if it doesn't exist
if [[ ! -d ".git" ]]; then
    echo "[INFO] Cloning ComfyUI repository..."
    if command -v git >/dev/null 2>&1; then
        git clone https://github.com/comfyanonymous/ComfyUI.git .
    else
        echo "[ERROR] Git is required but not installed."
        echo "Please install git and try again."
        exit 1
    fi
fi

# Install requirements
if [[ -f "requirements.txt" ]]; then
    echo "[INFO] Installing Python requirements..."
    $pipCmd install -r requirements.txt
fi

echo "[OK] ComfyUI installation completed!"
echo "[INFO] To start ComfyUI, run: cd $ComfyUIPath && python3 main.py"
