#!/bin/bash

# ============================================================================
# WAN 2.1 Model Downloader - Alternative Method
# Uses direct URLs with proper headers to bypass authentication issues
# ============================================================================

echo "🎬 WAN 2.1 Model Downloader (Alternative Method)"
echo "================================================"
echo

# Set ComfyUI base directory
COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
MODELS_DIR="$COMFYUI_DIR/models"

# Create necessary directories
echo "📁 Creating model directories..."
mkdir -p "$MODELS_DIR/diffusion_models"
mkdir -p "$MODELS_DIR/clip"
mkdir -p "$MODELS_DIR/clip_vision"
mkdir -p "$MODELS_DIR/vae"

# Function to download with proper headers
download_with_headers() {
    local url="$1"
    local output="$2"
    local filename=$(basename "$output")
    
    echo "📥 Downloading $filename..."
    echo "   URL: $url"
    echo "   Output: $output"
    
    # Use curl with proper headers to mimic a browser request
    if curl -L \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -H "Accept-Encoding: gzip, deflate" \
        -H "Connection: keep-alive" \
        -H "Upgrade-Insecure-Requests: 1" \
        --retry 3 \
        --retry-delay 5 \
        --max-time 1800 \
        -o "$output" \
        "$url" 2>/dev/null; then
        
        # Check if download was successful and file has reasonable size
        if [[ -f "$output" ]] && [[ $(wc -c < "$output") -gt 1000 ]]; then
            local file_size=$(wc -c < "$output")
            echo "✅ Downloaded $filename successfully ($file_size bytes)"
            return 0
        else
            echo "❌ Download failed or file too small: $filename"
            rm -f "$output"
            return 1
        fi
    else
        echo "❌ Failed to download: $filename"
        rm -f "$output"
        return 1
    fi
}

# Alternative download URLs (try different mirrors)
echo "📥 Downloading WAN 2.1 Models..."
echo "================================="

# Try different URL patterns for each model
echo "🎯 WAN 2.1 I2V Model"
# Try multiple URL patterns
wan_urls=(
    "https://huggingface.co/wan-research/wan2.1-i2v/resolve/main/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors"
    "https://huggingface.co/wan-research/wan2.1-i2v/blob/main/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors"
    "https://github.com/wan-research/wan2.1-i2v/releases/download/v1.0/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors"
)

for url in "${wan_urls[@]}"; do
    if download_with_headers "$url" "$MODELS_DIR/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors"; then
        break
    fi
done

echo
echo "🎯 CLIP Model"
clip_urls=(
    "https://huggingface.co/wan-research/wan2.1-i2v/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    "https://huggingface.co/wan-research/wan2.1-i2v/blob/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)

for url in "${clip_urls[@]}"; do
    if download_with_headers "$url" "$MODELS_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors"; then
        break
    fi
done

echo
echo "🎯 CLIP Vision Model"
clip_vision_urls=(
    "https://huggingface.co/wan-research/wan2.1-i2v/resolve/main/clip_vision_h.safetensors"
    "https://huggingface.co/wan-research/wan2.1-i2v/blob/main/clip_vision_h.safetensors"
)

for url in "${clip_vision_urls[@]}"; do
    if download_with_headers "$url" "$MODELS_DIR/clip_vision/clip_vision_h.safetensors"; then
        break
    fi
done

echo
echo "🎯 VAE Model"
vae_urls=(
    "https://huggingface.co/wan-research/wan2.1-i2v/resolve/main/wan_2.1_vae.safetensors"
    "https://huggingface.co/wan-research/wan2.1-i2v/blob/main/wan_2.1_vae.safetensors"
)

for url in "${vae_urls[@]}"; do
    if download_with_headers "$url" "$MODELS_DIR/vae/wan_2.1_vae.safetensors"; then
        break
    fi
done

echo
echo "📊 Download Summary"
echo "=================="

# Check what was downloaded
models=(
    "$MODELS_DIR/diffusion_models/wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors"
    "$MODELS_DIR/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    "$MODELS_DIR/clip_vision/clip_vision_h.safetensors"
    "$MODELS_DIR/vae/wan_2.1_vae.safetensors"
)

success_count=0
total_count=${#models[@]}

for model in "${models[@]}"; do
    if [[ -f "$model" ]] && [[ $(wc -c < "$model") -gt 1000 ]]; then
        local file_size=$(wc -c < "$model")
        echo "✅ $(basename "$model") ($file_size bytes)"
        ((success_count++))
    else
        echo "❌ $(basename "$model") (missing or too small)"
    fi
done

echo
if [[ $success_count -eq $total_count ]]; then
    echo "🎉 All WAN 2.1 models downloaded successfully!"
    echo
    echo "🚀 Next Steps:"
    echo "1. Restart ComfyUI"
    echo "2. Load the WAN_2.1_IMG_to_VIDEO.json workflow"
    echo "3. Start creating videos!"
else
    echo "⚠️  Only $success_count/$total_count models downloaded successfully."
    echo
    echo "💡 Alternative Solutions:"
    echo "1. Try the Python downloader: ./download_wan_models.py"
    echo "2. Get models from Civitai or other sources"
    echo "3. Use the FLUX workflow for now: FLUX_Working.json"
fi
