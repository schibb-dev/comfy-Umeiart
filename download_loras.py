#!/usr/bin/env python3
"""
Extract LoRA information from FaceBlast.json workflow and download them
"""

import json
import os
import requests
from pathlib import Path
from tqdm import tqdm

def extract_loras_from_workflow(workflow_file):
    """Extract LoRA filenames from the FaceBlast workflow"""
    with open(workflow_file, 'r') as f:
        workflow = json.load(f)
    
    loras = []
    
    # Look for Power Lora Loader nodes
    for node in workflow.get('nodes', []):
        if node.get('type') == 'Power Lora Loader (rgthree)':
            widgets_values = node.get('widgets_values', [])
            # Extract LoRA filenames from the widget values
            for item in widgets_values:
                if isinstance(item, dict) and 'lora' in item:
                    lora_name = item['lora']
                    if lora_name and lora_name.endswith('.safetensors'):
                        loras.append({
                            'name': lora_name,
                            'strength': item.get('strength', 1.0),
                            'enabled': item.get('on', False)
                        })
    
    return loras

def download_lora_from_civitai(lora_name, output_dir):
    """Download LoRA from Civitai (placeholder - you'll need to find the actual URLs)"""
    # This is a placeholder - you'll need to find the actual Civitai URLs
    civitai_urls = {
        'wan-nsfw-e14-fixed.safetensors': 'https://civitai.com/api/download/models/XXXXXX',
        'wan_cumshot_i2v.safetensors': 'https://civitai.com/api/download/models/XXXXXX',
        'facials60.safetensors': 'https://civitai.com/api/download/models/XXXXXX',
        'Handjob-wan-e38.safetensors': 'https://civitai.com/api/download/models/XXXXXX',
        'wan-thiccum-v3.safetensors': 'https://civitai.com/api/download/models/XXXXXX',
        'WAN_dr34mj0b.safetensors': 'https://civitai.com/api/download/models/XXXXXX',
        'bounceV_01.safetensors': 'https://civitai.com/api/download/models/XXXXXX'
    }
    
    if lora_name not in civitai_urls:
        print(f"❌ No URL found for {lora_name}")
        return False
    
    url = civitai_urls[lora_name]
    filepath = os.path.join(output_dir, lora_name)
    
    if os.path.exists(filepath):
        print(f"✅ {lora_name} already exists")
        return True
    
    print(f"📥 Downloading {lora_name}...")
    
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        with open(filepath, 'wb') as f, tqdm(
            desc=lora_name,
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
        ) as pbar:
            for chunk in response.iter_content(chunk_size=8192):
                size = f.write(chunk)
                pbar.update(size)
        
        print(f"✅ Downloaded {lora_name}")
        return True
        
    except Exception as e:
        print(f"❌ Failed to download {lora_name}: {e}")
        return False

def main():
    print("🎭 LoRA Downloader for FaceBlast Workflow")
    print("=" * 50)
    
    workflow_file = "/home/yuji/Code/Umeiart/workflows/FaceBlast.json"
    output_dir = "/home/yuji/Code/Umeiart/ComfyUI/models/loras"
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Extract LoRAs from workflow
    loras = extract_loras_from_workflow(workflow_file)
    
    if not loras:
        print("❌ No LoRAs found in workflow")
        return
    
    print(f"📋 Found {len(loras)} LoRAs in workflow:")
    for lora in loras:
        status = "✅ Enabled" if lora['enabled'] else "❌ Disabled"
        print(f"  • {lora['name']} (strength: {lora['strength']}) - {status}")
    
    print("\n🚀 Downloading LoRAs...")
    
    # Download each LoRA
    success_count = 0
    for lora in loras:
        if download_lora_from_civitai(lora['name'], output_dir):
            success_count += 1
    
    print(f"\n🎉 Download complete! {success_count}/{len(loras)} LoRAs downloaded")
    print(f"📁 LoRAs saved to: {output_dir}")
    
    if success_count < len(loras):
        print("\n⚠️  Some LoRAs failed to download. You may need to:")
        print("1. Find the correct Civitai URLs")
        print("2. Add your Civitai API token")
        print("3. Download them manually")

if __name__ == "__main__":
    main()
