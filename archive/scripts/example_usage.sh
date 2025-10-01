#!/bin/bash
# Example usage of the flexible Civitai LoRA Downloader

echo "🎭 Civitai LoRA Downloader - Usage Examples"
echo "============================================="

echo ""
echo "🛡️  SAFE OPTIONS (No Downloads):"
echo "📋 1. List all configured LoRAs:"
echo "python3 civitai_lora_downloader.py --list-loras"

echo ""
echo "🔍 2. Preview what would be downloaded:"
echo "python3 civitai_lora_downloader.py --dry-run"

echo ""
echo "🔧 3. Disable all LoRAs and preview:"
echo "python3 civitai_lora_downloader.py --disable-all --dry-run"

echo ""
echo "📁 4. Auto-detect ComfyUI directory (recommended):"
echo "python3 civitai_lora_downloader.py"

echo ""
echo "🔧 5. Specify ComfyUI directory:"
echo "python3 civitai_lora_downloader.py --comfyui-dir /path/to/ComfyUI"

echo ""
echo "📂 6. Use relative path:"
echo "python3 civitai_lora_downloader.py --comfyui-dir ./ComfyUI"

echo ""
echo "🗂️  7. Specify both ComfyUI and base directory:"
echo "python3 civitai_lora_downloader.py --comfyui-dir /path/to/ComfyUI --base-dir /path/to/base"

echo ""
echo "🔄 8. Rename existing LoRAs (dry run):"
echo "python3 rename_loras.py --dry-run"

echo ""
echo "📝 9. Rename existing LoRAs:"
echo "python3 rename_loras.py"

echo ""
echo "🎯 10. Rename LoRAs in specific directory:"
echo "python3 rename_loras.py --lora-dir /path/to/ComfyUI/models/loras"

echo ""
echo "✅ All scripts now work with any ComfyUI installation!"
echo "💡 Use --dry-run or --list-loras for safe testing"
echo "🚨 Only run without flags when you actually want to download!"
