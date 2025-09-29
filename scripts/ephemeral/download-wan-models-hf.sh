#!/bin/bash

# ============================================================================
# WAN 2.1 Model Downloader (Hugging Face)
# Downloads WAN 2.1 models from Hugging Face
# ============================================================================

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"

echo "🎬 WAN 2.1 Model Downloader (Hugging Face)"
echo "==========================================="
echo

# Create model directories
echo "📁 Creating model directories..."
mkdir -p "$COMFYUI_DIR/models/diffusion_models"
mkdir -p "$COMFYUI_DIR/models/text_encoders"
mkdir -p "$COMFYUI_DIR/models/vae"
mkdir -p "$COMFYUI_DIR/models/checkpoints"

# Function to download from Hugging Face
download_hf_model() {
    local repo="$1"
    local filename="$2"
    local target_dir="$3"
    local target_file="$target_dir/$filename"
    
    echo "📥 Downloading $filename from $repo..."
    
    local url="https://huggingface.co/$repo/resolve/main/$filename"
    
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

echo "🚀 Starting WAN 2.1 model downloads from Hugging Face..."
echo

# Download WAN 2.1 models
echo "📥 Downloading WAN 2.1 models..."

# WAN 2.1 Diffusion Model
echo "1. WAN 2.1 Diffusion Model..."
download_hf_model "wan-research/wan2.1" "diffusion_pytorch_model-00001-of-00007.safetensors" "$COMFYUI_DIR/models/diffusion_models"

# WAN 2.1 Text Encoder
echo "2. WAN 2.1 Text Encoder..."
download_hf_model "wan-research/wan2.1" "models_t5_umt5-xxl-enc-bf16.pth" "$COMFYUI_DIR/models/text_encoders"

# WAN 2.1 VAE
echo "3. WAN 2.1 VAE..."
download_hf_model "wan-research/wan2.1" "Wan2.1_VAE.pth" "$COMFYUI_DIR/models/vae"

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
