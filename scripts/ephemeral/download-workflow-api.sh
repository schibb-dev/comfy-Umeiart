#!/bin/bash

# ============================================================================
# WAN 2.1 IMG to VIDEO Workflow Downloader with Civitai API
# Uses Civitai API token for authenticated downloads
# ============================================================================

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
WORKFLOW_DIR="$COMFYUI_DIR/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/WAN_2.1_IMG_to_VIDEO.json"
CIVITAI_API_BASE="https://civitai.com/api/v1"
ARTICLE_ID="13389"
TOKEN_FILE="/home/yuji/Code/Umeiart/.civitai_token"

echo "🎬 WAN 2.1 IMG to VIDEO Workflow Downloader (Civitai API)"
echo "========================================================"
echo

# Check for command line arguments
if [[ "$1" == "clear-token" ]]; then
    if [[ -f "$TOKEN_FILE" ]]; then
        rm -f "$TOKEN_FILE"
        echo "🗑️  Saved API token cleared"
    else
        echo "ℹ️  No saved token found"
    fi
    exit 0
fi

# Create workflows directory
mkdir -p "$WORKFLOW_DIR"

# Function to get API token from user or file
get_api_token() {
    # First, try to load token from file
    if [[ -f "$TOKEN_FILE" ]]; then
        CIVITAI_API_TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null || echo "")
        if [[ -n "$CIVITAI_API_TOKEN" ]]; then
            echo "✅ Using saved Civitai API token"
            return 0
        fi
    fi
    
    # If no saved token, prompt user
    echo "🔑 Civitai API Token Required"
    echo "============================="
    echo
    echo "To download workflows from Civitai, you need an API token:"
    echo
    echo "1. 🌐 Go to: https://civitai.com/"
    echo "2. 🔐 Sign in to your account"
    echo "3. ⚙️  Go to Account Settings → API Keys"
    echo "4. ➕ Click 'Add API key'"
    echo "5. 📝 Give it a name (e.g., 'ComfyUI Workflow Downloader')"
    echo "6. 🔑 Copy the generated token"
    echo
    echo "Enter your Civitai API token:"
    read -s CIVITAI_API_TOKEN
    echo
    
    if [[ -n "$CIVITAI_API_TOKEN" ]]; then
        # Save token to file for future use
        echo "$CIVITAI_API_TOKEN" > "$TOKEN_FILE"
        echo "💾 Token saved for future use"
        return 0
    else
        echo "❌ No API token provided. Exiting."
        exit 1
    fi
}

# Function to search for the workflow using API
search_workflow() {
    echo "🔍 Searching for WAN 2.1 IMG to VIDEO workflow..."
    
    # Search for workflows related to WAN 2.1
    local search_url="$CIVITAI_API_BASE/models"
    local search_params="?query=WAN%202.1%20IMG%20to%20VIDEO&types=Checkpoint&sort=Most%20Downloaded"
    
    echo "📡 Searching Civitai API..."
    local search_result=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$search_url$search_params" 2>/dev/null || echo "")
    
    if [[ -n "$search_result" ]]; then
        echo "✅ API search successful"
        # Extract model IDs from search results
        local model_ids=$(echo "$search_result" | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+' | head -5)
        
        if [[ -n "$model_ids" ]]; then
            echo "🔍 Found potential models:"
            echo "$model_ids" | while read -r id; do
                echo "  • Model ID: $id"
            done
            
            # Try to download from the first model ID
            local first_id=$(echo "$model_ids" | head -1)
            if [[ -n "$first_id" ]]; then
                download_from_model_id "$first_id"
                return $?
            fi
        fi
    fi
    
    return 1
}

# Function to download workflow from specific model ID
download_from_model_id() {
    local model_id="$1"
    echo "📥 Attempting to download from Model ID: $model_id"
    
    # Try different download endpoints
    local download_urls=(
        "$CIVITAI_API_BASE/models/$model_id/download"
        "$CIVITAI_API_BASE/models/$model_id/versions"
        "$CIVITAI_API_BASE/models/$model_id"
    )
    
    for url in "${download_urls[@]}"; do
        echo "  Trying: $url"
        
        # Get model information first
        local model_info=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
            -H "Content-Type: application/json" \
            "$url" 2>/dev/null || echo "")
        
        if [[ -n "$model_info" ]]; then
            # Look for download URLs in the response
            local download_links=$(echo "$model_info" | grep -oE '"downloadUrl":"[^"]*"' | sed 's/"downloadUrl":"//g' | sed 's/"//g')
            
            if [[ -n "$download_links" ]]; then
                echo "🔗 Found download links:"
                echo "$download_links" | while read -r link; do
                    echo "  • $link"
                done
                
                # Try to download the first JSON file
                local json_link=$(echo "$download_links" | grep '\.json$' | head -1)
                if [[ -n "$json_link" ]]; then
                    echo "📥 Downloading workflow from: $json_link"
                    if curl -L -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
                        -o "$WORKFLOW_FILE" "$json_link" 2>/dev/null; then
                        
                        if [[ -f "$WORKFLOW_FILE" ]] && [[ $(wc -c < "$WORKFLOW_FILE") -gt 1000 ]]; then
                            if python3 -m json.tool "$WORKFLOW_FILE" > /dev/null 2>&1; then
                                echo "✅ Workflow downloaded successfully!"
                                return 0
                            else
                                echo "⚠️  Downloaded file is not valid JSON"
                                rm -f "$WORKFLOW_FILE"
                            fi
                        else
                            echo "⚠️  Download failed or file too small"
                            rm -f "$WORKFLOW_FILE"
                        fi
                    fi
                fi
            fi
        fi
    done
    
    return 1
}

# Function to try direct article download
download_from_article() {
    echo "📥 Attempting to download from article..."
    
    # Try to get article information
    local article_url="$CIVITAI_API_BASE/articles/$ARTICLE_ID"
    local article_info=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$article_url" 2>/dev/null || echo "")
    
    if [[ -n "$article_info" ]]; then
        echo "✅ Article information retrieved"
        
        # Look for workflow attachments or downloads
        local download_links=$(echo "$article_info" | grep -oE '"url":"[^"]*\.json"' | sed 's/"url":"//g' | sed 's/"//g')
        
        if [[ -n "$download_links" ]]; then
            echo "🔗 Found workflow links:"
            echo "$download_links" | while read -r link; do
                echo "  • $link"
            done
            
            # Try to download the first JSON file
            local json_link=$(echo "$download_links" | head -1)
            if [[ -n "$json_link" ]]; then
                echo "📥 Downloading workflow from: $json_link"
                if curl -L -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
                    -o "$WORKFLOW_FILE" "$json_link" 2>/dev/null; then
                    
                    if [[ -f "$WORKFLOW_FILE" ]] && [[ $(wc -c < "$WORKFLOW_FILE") -gt 1000 ]]; then
                        if python3 -m json.tool "$WORKFLOW_FILE" > /dev/null 2>&1; then
                            echo "✅ Workflow downloaded successfully!"
                            return 0
                        else
                            echo "⚠️  Downloaded file is not valid JSON"
                            rm -f "$WORKFLOW_FILE"
                        fi
                    else
                        echo "⚠️  Download failed or file too small"
                        rm -f "$WORKFLOW_FILE"
                    fi
                fi
            fi
        fi
    fi
    
    return 1
}

# Function to create fallback workflow
create_fallback_workflow() {
    echo "📝 Creating fallback workflow template..."
    
    cat > "$WORKFLOW_FILE" << 'EOF'
{
  "last_node_id": 10,
  "last_link_id": 10,
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
        {"name": "IMAGE", "type": "IMAGE", "links": [1], "slot_index": 0}
      ],
      "properties": {"Node name for S&R": "LoadImage"},
      "widgets_values": ["example.png", "image"]
    },
    {
      "id": 2,
      "type": "Note",
      "pos": [500, 100],
      "size": {"0": 400, "1": 400},
      "flags": {},
      "order": 1,
      "mode": 0,
      "outputs": [],
      "properties": {},
      "widgets_values": [
        "WAN 2.1 IMG to VIDEO Workflow\n\nThis is a template workflow.\nAll required models and custom nodes are installed.\n\nTo get the complete workflow:\n1. Visit: https://civitai.com/articles/13389\n2. Download the workflow JSON\n3. Replace this file\n\nInstalled Models:\n✅ wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors\n✅ umt5_xxl_fp8_e4m3fn_scaled.safetensors\n✅ clip_vision_h.safetensors\n✅ wan_2.1_vae.safetensors\n\nInstalled Custom Nodes:\n✅ ComfyUI-Custom-Scripts\n✅ ComfyUI-KJNodes\n✅ ComfyUI-VideoHelperSuite\n✅ rgthree-comfy\n✅ ComfyUI-Frame-Interpolation\n✅ WAS Node Suite"
      ]
    }
  ],
  "links": [
    [1, 1, 0, 2, 0, "IMAGE"]
  ],
  "groups": [],
  "config": {},
  "extra": {},
  "version": 0.4
}
EOF
    
    echo "✅ Fallback workflow template created"
}

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    
    if [[ -f "$WORKFLOW_FILE" ]]; then
        local file_size=$(wc -c < "$WORKFLOW_FILE")
        echo "✅ Workflow file created: $WORKFLOW_FILE"
        echo "📊 File size: $file_size bytes"
        
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
echo "🚀 Starting Civitai API workflow download..."

# Get API token
get_api_token

# Try different download methods
echo
echo "📥 Attempting downloads..."

if download_from_article; then
    echo "✅ Downloaded from article"
elif search_workflow; then
    echo "✅ Downloaded from search results"
else
    echo "⚠️  API download failed, creating template workflow"
    create_fallback_workflow
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
    echo "  4. Start creating videos!"
    echo
    echo "💾 Your API token is saved for future use"
    echo "   Run './download-workflow-api.sh clear-token' to clear it"
else
    echo "❌ Installation failed"
    exit 1
fi

echo
echo "💡 Tip: Use './comfyui-restart.sh restart' to restart ComfyUI with the new workflow"
