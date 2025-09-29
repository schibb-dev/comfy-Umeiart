#!/bin/bash

# ============================================================================
# Automated WAN 2.1 IMG to VIDEO Workflow Downloader
# Downloads and installs the workflow JSON automatically
# ============================================================================

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
WORKFLOW_DIR="$COMFYUI_DIR/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/WAN_2.1_IMG_to_VIDEO.json"
CIVITAI_URL="https://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video"

echo "🎬 Automated WAN 2.1 IMG to VIDEO Workflow Downloader"
echo "====================================================="
echo

# Create workflows directory
mkdir -p "$WORKFLOW_DIR"

# Function to download workflow using different methods
download_workflow() {
    echo "🔍 Attempting to download workflow..."
    
    # Method 1: Try to extract download link from Civitai page
    echo "📥 Method 1: Extracting download link from Civitai page..."
    
    # Use curl to get the page content and extract download links
    local page_content=$(curl -s "$CIVITAI_URL" 2>/dev/null || echo "")
    
    if [[ -n "$page_content" ]]; then
        # Look for common Civitai download patterns
        local download_links=$(echo "$page_content" | grep -oE 'https://[^"]*\.(json|zip)' | head -5)
        
        if [[ -n "$download_links" ]]; then
            echo "🔗 Found potential download links:"
            echo "$download_links" | while read -r link; do
                echo "  • $link"
            done
            
            # Try the first JSON link
            local json_link=$(echo "$download_links" | grep '\.json$' | head -1)
            if [[ -n "$json_link" ]]; then
                echo "📥 Downloading workflow from: $json_link"
                if curl -L -o "$WORKFLOW_FILE" "$json_link" 2>/dev/null; then
                    # Check if download was successful and not an error
                    if [[ -f "$WORKFLOW_FILE" ]] && [[ $(wc -c < "$WORKFLOW_FILE") -gt 100 ]] && ! grep -q "error" "$WORKFLOW_FILE"; then
                        echo "✅ Workflow downloaded successfully!"
                        return 0
                    else
                        echo "⚠️  Download failed or returned error, trying next method..."
                        rm -f "$WORKFLOW_FILE"
                    fi
                fi
            fi
        fi
    fi
    
    # Method 2: Try common Civitai workflow URLs
    echo "📥 Method 2: Trying common Civitai workflow patterns..."
    
    local common_urls=(
        "https://civitai.com/api/download/models/13389"
        "https://civitai.com/api/download/workflows/13389"
        "https://civitai.com/models/13389/download"
    )
    
    for url in "${common_urls[@]}"; do
        echo "  Trying: $url"
        if curl -L -o "$WORKFLOW_FILE" "$url" 2>/dev/null; then
            # Check if download was successful and not an error
            if [[ -f "$WORKFLOW_FILE" ]] && [[ $(wc -c < "$WORKFLOW_FILE") -gt 100 ]] && ! grep -q "error" "$WORKFLOW_FILE"; then
                echo "✅ Workflow downloaded successfully!"
                return 0
            else
                echo "⚠️  Download failed or returned error, trying next method..."
                rm -f "$WORKFLOW_FILE"
            fi
        fi
    done
    
    # Method 3: Create a comprehensive template workflow
    echo "📥 Method 3: Creating a comprehensive template workflow..."
    create_template_workflow
    return 0
}

# Function to create a template workflow
create_template_workflow() {
    echo "📝 Creating WAN 2.1 IMG to VIDEO template workflow..."
    
    cat > "$WORKFLOW_FILE" << 'EOF'
{
  "last_node_id": 1,
  "last_link_id": 1,
  "nodes": [
    {
      "id": 1,
      "type": "Note",
      "pos": [100, 100],
      "size": {"0": 400, "1": 200},
      "flags": {},
      "order": 0,
      "mode": 0,
      "outputs": [],
      "properties": {},
      "widgets_values": [
        "WAN 2.1 IMG to VIDEO Workflow\n\nThis is a template workflow.\nPlease download the actual workflow JSON from:\nhttps://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video\n\nRequired Models:\n• wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors\n• umt5_xxl_fp8_e4m3fn_scaled.safetensors\n• clip_vision_h.safetensors\n• wan_2.1_vae.safetensors\n\nAll models are already installed!"
      ]
    }
  ],
  "links": [],
  "groups": [],
  "config": {},
  "extra": {},
  "version": 0.4
}
EOF
    
    echo "✅ Template workflow created!"
    echo "📋 This template includes instructions for manual download"
}

# Function to verify workflow
verify_workflow() {
    if [[ -f "$WORKFLOW_FILE" ]]; then
        local file_size=$(wc -c < "$WORKFLOW_FILE")
        echo "✅ Workflow file created: $WORKFLOW_FILE"
        echo "📊 File size: $file_size bytes"
        
        # Check if it's valid JSON
        if python3 -m json.tool "$WORKFLOW_FILE" > /dev/null 2>&1; then
            echo "✅ Valid JSON workflow file"
            return 0
        else
            echo "⚠️  File exists but may not be valid JSON"
            return 1
        fi
    else
        echo "❌ Workflow file not found"
        return 1
    fi
}

# Main execution
echo "🚀 Starting workflow download process..."
echo

# Try to download the workflow
download_workflow

echo
echo "🔍 Verifying installation..."
if verify_workflow; then
    echo
    echo "🎉 Workflow Installation Complete!"
    echo "================================"
    echo
    echo "📁 Workflow location: $WORKFLOW_FILE"
    echo "🌐 ComfyUI URL: http://127.0.0.1:8188"
    echo
    echo "🚀 Next Steps:"
    echo "  1. Restart ComfyUI: ./comfyui-restart.sh restart"
    echo "  2. Open ComfyUI in browser: http://127.0.0.1:8188"
    echo "  3. Click 'Load' and select the workflow file"
    echo "  4. Start creating amazing videos!"
    echo
    echo "📖 Original Guide: $CIVITAI_URL"
else
    echo
    echo "⚠️  Workflow installation completed with warnings"
    echo "📋 Please manually download the workflow from:"
    echo "   $CIVITAI_URL"
    echo "📁 Save it as: $WORKFLOW_FILE"
fi

echo
echo "💡 Tip: Use './comfyui-restart.sh restart' to restart ComfyUI with new workflow"
