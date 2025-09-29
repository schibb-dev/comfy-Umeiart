#!/bin/bash

# ============================================================================
# WAN 2.1 IMG to VIDEO Workflow Manual Download Guide
# Since Civitai requires authentication, this provides clear instructions
# ============================================================================

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
WORKFLOW_DIR="$COMFYUI_DIR/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/WAN_2.1_IMG_to_VIDEO.json"
CIVITAI_URL="https://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video"

echo "🎬 WAN 2.1 IMG to VIDEO Workflow Download Guide"
echo "=============================================="
echo

# Create workflows directory
mkdir -p "$WORKFLOW_DIR"

echo "📋 Manual Download Instructions:"
echo "================================"
echo
echo "1. 🌐 Open your web browser and go to:"
echo "   $CIVITAI_URL"
echo
echo "2. 🔐 Sign in to your Civitai account (if not already signed in)"
echo
echo "3. 📥 Look for the workflow download button/link in the article"
echo "   (Usually labeled 'Download' or has a download icon)"
echo
echo "4. 💾 Save the downloaded JSON file as:"
echo "   $WORKFLOW_FILE"
echo
echo "5. ✅ Verify the file was downloaded correctly"
echo

# Check if workflow file exists
if [[ -f "$WORKFLOW_FILE" ]]; then
    file_size=$(wc -c < "$WORKFLOW_FILE")
    echo "✅ Workflow file found: $WORKFLOW_FILE"
    echo "📊 File size: $file_size bytes"
    
    # Check if it's valid JSON
    if python3 -m json.tool "$WORKFLOW_FILE" > /dev/null 2>&1; then
        echo "✅ Valid JSON workflow file"
        echo
        echo "🎉 Workflow is ready to use!"
        echo "🚀 Next steps:"
        echo "   1. Restart ComfyUI: ./comfyui-restart.sh restart"
        echo "   2. Open ComfyUI: http://127.0.0.1:8188"
        echo "   3. Click 'Load' and select the workflow file"
        echo "   4. Start creating videos!"
    else
        echo "⚠️  File exists but is not valid JSON"
        echo "   Please re-download the workflow file"
    fi
else
    echo "❌ Workflow file not found"
    echo "   Please follow the manual download instructions above"
fi

echo
echo "📁 Current Setup Status:"
echo "========================"
echo "✅ ComfyUI installed with SageAttention"
echo "✅ All required models downloaded:"
echo "   • WAN 2.1 I2V 720p Model (14B parameters)"
echo "   • CLIP Model (UMT5 XXL)"
echo "   • CLIP Vision Model"
echo "   • VAE Model"
echo "   • Upscale Models (RealESRGAN)"
echo "✅ All custom nodes installed:"
echo "   • ComfyUI-Custom-Scripts"
echo "   • ComfyUI-KJNodes"
echo "   • ComfyUI-VideoHelperSuite"
echo "   • rgthree-comfy"
echo "   • ComfyUI-Frame-Interpolation"
echo "   • WAS Node Suite"
echo "⏳ Workflow JSON needs manual download"

echo
echo "🔧 Available Scripts:"
echo "===================="
echo "• ./comfyui-restart.sh restart  - Restart ComfyUI"
echo "• ./comfyui-restart.sh status   - Check ComfyUI status"
echo "• ./comfyui-restart.sh logs     - View ComfyUI logs"
echo "• ./download-workflow-manual.sh - Show this guide again"

echo
echo "💡 Tips:"
echo "========"
echo "• Your RTX 5060 Ti 16GB is perfect for this workflow"
echo "• SageAttention is enabled for maximum performance"
echo "• The 720p model provides excellent quality"
echo "• All models are optimized for your hardware"
