#!/bin/bash

# ============================================================================
# WAN 2.1 Model Downloader (Manual)
# Downloads WAN 2.1 models with direct links
# ============================================================================

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"

echo "🎬 WAN 2.1 Model Downloader (Manual)"
echo "===================================="
echo

# Create model directories
echo "📁 Creating model directories..."
mkdir -p "$COMFYUI_DIR/models/diffusion_models"
mkdir -p "$COMFYUI_DIR/models/text_encoders"
mkdir -p "$COMFYUI_DIR/models/vae"
mkdir -p "$COMFYUI_DIR/models/checkpoints"

# Function to download file
download_file() {
    local url="$1"
    local target_file="$2"
    local filename=$(basename "$target_file")
    
    echo "📥 Downloading $filename..."
    
    if command -v curl >/dev/null 2>&1; then
        if curl -L -o "$target_file" "$url" 2>/dev/null; then
            if [[ -f "$target_file" ]] && [[ $(wc -c < "$target_file") -gt 100 ]]; then
                echo "✅ Downloaded: $filename"
                return 0
            fi
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -O "$target_file" "$url" 2>/dev/null; then
            if [[ -f "$target_file" ]] && [[ $(wc -c < "$target_file") -gt 100 ]]; then
                echo "✅ Downloaded: $filename"
                return 0
            fi
        fi
    else
        echo "❌ Neither curl nor wget is available"
        return 1
    fi
    
    echo "❌ Failed to download: $filename"
    rm -f "$target_file"
    return 1
}

echo "🚀 Starting WAN 2.1 model downloads..."
echo

# Download WAN 2.1 models
echo "📥 Downloading WAN 2.1 models..."

# WAN 2.1 Diffusion Model
echo "1. WAN 2.1 Diffusion Model..."
download_file "https://huggingface.co/wan-research/wan2.1/resolve/main/diffusion_pytorch_model-00001-of-00007.safetensors" "$COMFYUI_DIR/models/diffusion_models/diffusion_pytorch_model-00001-of-00007.safetensors"

# WAN 2.1 Text Encoder
echo "2. WAN 2.1 Text Encoder..."
download_file "https://huggingface.co/wan-research/wan2.1/resolve/main/models_t5_umt5-xxl-enc-bf16.pth" "$COMFYUI_DIR/models/text_encoders/models_t5_umt5-xxl-enc-bf16.pth"

# WAN 2.1 VAE
echo "3. WAN 2.1 VAE..."
download_file "https://huggingface.co/wan-research/wan2.1/resolve/main/Wan2.1_VAE.pth" "$COMFYUI_DIR/models/vae/Wan2.1_VAE.pth"

echo
echo "🎉 WAN 2.1 model download complete!"
echo "=========================="
echo
echo "📁 Models saved to:"
echo "  • Diffusion: $COMFYUI_DIR/models/diffusion_models/"
echo "  • Text Encoder: $COMFYUI_DIR/models/text_encoders/"
echo "  • VAE: $COMFYUI_DIR/models/vae/"
echo
echo "🚀 Next Steps:"
echo "  1. Restart ComfyUI: ./comfyui-restart.sh restart"
echo "  2. Load the WAN 2.1 workflow"
echo "  3. Start generating videos!"
