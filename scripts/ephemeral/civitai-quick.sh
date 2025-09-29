#!/bin/bash

# ============================================================================
# Civitai Quick Downloader
# Quick access to common Civitai downloads
# ============================================================================

SCRIPT_DIR="/home/yuji/Code/Umeiart"
DOWNLOADER="$SCRIPT_DIR/civitai-downloader.sh"

echo "🎨 Civitai Quick Downloader"
echo "============================"
echo

# Check if main downloader exists
if [[ ! -f "$DOWNLOADER" ]]; then
    echo "❌ Main downloader not found: $DOWNLOADER"
    exit 1
fi

# Quick download functions
download_wan_workflow() {
    echo "🎬 Downloading WAN 2.1 IMG to VIDEO workflow..."
    "$DOWNLOADER" workflow 13389
}

download_popular_models() {
    echo "🔥 Downloading popular models..."
    echo "1. FLUX.1 [dev]"
    echo "2. SDXL Base"
    echo "3. Juggernaut XL"
    echo "4. Realistic Vision"
    echo "5. Custom search"
    echo
    echo "Select a model (1-5):"
    read -r choice
    
    case $choice in
        1) "$DOWNLOADER" model "FLUX.1 dev" ;;
        2) "$DOWNLOADER" model "SDXL Base" ;;
        3) "$DOWNLOADER" model "Juggernaut XL" ;;
        4) "$DOWNLOADER" model "Realistic Vision" ;;
        5) 
            echo "Enter search term:"
            read -r search_term
            "$DOWNLOADER" model "$search_term"
            ;;
        *) echo "❌ Invalid choice" ;;
    esac
}

download_popular_loras() {
    echo "🎭 Downloading popular LoRAs..."
    echo "1. Anime style"
    echo "2. Realistic style"
    echo "3. Art style"
    echo "4. Custom search"
    echo
    echo "Select a LoRA (1-4):"
    read -r choice
    
    case $choice in
        1) "$DOWNLOADER" lora "anime style" ;;
        2) "$DOWNLOADER" lora "realistic style" ;;
        3) "$DOWNLOADER" lora "art style" ;;
        4) 
            echo "Enter search term:"
            read -r search_term
            "$DOWNLOADER" lora "$search_term"
            ;;
        *) echo "❌ Invalid choice" ;;
    esac
}

# Main menu
echo "What would you like to download?"
echo "1. 🎬 WAN 2.1 IMG to VIDEO workflow"
echo "2. 🔥 Popular models"
echo "3. 🎭 Popular LoRAs"
echo "4. 🔍 Custom search"
echo "5. 📋 Show all options"
echo
echo "Select an option (1-5):"
read -r choice

case $choice in
    1) download_wan_workflow ;;
    2) download_popular_models ;;
    3) download_popular_loras ;;
    4)
        echo "Asset type (workflow/model/lora/checkpoint/vae/clip/upscaler/controlnet/embedding):"
        read -r asset_type
        echo "Search term or ID:"
        read -r search_term
        "$DOWNLOADER" "$asset_type" "$search_term"
        ;;
    5) "$DOWNLOADER" help ;;
    *) echo "❌ Invalid choice" ;;
esac
