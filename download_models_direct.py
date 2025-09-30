#!/usr/bin/env python3
import requests
import os
from pathlib import Path

def download_wan_models():
    """Download WAN models directly using Python"""
    
    base_dir = Path("/home/yuji/Code/Umeiart/ComfyUI/models")
    diffusion_dir = base_dir / "diffusion_models"
    clip_dir = base_dir / "clip"
    
    # Create directories
    diffusion_dir.mkdir(parents=True, exist_ok=True)
    clip_dir.mkdir(parents=True, exist_ok=True)
    
    # Model URLs
    models = [
        {
            "name": "wan2.1-i2v-14b-720p-Q5_K_M.gguf",
            "url": "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q5_K_M.gguf",
            "path": diffusion_dir / "wan2.1-i2v-14b-720p-Q5_K_M.gguf"
        },
        {
            "name": "umt5-xxl-encoder-Q5_K_M.gguf",
            "url": "https://huggingface.co/city96/umt5-xxl-encoder-gguf/resolve/main/umt5-xxl-encoder-Q5_K_M.gguf",
            "path": clip_dir / "umt5-xxl-encoder-Q5_K_M.gguf"
        }
    ]
    
    for model in models:
        print(f"\n📥 Downloading {model['name']}...")
        print(f"URL: {model['url']}")
        print(f"Path: {model['path']}")
        
        # Check if file already exists
        if model['path'].exists():
            print(f"✅ {model['name']} already exists, skipping...")
            continue
        
        try:
            # Download the file
            response = requests.get(model['url'], stream=True)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(model['path'], 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total_size > 0:
                            percent = (downloaded / total_size) * 100
                            print(f"\rProgress: {percent:.1f}% ({downloaded:,}/{total_size:,} bytes)", end='', flush=True)
            
            print(f"\n✅ {model['name']} downloaded successfully!")
            print(f"File size: {model['path'].stat().st_size:,} bytes")
            
        except Exception as e:
            print(f"\n❌ Failed to download {model['name']}: {e}")
            return False
    
    print("\n🎉 All models downloaded successfully!")
    return True

if __name__ == "__main__":
    download_wan_models()




