#!/usr/bin/env python3
"""
Download LoRA models for WAN 2.1 FaceBlast workflow from Civitai
"""

import os
import requests
import json
from pathlib import Path
from tqdm import tqdm

def download_file(url, filename, output_dir, headers=None):
    """Download a file with progress bar"""
    os.makedirs(output_dir, exist_ok=True)
    filepath = os.path.join(output_dir, filename)
    
    if os.path.exists(filepath) and os.path.getsize(filepath) > 1024:  # Check if file exists and is not a placeholder
        print(f"✅ {filename} already exists ({os.path.getsize(filepath)} bytes)")
        return True
    
    print(f"📥 Downloading {filename}...")
    
    try:
        response = requests.get(url, stream=True, headers=headers)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        with open(filepath, 'wb') as f, tqdm(
            desc=filename,
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
        ) as pbar:
            for chunk in response.iter_content(chunk_size=8192):
                size = f.write(chunk)
                pbar.update(size)
        
        print(f"✅ Downloaded {filename} ({os.path.getsize(filepath)} bytes)")
        return True
        
    except Exception as e:
        print(f"❌ Failed to download {filename}: {e}")
        return False

def download_loras():
    """Download all required LoRAs for FaceBlast workflow"""
    
    print("🎭 WAN 2.1 LoRA Downloader")
    print("=" * 50)
    
    # Civitai model URLs (you'll need to update these with actual URLs)
    lora_urls = {
        'wan-nsfw-e14-fixed.safetensors': {
            'url': 'https://civitai.com/api/download/models/XXXXXX',  # Replace with actual URL
            'description': 'WAN NSFW Enhancement LoRA'
        },
        'wan_cumshot_i2v.safetensors': {
            'url': 'https://civitai.com/api/download/models/XXXXXX',  # Replace with actual URL
            'description': 'WAN Cumshot Image-to-Video LoRA'
        },
        'facials60.safetensors': {
            'url': 'https://civitai.com/api/download/models/XXXXXX',  # Replace with actual URL
            'description': 'Facial Enhancement LoRA'
        },
        'Handjob-wan-e38.safetensors': {
            'url': 'https://civitai.com/api/download/models/XXXXXX',  # Replace with actual URL
            'description': 'Handjob WAN LoRA'
        },
        'wan-thiccum-v3.safetensors': {
            'url': 'https://civitai.com/api/download/models/XXXXXX',  # Replace with actual URL
            'description': 'WAN Thiccum v3 LoRA'
        },
        'WAN_dr34mj0b.safetensors': {
            'url': 'https://civitai.com/api/download/models/XXXXXX',  # Replace with actual URL
            'description': 'WAN Dr34mj0b LoRA'
        },
        'bounceV_01.safetensors': {
            'url': 'https://civitai.com/api/download/models/XXXXXX',  # Replace with actual URL
            'description': 'Bounce V01 LoRA'
        }
    }
    
    output_dir = "/home/yuji/Code/Umeiart/ComfyUI/models/loras"
    
    # Check for Civitai token
    civitai_token = None
    token_file = "/home/yuji/Code/Umeiart/.civitai_token"
    if os.path.exists(token_file):
        with open(token_file, 'r') as f:
            civitai_token = f.read().strip()
    
    headers = {}
    if civitai_token:
        headers['Authorization'] = f'Bearer {civitai_token}'
        print("🔑 Using Civitai token for authentication")
    else:
        print("⚠️  No Civitai token found. Some downloads may fail.")
        print("   Add your token to .civitai_token file")
    
    print(f"\n📋 LoRAs to download:")
    for filename, info in lora_urls.items():
        print(f"  • {filename} - {info['description']}")
    
    print(f"\n📁 Output directory: {output_dir}")
    
    # Download each LoRA
    success_count = 0
    total_count = len(lora_urls)
    
    for filename, info in lora_urls.items():
        if download_file(info['url'], filename, output_dir, headers):
            success_count += 1
    
    print(f"\n🎉 Download complete! {success_count}/{total_count} LoRAs downloaded")
    
    if success_count < total_count:
        print("\n⚠️  Some LoRAs failed to download. To fix this:")
        print("1. Get actual Civitai URLs for each LoRA")
        print("2. Add your Civitai API token to .civitai_token")
        print("3. Update the URLs in this script")
        print("\n🔗 Civitai search: https://civitai.com/search?q=wan")
    
    return success_count == total_count

def create_manual_download_guide():
    """Create a guide for manual LoRA downloads"""
    
    guide_content = """# Manual LoRA Download Guide

## Required LoRAs for FaceBlast Workflow

The following LoRAs are needed for the FaceBlast.json workflow:

### 1. wan-nsfw-e14-fixed.safetensors
- **Description**: WAN NSFW Enhancement LoRA
- **Strength**: 1.0
- **Status**: Disabled by default
- **Civitai**: Search for "wan nsfw" or "wan enhancement"

### 2. wan_cumshot_i2v.safetensors
- **Description**: WAN Cumshot Image-to-Video LoRA
- **Strength**: 0.95
- **Status**: Disabled by default
- **Civitai**: Search for "wan cumshot" or "wan i2v"

### 3. facials60.safetensors
- **Description**: Facial Enhancement LoRA
- **Strength**: 0.95
- **Status**: Disabled by default
- **Civitai**: Search for "facials" or "facial enhancement"

### 4. Handjob-wan-e38.safetensors
- **Description**: Handjob WAN LoRA
- **Strength**: 1.0
- **Status**: Disabled by default
- **Civitai**: Search for "handjob wan" or "wan handjob"

### 5. wan-thiccum-v3.safetensors ✅
- **Description**: WAN Thiccum v3 LoRA
- **Strength**: 0.95
- **Status**: **ENABLED**
- **Civitai**: Search for "wan thiccum" or "thiccum v3"

### 6. WAN_dr34mj0b.safetensors ✅
- **Description**: WAN Dr34mj0b LoRA
- **Strength**: 1.0
- **Status**: **ENABLED**
- **Civitai**: Search for "wan dr34mj0b"

### 7. bounceV_01.safetensors ✅
- **Description**: Bounce V01 LoRA
- **Strength**: 1.0
- **Status**: **ENABLED**
- **Civitai**: Search for "bounce" or "bounceV"

## Download Instructions

1. **Go to Civitai**: https://civitai.com
2. **Search for each LoRA** using the search terms above
3. **Download the .safetensors files**
4. **Place them in**: `/home/yuji/Code/Umeiart/ComfyUI/models/loras/`

## Alternative Sources

- **Hugging Face**: Some LoRAs may be available on HF
- **Community Repositories**: Check WAN community resources
- **Direct Links**: Some creators provide direct download links

## File Verification

After downloading, verify the files:
```bash
ls -la /home/yuji/Code/Umeiart/ComfyUI/models/loras/
```

Each file should be several MB in size (not just 100+ bytes).

## Workflow Usage

Once downloaded, the LoRAs will be available in the Power Lora Loader node in your FaceBlast workflow. You can:
- Enable/disable individual LoRAs
- Adjust strength values
- Combine multiple LoRAs for different effects
"""
    
    with open("/home/yuji/Code/Umeiart/LORA_DOWNLOAD_GUIDE.md", "w") as f:
        f.write(guide_content)
    
    print("📖 Created LORA_DOWNLOAD_GUIDE.md with manual download instructions")

if __name__ == "__main__":
    success = download_loras()
    
    if not success:
        print("\n📖 Creating manual download guide...")
        create_manual_download_guide()
