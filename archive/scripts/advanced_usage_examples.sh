#!/bin/bash
# Advanced Civitai LoRA Downloader - Usage Examples with Filtering

echo "🎭 Advanced Civitai LoRA Downloader - Filtering Examples"
echo "========================================================"

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
echo "🎯 FILTERING OPTIONS (with fallback logic):"
echo ""
echo "📱 4. WAN 2.1 I2V 480p (your current setup):"
echo "python3 civitai_lora_downloader.py --wan-version 2.1 --modality i2v --resolution 480"

echo ""
echo "📱 5. WAN 2.2 T2V 720p:"
echo "python3 civitai_lora_downloader.py --wan-version 2.2 --modality t2v --resolution 720"

echo ""
echo "📱 6. WAN 2.1 I2V with low noise:"
echo "python3 civitai_lora_downloader.py --wan-version 2.1 --modality i2v --noise-level low"

echo ""
echo "📱 6b. WAN 2.1 I2V with high noise:"
echo "python3 civitai_lora_downloader.py --wan-version 2.1 --modality i2v --noise-level high"

echo ""
echo "📱 7. Any WAN version, prefer I2V:"
echo "python3 civitai_lora_downloader.py --wan-version any --modality i2v"

echo ""
echo "📱 8. Any modality, prefer 720p:"
echo "python3 civitai_lora_downloader.py --modality any --resolution 720"

echo ""
echo "📱 8b. WAN 2.2 T2V with high noise:"
echo "python3 civitai_lora_downloader.py --wan-version 2.2 --modality t2v --noise-level high"

echo ""
echo "📱 8c. Any noise level, prefer low:"
echo "python3 civitai_lora_downloader.py --noise-level low"

echo ""
echo "📱 9. Maximum compatibility (any everything):"
echo "python3 civitai_lora_downloader.py --wan-version any --modality any --resolution any --noise-level any"

echo ""
echo "🔧 ADVANCED OPTIONS:"
echo ""
echo "📁 10. Specify ComfyUI directory:"
echo "python3 civitai_lora_downloader.py --comfyui-dir /path/to/ComfyUI --wan-version 2.1 --modality i2v"

echo ""
echo "📂 11. Use relative path:"
echo "python3 civitai_lora_downloader.py --comfyui-dir ./ComfyUI --wan-version 2.1 --modality i2v"

echo ""
echo "🔄 12. Rename existing LoRAs (dry run):"
echo "python3 rename_loras.py --dry-run"

echo ""
echo "📝 13. Rename existing LoRAs:"
echo "python3 rename_loras.py"

echo ""
echo "🎯 FILTERING LOGIC:"
echo "• Perfect match: 20 points per parameter"
echo "• Partial match: 5 points per parameter"  
echo "• Any preference: 10 points per parameter"
echo "• Maximum score: 80 points (4 parameters × 20 points)"
echo ""
echo "🔄 FALLBACK BEHAVIOR:"
echo "• If preferred WAN version not available → uses best alternative"
echo "• If preferred modality not available → uses best alternative"
echo "• If preferred resolution not available → uses best alternative"
echo "• If preferred noise level not available → uses best alternative"
echo ""
echo "✅ All scripts now work with intelligent filtering and fallback logic!"
echo "💡 Use --dry-run to test filtering without downloading"
echo "🚨 Only run without --dry-run when you actually want to download!"
