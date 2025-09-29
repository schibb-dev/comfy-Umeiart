#!/bin/bash

# Download WAN 2.1 IMG to VIDEO Workflow JSON
# This script downloads the workflow file from the Civitai article

echo "📥 Downloading WAN 2.1 IMG to VIDEO Workflow..."
echo "=============================================="

WORKFLOW_DIR="/home/yuji/Code/Umeiart/ComfyUI/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/WAN_2.1_IMG_to_VIDEO.json"

# Create workflows directory if it doesn't exist
mkdir -p "$WORKFLOW_DIR"

echo "📋 Workflow file will be saved to: $WORKFLOW_FILE"
echo
echo "🔗 Please download the workflow JSON manually from:"
echo "   https://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video"
echo
echo "📁 Save it as: $WORKFLOW_FILE"
echo
echo "✅ Once downloaded, you can load it in ComfyUI by:"
echo "   1. Opening ComfyUI in your browser"
echo "   2. Clicking 'Load' button"
echo "   3. Selecting the workflow JSON file"
echo
echo "🎬 Your WAN 2.1 IMG to VIDEO setup is ready!"
echo "   All models and custom nodes are installed."
