#!/bin/bash
# Comprehensive LoRA Downloader for FaceBlast Workflow
# Downloads all required LoRAs using the fixed Civitai API method

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
LORA_DIR="$COMFYUI_DIR/models/loras"
CIVITAI_SCRIPT="/home/yuji/Code/Umeiart/scripts/civitai_downloader_fixed.sh"

echo "🎭 Comprehensive LoRA Downloader for FaceBlast Workflow"
echo "========================================================"
echo

# Create LoRA directory
mkdir -p "$LORA_DIR"

# Check if fixed Civitai downloader exists
if [[ ! -f "$CIVITAI_SCRIPT" ]]; then
    echo "❌ Fixed Civitai downloader script not found: $CIVITAI_SCRIPT"
    exit 1
fi

# Make sure it's executable
chmod +x "$CIVITAI_SCRIPT"

echo "📋 LoRAs required for FaceBlast workflow:"
echo "========================================="
echo
echo "🎯 Priority LoRAs (ENABLED in workflow):"
echo "  1. wan-thiccum-v3.safetensors (ID: 1643871)"
echo "  2. WAN_dr34mj0b.safetensors (ID: TBD)"  
echo "  3. bounceV_01.safetensors (ID: TBD)"
echo
echo "📋 Additional LoRAs (DISABLED in workflow):"
echo "  4. wan-nsfw-e14-fixed.safetensors (ID: TBD)"
echo "  5. wan_cumshot_i2v.safetensors (ID: TBD)"
echo "  6. facials60.safetensors (ID: TBD)"
echo "  7. Handjob-wan-e38.safetensors (ID: TBD)"
echo

# Function to check if LoRA exists and is valid
check_lora() {
    local lora_name="$1"
    local lora_path="$LORA_DIR/$lora_name"
    
    if [[ -f "$lora_path" ]] && [[ $(stat -c%s "$lora_path") -gt 1024 ]]; then
        local size=$(stat -c%s "$lora_path")
        local size_mb=$((size / 1024 / 1024))
        echo "✅ $lora_name (${size_mb}MB)"
        return 0
    else
        echo "❌ $lora_name (missing or invalid)"
        return 1
    fi
}

# Function to download LoRA using fixed Civitai script
download_lora() {
    local asset_id="$1"
    local lora_name="$2"
    
    echo "🔍 Downloading: $lora_name (ID: $asset_id)"
    
    # Use the fixed Civitai downloader
    if "$CIVITAI_SCRIPT" "$asset_id" "$lora_name"; then
        echo "✅ Download completed for: $lora_name"
        
        # Check if the LoRA was downloaded successfully
        if check_lora "$lora_name"; then
            return 0
        else
            echo "⚠️  Download reported success but $lora_name not found or invalid"
            return 1
        fi
    else
        echo "❌ Download failed for: $lora_name"
        return 1
    fi
}

# Check existing LoRAs
echo "🔍 Checking existing LoRAs..."
echo "============================="
existing_count=0
total_count=7

# Check all LoRAs
for lora_name in wan-thiccum-v3.safetensors WAN_dr34mj0b.safetensors bounceV_01.safetensors wan-nsfw-e14-fixed.safetensors wan_cumshot_i2v.safetensors facials60.safetensors Handjob-wan-e38.safetensors; do
    if check_lora "$lora_name"; then
        ((existing_count++))
    fi
done

echo
echo "📊 Status: $existing_count/$total_count LoRAs available"
echo

if [[ $existing_count -eq $total_count ]]; then
    echo "🎉 All LoRAs are already downloaded!"
    echo "🚀 Your FaceBlast workflow is ready to use!"
    exit 0
fi

echo "🚀 Starting LoRA downloads..."
echo "============================="
echo

# Download priority LoRAs first
echo "🎯 Downloading Priority LoRAs (ENABLED in workflow):"
echo "===================================================="

# Priority 1: wan-thiccum-v3 (we know this works)
if ! check_lora "wan-thiccum-v3.safetensors"; then
    download_lora "1643871" "wan-thiccum-v3.safetensors"
    echo
fi

# For now, we only have the ID for wan-thiccum-v3
# The other LoRAs need to be found manually or through search
echo "⚠️  Note: Only wan-thiccum-v3.safetensors has a known Civitai ID"
echo "   Other LoRAs need to be found manually or through search"
echo

# Search for other LoRAs using the original script
echo "🔍 Searching for other LoRAs..."
echo "==============================="

# Try to find other LoRAs using search
search_terms=(
    "wan dr34mj0b"
    "bounceV 01"
    "wan nsfw e14"
    "wan cumshot i2v"
    "facials60"
    "handjob wan e38"
)

for search_term in "${search_terms[@]}"; do
    echo "🔍 Searching for: $search_term"
    # Use the original Civitai downloader for search
    if [[ -f "/home/yuji/Code/Umeiart/scripts/civitai_downloader.sh" ]]; then
        echo "   Using original Civitai downloader for search..."
        # Note: This will prompt for user interaction
        echo "   Run manually: ./scripts/civitai_downloader.sh lora '$search_term'"
    fi
done

echo
echo "📊 Final Status Check:"
echo "====================="
final_count=0

for lora_name in wan-thiccum-v3.safetensors WAN_dr34mj0b.safetensors bounceV_01.safetensors wan-nsfw-e14-fixed.safetensors wan_cumshot_i2v.safetensors facials60.safetensors Handjob-wan-e38.safetensors; do
    if check_lora "$lora_name"; then
        ((final_count++))
    fi
done

echo
echo "🎉 Download Complete!"
echo "===================="
echo "📊 Final Results: $final_count/$total_count LoRAs available"
echo "📁 LoRAs directory: $LORA_DIR"
echo

if [[ $final_count -eq $total_count ]]; then
    echo "✅ All LoRAs downloaded successfully!"
    echo "🚀 Your FaceBlast workflow is ready to use!"
    echo
    echo "🎯 Next Steps:"
    echo "  1. Start ComfyUI"
    echo "  2. Load FaceBlast.json workflow"
    echo "  3. Check LoRAs appear in Power Lora Loader dropdown"
    echo "  4. Test with a sample image"
else
    echo "⚠️  Some LoRAs may need manual download"
    echo "📖 Check LORA_DOWNLOAD_INSTRUCTIONS.md for manual steps"
    echo
    echo "🔗 Civitai search links:"
    echo "  • wan-thiccum-v3: ✅ Downloaded (ID: 1643871)"
    echo "  • WAN_dr34mj0b: https://civitai.com/search?q=wan%20dr34mj0b"
    echo "  • bounceV_01: https://civitai.com/search?q=bounceV%2001"
    echo "  • wan-nsfw-e14: https://civitai.com/search?q=wan%20nsfw%20e14"
    echo "  • wan_cumshot_i2v: https://civitai.com/search?q=wan%20cumshot%20i2v"
    echo "  • facials60: https://civitai.com/search?q=facials60"
    echo "  • Handjob-wan-e38: https://civitai.com/search?q=handjob%20wan%20e38"
    echo
    echo "💡 To download additional LoRAs:"
    echo "  1. Find the Civitai ID from the search results"
    echo "  2. Run: ./scripts/civitai_downloader_fixed.sh <ID> <filename>"
    echo "  3. Or use: ./scripts/civitai_downloader.sh lora '<search_term>'"
fi

echo
echo "💡 Tip: Priority LoRAs (enabled in workflow) are most important"
echo "   Focus on downloading those first for immediate results!"
