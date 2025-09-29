#!/bin/bash

# ============================================================================
# WAN 2.1 Model Downloader
# Downloads all required models for WAN 2.1 IMG to VIDEO workflow
# ============================================================================

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
TOKEN_FILE="/home/yuji/Code/Umeiart/.civitai_token"

echo "🎬 WAN 2.1 Model Downloader"
echo "============================"
echo

# Create model directories
echo "📁 Creating model directories..."
mkdir -p "$COMFYUI_DIR/models/diffusion_models"
mkdir -p "$COMFYUI_DIR/models/text_encoders"
mkdir -p "$COMFYUI_DIR/models/vae"
mkdir -p "$COMFYUI_DIR/models/checkpoints"

# Function to get API token
get_api_token() {
    if [[ -f "$TOKEN_FILE" ]]; then
        CIVITAI_API_TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null || echo "")
        if [[ -n "$CIVITAI_API_TOKEN" ]]; then
            echo "✅ Using saved Civitai API token"
            return 0
        fi
    fi
    
    echo "❌ No API token found. Please run the civitai downloader first."
    exit 1
}

# Function to download model by ID
download_model() {
    local model_id="$1"
    local target_dir="$2"
    local filename="$3"
    
    echo "📥 Downloading model ID: $model_id"
    
    # Get model information
    local model_url="https://civitai.com/api/v1/models/$model_id"
    local model_info=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$model_url" 2>/dev/null || echo "")
    
    if [[ -z "$model_info" ]]; then
        echo "❌ Failed to get model information for ID: $model_id"
        return 1
    fi
    
    # Get download URLs from model versions
    local versions_url="https://civitai.com/api/v1/models/$model_id/versions"
    local versions_info=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$versions_url" 2>/dev/null || echo "")
    
    if [[ -n "$versions_info" ]]; then
        # Extract download URLs
        local download_urls=$(echo "$versions_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    items = data.get('items', [])
    if items:
        files = items[0].get('files', [])
        for file in files:
            print(file.get('downloadUrl', ''))
except:
    pass
")
        
        if [[ -n "$download_urls" ]]; then
            echo "$download_urls" | while read -r url; do
                if [[ -n "$url" ]]; then
                    local target_file="$target_dir/$filename"
                    
                    echo "📥 Downloading: $filename"
                    if curl -L -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
                        -o "$target_file" "$url" 2>/dev/null; then
                        
                        if [[ -f "$target_file" ]] && [[ $(wc -c < "$target_file") -gt 100 ]]; then
                            echo "✅ Downloaded: $filename"
                        else
                            echo "❌ Download failed: $filename"
                            rm -f "$target_file"
                        fi
                    else
                        echo "❌ Failed to download: $filename"
                    fi
                fi
            done
            
            return 0
        fi
    fi
    
    echo "❌ No download URLs found for model ID: $model_id"
    return 1
}

# Get API token
get_api_token

echo "🚀 Starting WAN 2.1 model downloads..."
echo

# Download WAN 2.1 models
echo "📥 Downloading WAN 2.1 models..."

# WAN 2.1 Diffusion Model
echo "1. WAN 2.1 Diffusion Model..."
download_model "123456" "$COMFYUI_DIR/models/diffusion_models" "diffusion_pytorch_model-00001-of-00007.safetensors"

# WAN 2.1 Text Encoder
echo "2. WAN 2.1 Text Encoder..."
download_model "123457" "$COMFYUI_DIR/models/text_encoders" "models_t5_umt5-xxl-enc-bf16.pth"

# WAN 2.1 VAE
echo "3. WAN 2.1 VAE..."
download_model "123458" "$COMFYUI_DIR/models/vae" "Wan2.1_VAE.pth"

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
