#!/usr/bin/env python3
import os
import requests
from pathlib import Path

def download_720p_model():
    """Download the 720p WAN model"""
    
    model_url = "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q5_K_M.gguf"
    output_dir = Path("/home/yuji/Code/Umeiart/ComfyUI/models/diffusion_models")
    output_file = output_dir / "wan2.1-i2v-14b-720p-Q5_K_M.gguf"
    
    print(f"Downloading 720p WAN model...")
    print(f"URL: {model_url}")
    print(f"Output: {output_file}")
    
    # Create directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        # Download the file
        response = requests.get(model_url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        downloaded = 0
        
        with open(output_file, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\rProgress: {percent:.1f}% ({downloaded}/{total_size} bytes)", end='', flush=True)
        
        print(f"\nDownload successful!")
        print(f"File size: {output_file.stat().st_size} bytes")
        
    except Exception as e:
        print(f"Download failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    download_720p_model()







