#!/bin/bash
# Quick LoRA Download Script for FaceBlast Workflow
# Run this script to open Civitai search pages for each LoRA

echo "🎭 Opening Civitai search pages for WAN 2.1 LoRAs..."
echo ""

# Function to open URL in default browser
open_url() {
    if command -v xdg-open > /dev/null; then
        xdg-open "$1"
    elif command -v open > /dev/null; then
        open "$1"
    else
        echo "Please open: $1"
    fi
}

echo "📋 Priority LoRAs (ENABLED in workflow):"
echo "1. wan-thiccum-v3.safetensors"
open_url "https://civitai.com/search?q=wan%20thiccum%20v3"
sleep 2

echo "2. WAN_dr34mj0b.safetensors"
open_url "https://civitai.com/search?q=wan%20dr34mj0b"
sleep 2

echo "3. bounceV_01.safetensors"
open_url "https://civitai.com/search?q=bounceV%2001"
sleep 2

echo ""
echo "📋 Additional LoRAs (DISABLED in workflow):"
echo "4. wan-nsfw-e14-fixed.safetensors"
open_url "https://civitai.com/search?q=wan%20nsfw%20e14"
sleep 2

echo "5. wan_cumshot_i2v.safetensors"
open_url "https://civitai.com/search?q=wan%20cumshot%20i2v"
sleep 2

echo "6. facials60.safetensors"
open_url "https://civitai.com/search?q=facials60"
sleep 2

echo "7. Handjob-wan-e38.safetensors"
open_url "https://civitai.com/search?q=handjob%20wan%20e38"
sleep 2

echo ""
echo "✅ All Civitai search pages opened!"
echo "📁 Download files to: /home/yuji/Code/Umeiart/ComfyUI/models/loras/"
echo "🔍 Verify file sizes are several MB, not just 100+ bytes"
