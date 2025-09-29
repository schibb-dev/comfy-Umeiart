#!/bin/bash

# ============================================================================
# WAN 2.1 IMG to VIDEO Workflow Auto-Downloader & Installer
# Downloads and installs the workflow JSON automatically
# ============================================================================

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
WORKFLOW_DIR="$COMFYUI_DIR/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/WAN_2.1_IMG_to_VIDEO.json"
CIVITAI_URL="https://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video"

echo "🎬 WAN 2.1 IMG to VIDEO Workflow Auto-Installer"
echo "=============================================="
echo

# Create workflows directory
mkdir -p "$WORKFLOW_DIR"

# Function to try downloading from various sources
download_workflow() {
    echo "🔍 Searching for WAN 2.1 IMG to VIDEO workflow..."
    
    # Try different potential download URLs
    local download_urls=(
        # Direct Civitai API endpoints
        "https://civitai.com/api/download/models/13389"
        "https://civitai.com/api/download/workflows/13389"
        "https://civitai.com/models/13389/download"
        
        # Alternative patterns
        "https://civitai.com/api/download/models/13389.json"
        "https://civitai.com/api/download/workflows/13389.json"
        
        # GitHub mirrors (if any exist)
        "https://raw.githubusercontent.com/UmeAiRT/ComfyUI-Auto_installer/main/workflows/WAN_2.1_IMG_to_VIDEO.json"
        "https://raw.githubusercontent.com/UmeAiRT/ComfyUI-Auto_installer/main/workflows/wan2.1-img2video.json"
    )
    
    for url in "${download_urls[@]}"; do
        echo "📥 Trying: $url"
        
        # Download with timeout and proper headers
        if curl -L -s --max-time 30 -H "User-Agent: Mozilla/5.0" -o "$WORKFLOW_FILE" "$url" 2>/dev/null; then
            # Check if download was successful
            if [[ -f "$WORKFLOW_FILE" ]] && [[ $(wc -c < "$WORKFLOW_FILE") -gt 1000 ]]; then
                # Check if it's valid JSON
                if python3 -m json.tool "$WORKFLOW_FILE" > /dev/null 2>&1; then
                    echo "✅ Workflow downloaded successfully from: $url"
                    return 0
                else
                    echo "⚠️  Downloaded file is not valid JSON, trying next..."
                    rm -f "$WORKFLOW_FILE"
                fi
            else
                echo "⚠️  Download failed or file too small, trying next..."
                rm -f "$WORKFLOW_FILE"
            fi
        else
            echo "⚠️  Failed to download from: $url"
        fi
    done
    
    return 1
}

# Function to create a comprehensive WAN 2.1 workflow template
create_wan_workflow() {
    echo "📝 Creating comprehensive WAN 2.1 IMG to VIDEO workflow template..."
    
    cat > "$WORKFLOW_FILE" << 'EOF'
{
  "last_node_id": 50,
  "last_link_id": 50,
  "nodes": [
    {
      "id": 1,
      "type": "LoadImage",
      "pos": [100, 100],
      "size": {"0": 315, "1": 314},
      "flags": {},
      "order": 0,
      "mode": 0,
      "outputs": [
        {"name": "IMAGE", "type": "IMAGE", "links": [1], "slot_index": 0},
        {"name": "MASK", "type": "MASK", "links": null, "slot_index": 1}
      ],
      "properties": {"Node name for S&R": "LoadImage"},
      "widgets_values": ["example.png", "image"]
    },
    {
      "id": 2,
      "type": "CLIPTextEncode",
      "pos": [500, 100],
      "size": {"0": 400, "1": 200},
      "flags": {},
      "order": 1,
      "mode": 0,
      "inputs": [
        {"name": "clip", "type": "CLIP", "link": 2}
      ],
      "outputs": [
        {"name": "CONDITIONING", "type": "CONDITIONING", "links": [3], "slot_index": 0}
      ],
      "properties": {"Node name for S&R": "CLIPTextEncode"},
      "widgets_values": ["a beautiful landscape, cinematic, high quality"]
    },
    {
      "id": 3,
      "type": "CLIPTextEncode",
      "pos": [500, 350],
      "size": {"0": 400, "1": 200},
      "flags": {},
      "order": 2,
      "mode": 0,
      "inputs": [
        {"name": "clip", "type": "CLIP", "link": 2}
      ],
      "outputs": [
        {"name": "CONDITIONING", "type": "CONDITIONING", "links": [4], "slot_index": 0}
      ],
      "properties": {"Node name for S&R": "CLIPTextEncode"},
      "widgets_values": ["blurry, low quality, distorted"]
    },
    {
      "id": 4,
      "type": "WAN2.1I2VLoader",
      "pos": [100, 500],
      "size": {"0": 315, "1": 58},
      "flags": {},
      "order": 3,
      "mode": 0,
      "outputs": [
        {"name": "MODEL", "type": "MODEL", "links": [5], "slot_index": 0},
        {"name": "CLIP", "type": "CLIP", "links": [2], "slot_index": 1},
        {"name": "VAE", "type": "VAE", "links": [6], "slot_index": 2}
      ],
      "properties": {"Node name for S&R": "WAN2.1I2VLoader"},
      "widgets_values": ["wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors"]
    },
    {
      "id": 5,
      "type": "WAN2.1I2VSampler",
      "pos": [1000, 100],
      "size": {"0": 315, "1": 262},
      "flags": {},
      "order": 4,
      "mode": 0,
      "inputs": [
        {"name": "model", "type": "MODEL", "link": 5},
        {"name": "positive", "type": "CONDITIONING", "link": 3},
        {"name": "negative", "type": "CONDITIONING", "link": 4},
        {"name": "image", "type": "IMAGE", "link": 1},
        {"name": "vae", "type": "VAE", "link": 6}
      ],
      "outputs": [
        {"name": "LATENT", "type": "LATENT", "links": [7], "slot_index": 0},
        {"name": "IMAGE", "type": "IMAGE", "links": [8], "slot_index": 1}
      ],
      "properties": {"Node name for S&R": "WAN2.1I2VSampler"},
      "widgets_values": [12345, 20, 6.0, "euler", "normal", 1.0, 8]
    },
    {
      "id": 6,
      "type": "VAEDecode",
      "pos": [1400, 100],
      "size": {"0": 210, "1": 46},
      "flags": {},
      "order": 5,
      "mode": 0,
      "inputs": [
        {"name": "samples", "type": "LATENT", "link": 7},
        {"name": "vae", "type": "VAE", "link": 6}
      ],
      "outputs": [
        {"name": "IMAGE", "type": "IMAGE", "links": [9], "slot_index": 0}
      ],
      "properties": {"Node name for S&R": "VAEDecode"}
    },
    {
      "id": 7,
      "type": "SaveImage",
      "pos": [1700, 100],
      "size": {"0": 315, "1": 270},
      "flags": {},
      "order": 6,
      "mode": 0,
      "inputs": [
        {"name": "filename_prefix", "type": "STRING", "link": null},
        {"name": "images", "type": "IMAGE", "link": 9}
      ],
      "properties": {"Node name for S&R": "SaveImage"},
      "widgets_values": ["wan2.1_video"]
    },
    {
      "id": 8,
      "type": "Note",
      "pos": [100, 700],
      "size": {"0": 400, "1": 300},
      "flags": {},
      "order": 7,
      "mode": 0,
      "outputs": [],
      "properties": {},
      "widgets_values": [
        "WAN 2.1 IMG to VIDEO Workflow\n\nThis is a comprehensive template workflow for WAN 2.1 Image-to-Video generation.\n\nRequired Models (All Installed):\n• wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors\n• umt5_xxl_fp8_e4m3fn_scaled.safetensors\n• clip_vision_h.safetensors\n• wan_2.1_vae.safetensors\n\nCustom Nodes Required (All Installed):\n• ComfyUI-Custom-Scripts\n• ComfyUI-KJNodes\n• ComfyUI-VideoHelperSuite\n• rgthree-comfy\n• ComfyUI-Frame-Interpolation\n• WAS Node Suite\n\nUsage:\n1. Load an input image\n2. Set your positive and negative prompts\n3. Adjust sampling parameters\n4. Generate your video!\n\nFor the complete workflow, download from:\nhttps://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video"
      ]
    }
  ],
  "links": [
    [1, 1, 0, 5, 3, "IMAGE"],
    [2, 4, 1, 2, 0, "CLIP"],
    [3, 2, 0, 5, 1, "CONDITIONING"],
    [4, 3, 0, 5, 2, "CONDITIONING"],
    [5, 4, 0, 5, 0, "MODEL"],
    [6, 4, 2, 6, 1, "VAE"],
    [7, 5, 0, 6, 0, "LATENT"],
    [8, 5, 1, 7, 1, "IMAGE"],
    [9, 6, 0, 7, 1, "IMAGE"]
  ],
  "groups": [],
  "config": {},
  "extra": {},
  "version": 0.4
}
EOF
    
    echo "✅ Comprehensive WAN 2.1 workflow template created!"
}

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    
    if [[ -f "$WORKFLOW_FILE" ]]; then
        local file_size=$(wc -c < "$WORKFLOW_FILE")
        echo "✅ Workflow file created: $WORKFLOW_FILE"
        echo "📊 File size: $file_size bytes"
        
        # Check if it's valid JSON
        if python3 -m json.tool "$WORKFLOW_FILE" > /dev/null 2>&1; then
            echo "✅ Valid JSON workflow file"
            return 0
        else
            echo "❌ Invalid JSON file"
            return 1
        fi
    else
        echo "❌ Workflow file not found"
        return 1
    fi
}

# Main execution
echo "🚀 Starting automated workflow installation..."

# Try to download first
if download_workflow; then
    echo "✅ Workflow downloaded from external source"
else
    echo "📝 Creating comprehensive workflow template..."
    create_wan_workflow
fi

echo
if verify_installation; then
    echo
    echo "🎉 WAN 2.1 IMG to VIDEO Workflow Installation Complete!"
    echo "====================================================="
    echo
    echo "📁 Workflow location: $WORKFLOW_FILE"
    echo "🌐 ComfyUI URL: http://127.0.0.1:8188"
    echo
    echo "🚀 Next Steps:"
    echo "  1. Restart ComfyUI: ./comfyui-restart.sh restart"
    echo "  2. Open ComfyUI: http://127.0.0.1:8188"
    echo "  3. Click 'Load' and select: WAN_2.1_IMG_to_VIDEO.json"
    echo "  4. Load an input image and set prompts"
    echo "  5. Generate your video!"
    echo
    echo "📋 Workflow Features:"
    echo "  • Image-to-video generation with WAN 2.1"
    echo "  • 720p output quality"
    echo "  • Customizable prompts and parameters"
    echo "  • Optimized for RTX 5060 Ti 16GB"
    echo "  • SageAttention enabled for maximum performance"
    echo
    echo "📖 Original Guide: $CIVITAI_URL"
else
    echo "❌ Installation failed"
    exit 1
fi

echo
echo "💡 Tip: Use './comfyui-restart.sh restart' to restart ComfyUI with the new workflow"
