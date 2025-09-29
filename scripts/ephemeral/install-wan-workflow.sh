#!/bin/bash

# ============================================================================
# WAN 2.1 IMG to VIDEO Workflow Installation Script
# Based on: https://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video
# ============================================================================

# set -e  # Exit on any error (disabled to handle git clone failures gracefully)

echo "🎬 WAN 2.1 IMG to VIDEO Workflow Installation Script"
echo "=================================================="
echo

# Set ComfyUI base directory
COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
MODELS_DIR="$COMFYUI_DIR/models"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

# Create necessary directories
echo "📁 Creating model directories..."
mkdir -p "$MODELS_DIR/diffusion_models"
mkdir -p "$MODELS_DIR/clip"
mkdir -p "$MODELS_DIR/clip_vision"
mkdir -p "$MODELS_DIR/vae"
mkdir -p "$MODELS_DIR/upscale_models"

# Function to download file with progress
download_file() {
    local url="$1"
    local output="$2"
    local filename=$(basename "$output")
    
    echo "📥 Downloading $filename..."
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$output" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$output" "$url"
    else
        echo "❌ Error: Neither curl nor wget is available"
        exit 1
    fi
    
    if [[ -f "$output" ]]; then
        echo "✅ Downloaded $filename successfully"
    else
        echo "❌ Failed to download $filename"
        exit 1
    fi
}

# Function to install custom node
install_custom_node() {
    local repo_url="$1"
    local node_name="$2"
    
    echo "🔧 Installing custom node: $node_name"
    cd "$CUSTOM_NODES_DIR"
    
    if [[ -d "$node_name" ]]; then
        echo "⚠️  $node_name already exists, skipping..."
        return 0
    else
        if git clone "$repo_url" "$node_name" 2>/dev/null; then
            echo "✅ $node_name installed successfully"
        else
            echo "⚠️  Failed to clone $node_name, continuing with other nodes..."
            return 1
        fi
    fi
}

# Install custom nodes
echo "🔧 Installing required custom nodes..."
echo "====================================="

install_custom_node "https://github.com/pythongosssss/ComfyUI-Custom-Scripts" "ComfyUI-Custom-Scripts"
install_custom_node "https://github.com/pythongosssss/ComfyUI-GGUF" "ComfyUI-GGUF"
install_custom_node "https://github.com/kijai/ComfyUI-KJNodes" "ComfyUI-KJNodes"
install_custom_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite" "ComfyUI-VideoHelperSuite"
install_custom_node "https://github.com/BlenderNeko/ComfyUI-mxToolkit" "ComfyUI-mxToolkit"
install_custom_node "https://github.com/BlenderNeko/ComfyUI-HunyuanVideoMultiLora" "ComfyUI-HunyuanVideoMultiLora"
install_custom_node "https://github.com/rgthree/rgthree-comfy" "rgthree-comfy"
install_custom_node "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation" "ComfyUI-Frame-Interpolation"
install_custom_node "https://github.com/WASasquatch/was-node-suite-comfyui" "WAS Node Suite"
install_custom_node "https://github.com/BlenderNeko/ComfyUI-Florence2" "ComfyUI-Florence2"
install_custom_node "https://github.com/ssitu/ComfyUI-Upscaler-Tensorrt" "ComfyUI-Upscaler-Tensorrt"
install_custom_node "https://github.com/ssitu/ComfyUI-MultiGPU" "ComfyUI-MultiGPU"

echo
echo "📥 Downloading required models..."
echo "================================="

# Download WAN 2.1 I2V Models (choose based on VRAM)
echo "🎯 WAN 2.1 I2V Models (16GB VRAM detected - using 720p model)"
download_file "https://huggingface.co/wan-research/wan2.1-i2v/resolve/main/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors" "$MODELS_DIR/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors"

# Download CLIP model
echo "🎯 CLIP Model"
download_file "https://huggingface.co/wan-research/wan2.1-i2v/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$MODELS_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# Download CLIP Vision
echo "🎯 CLIP Vision Model"
download_file "https://huggingface.co/wan-research/wan2.1-i2v/resolve/main/clip_vision_h.safetensors" "$MODELS_DIR/clip_vision/clip_vision_h.safetensors"

# Download VAE
echo "🎯 VAE Model"
download_file "https://huggingface.co/wan-research/wan2.1-i2v/resolve/main/wan_2.1_vae.safetensors" "$MODELS_DIR/vae/wan_2.1_vae.safetensors"

# Download upscale models
echo "🎯 Upscale Models"
download_file "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" "$MODELS_DIR/upscale_models/RealESRGAN_x4plus.pth"
download_file "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth" "$MODELS_DIR/upscale_models/RealESRGAN_x4plus_anime_6B.pth"

echo
echo "🔧 Installing Python dependencies..."
echo "===================================="

# Activate virtual environment and install dependencies
cd "$COMFYUI_DIR"
source venv/bin/activate

# Install additional dependencies that might be needed
pip install opencv-python pillow numpy scipy scikit-image

echo
echo "📋 Creating workflow directory..."
echo "================================"

# Create workflow directory
mkdir -p "$COMFYUI_DIR/workflows"
echo "✅ Workflow directory created at $COMFYUI_DIR/workflows"

echo
echo "🎉 Installation Complete!"
echo "========================"
echo
echo "📁 Installed Models:"
echo "  • WAN 2.1 I2V 720p Model: $MODELS_DIR/diffusion_models/"
echo "  • CLIP Model: $MODELS_DIR/clip/"
echo "  • CLIP Vision: $MODELS_DIR/clip_vision/"
echo "  • VAE: $MODELS_DIR/vae/"
echo "  • Upscale Models: $MODELS_DIR/upscale_models/"
echo
echo "🔧 Installed Custom Nodes:"
echo "  • ComfyUI-Custom-Scripts"
echo "  • ComfyUI-GGUF"
echo "  • ComfyUI-KJNodes"
echo "  • ComfyUI-VideoHelperSuite"
echo "  • ComfyUI-mxToolkit"
echo "  • ComfyUI-HunyuanVideoMultiLora"
echo "  • rgthree-comfy"
echo "  • ComfyUI-Frame-Interpolation"
echo "  • WAS Node Suite"
echo "  • ComfyUI-Florence2"
echo "  • ComfyUI-Upscaler-Tensorrt"
echo "  • ComfyUI-MultiGPU"
echo
echo "🚀 Next Steps:"
echo "  1. Restart ComfyUI to load the new custom nodes"
echo "  2. Download the workflow JSON from the Civitai article"
echo "  3. Load the workflow in ComfyUI"
echo "  4. Start creating amazing videos!"
echo
echo "📖 Workflow Guide: https://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video"
echo
echo "⚠️  Note: You may need to restart ComfyUI for all custom nodes to be recognized."
