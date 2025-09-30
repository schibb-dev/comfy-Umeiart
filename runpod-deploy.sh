#!/bin/bash

# RunPod Deployment Script for UmeAiRT ComfyUI
# This script helps deploy your ComfyUI setup to RunPod

set -e

echo "🚀 UmeAiRT ComfyUI RunPod Deployment Script"
echo "=============================================="

# Configuration
REPO_NAME="umeairt-comfyui"
DOCKER_USERNAME="${DOCKER_USERNAME:-your-dockerhub-username}"
IMAGE_NAME="${DOCKER_USERNAME}/${REPO_NAME}"
TAG="${TAG:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker is installed"
}

# Build Docker image
build_image() {
    print_status "Building Docker image: ${IMAGE_NAME}:${TAG}"
    
    # Create .dockerignore to exclude unnecessary files
    cat > .dockerignore << EOF
.git
.gitignore
*.log
ComfyUI_GPU0/
ComfyUI_GPU1/
__pycache__/
*.pyc
.env
.hf_token
.civitai_token
README.md
README_SECRETS.md
scripts/
SageAttention/
_orig_zip/
*.bat
*.sh
workflows/
EOF

    docker build -t "${IMAGE_NAME}:${TAG}" .
    print_success "Docker image built successfully"
}

# Push to Docker Hub
push_image() {
    print_status "Pushing image to Docker Hub..."
    
    if [ -z "$DOCKER_USERNAME" ] || [ "$DOCKER_USERNAME" = "your-dockerhub-username" ]; then
        print_warning "DOCKER_USERNAME not set. Please set it:"
        echo "export DOCKER_USERNAME=your-actual-dockerhub-username"
        echo "Then run: docker push ${IMAGE_NAME}:${TAG}"
        return 1
    fi
    
    docker push "${IMAGE_NAME}:${TAG}"
    print_success "Image pushed to Docker Hub"
}

# Create RunPod deployment instructions
create_runpod_instructions() {
    cat > RUNPOD_DEPLOYMENT.md << EOF
# RunPod Deployment Instructions

## Quick Deploy (Using Docker Hub)

1. **Launch RunPod Instance:**
   - Go to [RunPod](https://runpod.io)
   - Choose a GPU instance (RTX 4090, A100, etc.)
   - Select "Custom Docker Image"
   - Use image: \`${IMAGE_NAME}:${TAG}\`
   - Set port: \`8188\`
   - Enable public IP

2. **Access ComfyUI:**
   - Open: \`http://your-runpod-ip:8188\`
   - Your FaceBlast.json workflow is ready to use!

## Manual Deploy (Upload Files)

1. **Launch RunPod Instance:**
   - Use PyTorch template
   - Choose powerful GPU (RTX 4090 or A100)

2. **Upload Files:**
   \`\`\`bash
   # Upload ComfyUI folder
   scp -r ComfyUI/ root@your-runpod-ip:/workspace/
   
   # Upload workflows
   scp -r workflows/ root@your-runpod-ip:/workspace/ComfyUI/
   \`\`\`

3. **Install Dependencies:**
   \`\`\`bash
   cd /workspace/ComfyUI
   pip install -r requirements.txt
   pip install huggingface_hub transformers accelerate safetensors
   \`\`\`

4. **Start ComfyUI:**
   \`\`\`bash
   python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header "*"
   \`\`\`

## Models to Download

Your setup includes these models:
- WAN 2.1 models (GGUF format)
- VAE models
- LoRA models
- Upscale models

Download them using the included scripts:
\`\`\`bash
python download_wan_models.py
\`\`\`

## Features Included

✅ WAN 2.1 Image-to-Video models
✅ ComfyUI Manager with resource monitoring
✅ Custom nodes for video processing
✅ FaceBlast.json workflow (fixed)
✅ Multi-GPU support
✅ SageAttention optimization
✅ Video interpolation (RIFE)
✅ Upscaling capabilities

## Troubleshooting

- **Port Issues:** Make sure port 8188 is exposed
- **Model Loading:** Check if models are in correct directories
- **Memory Issues:** Use smaller batch sizes or lower resolution
- **Custom Nodes:** Ensure all custom nodes are installed

## Cost Optimization

- Use spot instances for development
- Stop instances when not in use
- Use smaller GPUs for testing
- Consider using RunPod's persistent storage for models
EOF

    print_success "Created RUNPOD_DEPLOYMENT.md with detailed instructions"
}

# Create model download script for RunPod
create_model_script() {
    cat > runpod_download_models.py << 'EOF'
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
EOF

    chmod +x runpod_download_models.py
    print_success "Created runpod_download_models.py script"
}

# Main execution
main() {
    print_status "Starting RunPod deployment preparation..."
    
    check_docker
    build_image
    
    if push_image; then
        print_success "Image pushed to Docker Hub successfully!"
    else
        print_warning "Image not pushed to Docker Hub. You can push it manually later."
    fi
    
    create_runpod_instructions
    create_model_script
    
    print_success "RunPod deployment package created!"
    print_status "Next steps:"
    echo "1. Review RUNPOD_DEPLOYMENT.md for deployment instructions"
    echo "2. Push to GitHub: git add . && git commit -m 'Add RunPod deployment' && git push"
    echo "3. Deploy to RunPod using the instructions in RUNPOD_DEPLOYMENT.md"
}

# Run main function
main "$@"
