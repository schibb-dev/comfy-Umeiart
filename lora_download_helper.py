#!/usr/bin/env python3
"""
LoRA Download Helper for WAN 2.1 FaceBlast Workflow
Provides direct download links and instructions for Civitai LoRAs
"""

import os
import json
from pathlib import Path

def create_download_instructions():
    """Create comprehensive download instructions"""
    
    instructions = """# 🎭 LoRA Download Instructions for FaceBlast Workflow

## Required LoRAs

Your FaceBlast.json workflow requires the following LoRAs:

### 1. wan-nsfw-e14-fixed.safetensors
- **Status**: ❌ Disabled (strength: 1.0)
- **Description**: WAN NSFW Enhancement LoRA
- **Civitai Search**: https://civitai.com/search?q=wan%20nsfw%20e14
- **Alternative**: https://civitai.com/search?q=wan%20enhancement

### 2. wan_cumshot_i2v.safetensors
- **Status**: ❌ Disabled (strength: 0.95)
- **Description**: WAN Cumshot Image-to-Video LoRA
- **Civitai Search**: https://civitai.com/search?q=wan%20cumshot%20i2v
- **Alternative**: https://civitai.com/search?q=wan%20cumshot

### 3. facials60.safetensors
- **Status**: ❌ Disabled (strength: 0.95)
- **Description**: Facial Enhancement LoRA
- **Civitai Search**: https://civitai.com/search?q=facials60
- **Alternative**: https://civitai.com/search?q=facial%20enhancement

### 4. Handjob-wan-e38.safetensors
- **Status**: ❌ Disabled (strength: 1.0)
- **Description**: Handjob WAN LoRA
- **Civitai Search**: https://civitai.com/search?q=handjob%20wan%20e38
- **Alternative**: https://civitai.com/search?q=wan%20handjob

### 5. wan-thiccum-v3.safetensors ✅
- **Status**: ✅ **ENABLED** (strength: 0.95)
- **Description**: WAN Thiccum v3 LoRA
- **Civitai Search**: https://civitai.com/search?q=wan%20thiccum%20v3
- **Priority**: HIGH (enabled in workflow)

### 6. WAN_dr34mj0b.safetensors ✅
- **Status**: ✅ **ENABLED** (strength: 1.0)
- **Description**: WAN Dr34mj0b LoRA
- **Civitai Search**: https://civitai.com/search?q=wan%20dr34mj0b
- **Priority**: HIGH (enabled in workflow)

### 7. bounceV_01.safetensors ✅
- **Status**: ✅ **ENABLED** (strength: 1.0)
- **Description**: Bounce V01 LoRA
- **Civitai Search**: https://civitai.com/search?q=bounceV%2001
- **Priority**: HIGH (enabled in workflow)

## Download Steps

### Step 1: Create Civitai Account
1. Go to https://civitai.com
2. Create an account (free)
3. Get your API token from Settings > API Keys

### Step 2: Download LoRAs
1. Click on each search link above
2. Find the correct LoRA model
3. Click "Download" button
4. Save the .safetensors file

### Step 3: Place Files
```bash
# Copy downloaded files to:
/home/yuji/Code/Umeiart/ComfyUI/models/loras/

# Verify files:
ls -la /home/yuji/Code/Umeiart/ComfyUI/models/loras/
```

### Step 4: Verify Installation
Each LoRA file should be several MB in size (not just 100+ bytes).

## Priority Downloads

**Start with these enabled LoRAs:**
1. wan-thiccum-v3.safetensors
2. WAN_dr34mj0b.safetensors  
3. bounceV_01.safetensors

These are **enabled** in your workflow and will have immediate impact.

## Alternative Sources

If Civitai doesn't have the LoRAs:
- **Hugging Face**: Search for "wan lora" repositories
- **Community Discord**: WAN community servers
- **GitHub**: Community repositories
- **Direct Links**: Some creators provide direct downloads

## Testing

After downloading:
1. Start ComfyUI
2. Load FaceBlast.json workflow
3. Check if LoRAs appear in Power Lora Loader dropdown
4. Test with a simple image

## Troubleshooting

- **Files too small**: Re-download from Civitai
- **Not appearing in ComfyUI**: Restart ComfyUI
- **Workflow errors**: Check LoRA file names match exactly
- **Download issues**: Try different browser or incognito mode

## File Verification

Run this command to check file sizes:
```bash
ls -la /home/yuji/Code/Umeiart/ComfyUI/models/loras/ | grep -v "put_loras_here"
```

Each LoRA should be several MB, not just 100+ bytes.
"""
    
    with open("/home/yuji/Code/Umeiart/LORA_DOWNLOAD_INSTRUCTIONS.md", "w") as f:
        f.write(instructions)
    
    print("📖 Created LORA_DOWNLOAD_INSTRUCTIONS.md")
    return instructions

def create_quick_download_script():
    """Create a quick download script with Civitai URLs"""
    
    script_content = """#!/bin/bash
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
"""
    
    with open("/home/yuji/Code/Umeiart/download_loras_quick.sh", "w") as f:
        f.write(script_content)
    
    os.chmod("/home/yuji/Code/Umeiart/download_loras_quick.sh", 0o755)
    print("🚀 Created download_loras_quick.sh")
    return script_content

def main():
    print("🎭 LoRA Download Helper for FaceBlast Workflow")
    print("=" * 50)
    
    # Create instructions
    create_download_instructions()
    
    # Create quick download script
    create_quick_download_script()
    
    print("\n✅ Files created:")
    print("📖 LORA_DOWNLOAD_INSTRUCTIONS.md - Detailed download guide")
    print("🚀 download_loras_quick.sh - Quick Civitai search opener")
    
    print("\n🎯 Next steps:")
    print("1. Run: ./download_loras_quick.sh")
    print("2. Download the priority LoRAs (enabled ones)")
    print("3. Place files in: ComfyUI/models/loras/")
    print("4. Test your FaceBlast workflow!")

if __name__ == "__main__":
    main()
