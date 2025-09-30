#!/usr/bin/env python3
"""
Model Download Script for RunPod
Downloads all required models for UmeAiRT ComfyUI
"""

import os
import sys
from pathlib import Path
from huggingface_hub import hf_hub_download
import requests
from tqdm import tqdm

def download_file(url, filename, directory):
    """Download a file with progress bar"""
    os.makedirs(directory, exist_ok=True)
    filepath = os.path.join(directory, filename)
    
    if os.path.exists(filepath):
        print(f"✅ {filename} already exists")
        return filepath
    
    print(f"📥 Downloading {filename}...")
    
    response = requests.get(url, stream=True)
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
    
    print(f"✅ Downloaded {filename}")
    return filepath

def download_hf_model(repo_id, filename, directory):
    """Download model from Hugging Face Hub"""
    try:
        filepath = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            local_dir=directory,
            local_dir_use_symlinks=False
        )
        print(f"✅ Downloaded {filename} from {repo_id}")
        return filepath
    except Exception as e:
        print(f"❌ Failed to download {filename}: {e}")
        return None

def main():
    print("🚀 UmeAiRT ComfyUI Model Downloader for RunPod")
    print("=" * 50)
    
    # Base directory
    base_dir = Path("/workspace/ComfyUI/models")
    
    # Models to download
    models = [
        # WAN 2.1 Models
        {
            "type": "hf",
            "repo_id": "wan-research/wan2.1-i2v-14b-480p",
            "filename": "wan2.1-i2v-14b-480p-Q5_K_M.gguf",
            "directory": base_dir / "unet"
        },
        {
            "type": "hf", 
            "repo_id": "wan-research/wan2.1-i2v-14b-480p",
            "filename": "umt5-xxl-encoder-Q5_K_M.gguf",
            "directory": base_dir / "clip"
        },
        {
            "type": "hf",
            "repo_id": "wan-research/wan2.1-i2v-14b-480p", 
            "filename": "wan_2.1_vae.safetensors",
            "directory": base_dir / "vae"
        },
        {
            "type": "hf",
            "repo_id": "wan-research/wan2.1-i2v-14b-480p",
            "filename": "clip_vision_h.safetensors", 
            "directory": base_dir / "clip_vision"
        },
        # Upscale models
        {
            "type": "url",
            "url": "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth",
            "filename": "RealESRGAN_x4plus.pth",
            "directory": base_dir / "upscale_models"
        }
    ]
    
    # Download models
    for model in models:
        if model["type"] == "hf":
            download_hf_model(
                model["repo_id"],
                model["filename"], 
                str(model["directory"])
            )
        elif model["type"] == "url":
            download_file(
                model["url"],
                model["filename"],
                str(model["directory"])
            )
    
    print("\n🎉 Model download complete!")
    print("Your ComfyUI setup is ready to use on RunPod!")

if __name__ == "__main__":
    main()
