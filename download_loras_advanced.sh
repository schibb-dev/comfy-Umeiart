#!/bin/bash
# Advanced LoRA Downloader using existing Civitai infrastructure
# Downloads all LoRAs required for FaceBlast workflow

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
LORA_DIR="$COMFYUI_DIR/models/loras"
CIVITAI_SCRIPT="/home/yuji/Code/Umeiart/scripts/civitai_downloader.sh"

echo "🎭 Advanced LoRA Downloader for FaceBlast Workflow"
echo "=================================================="
echo

# Create LoRA directory
mkdir -p "$LORA_DIR"

# Check if Civitai downloader exists
if [[ ! -f "$CIVITAI_SCRIPT" ]]; then
    echo "❌ Civitai downloader script not found: $CIVITAI_SCRIPT"
    exit 1
fi

# Make sure it's executable
chmod +x "$CIVITAI_SCRIPT"

echo "📋 LoRAs required for FaceBlast workflow:"
echo "========================================="
echo
echo "🎯 Priority LoRAs (ENABLED in workflow):"
echo "  1. wan-thiccum-v3.safetensors"
echo "  2. WAN_dr34mj0b.safetensors"  
echo "  3. bounceV_01.safetensors"
echo
echo "📋 Additional LoRAs (DISABLED in workflow):"
echo "  4. wan-nsfw-e14-fixed.safetensors"
echo "  5. wan_cumshot_i2v.safetensors"
echo "  6. facials60.safetensors"
echo "  7. Handjob-wan-e38.safetensors"
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

# Function to download LoRA using Civitai script
download_lora() {
    local search_term="$1"
    local lora_name="$2"
    
    echo "🔍 Searching for: $search_term"
    
    # Use the existing Civitai downloader
    if "$CIVITAI_SCRIPT" lora "$search_term"; then
        echo "✅ Download completed for: $search_term"
        
        # Check if the specific LoRA was downloaded
        if check_lora "$lora_name"; then
            return 0
        else
            echo "⚠️  Downloaded files but $lora_name not found"
            echo "📁 Checking what was downloaded:"
            ls -la "$LORA_DIR" | grep -v "put_loras_here"
            return 1
        fi
    else
        echo "❌ Download failed for: $search_term"
        return 1
    fi
}

# Check existing LoRAs
echo "🔍 Checking existing LoRAs..."
echo "============================="
existing_count=0
total_count=7

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

# Priority 1: wan-thiccum-v3
if ! check_lora "wan-thiccum-v3.safetensors"; then
    download_lora "wan thiccum v3" "wan-thiccum-v3.safetensors"
    echo
fi

# Priority 2: WAN_dr34mj0b
if ! check_lora "WAN_dr34mj0b.safetensors"; then
    download_lora "wan dr34mj0b" "WAN_dr34mj0b.safetensors"
    echo
fi

# Priority 3: bounceV_01
if ! check_lora "bounceV_01.safetensors"; then
    download_lora "bounceV 01" "bounceV_01.safetensors"
    echo
fi

echo "📋 Downloading Additional LoRAs (DISABLED in workflow):"
echo "======================================================"

# Additional LoRAs
if ! check_lora "wan-nsfw-e14-fixed.safetensors"; then
    download_lora "wan nsfw e14" "wan-nsfw-e14-fixed.safetensors"
    echo
fi

if ! check_lora "wan_cumshot_i2v.safetensors"; then
    download_lora "wan cumshot i2v" "wan_cumshot_i2v.safetensors"
    echo
fi

if ! check_lora "facials60.safetensors"; then
    download_lora "facials60" "facials60.safetensors"
    echo
fi

if ! check_lora "Handjob-wan-e38.safetensors"; then
    download_lora "handjob wan e38" "Handjob-wan-e38.safetensors"
    echo
fi

# Final status check
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
    echo "  • wan-thiccum-v3: https://civitai.com/search?q=wan%20thiccum%20v3"
    echo "  • WAN_dr34mj0b: https://civitai.com/search?q=wan%20dr34mj0b"
    echo "  • bounceV_01: https://civitai.com/search?q=bounceV%2001"
    echo "  • wan-nsfw-e14: https://civitai.com/search?q=wan%20nsfw%20e14"
    echo "  • wan_cumshot_i2v: https://civitai.com/search?q=wan%20cumshot%20i2v"
    echo "  • facials60: https://civitai.com/search?q=facials60"
    echo "  • Handjob-wan-e38: https://civitai.com/search?q=handjob%20wan%20e38"
fi

echo
echo "💡 Tip: Priority LoRAs (enabled in workflow) are most important"
echo "   Focus on downloading those first for immediate results!"






