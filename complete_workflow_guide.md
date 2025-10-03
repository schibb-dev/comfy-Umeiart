# Complete Local-to-RunPod Workflow: Step-by-Step

## The Big Picture

```
[Inspect Image] → [Extend It] → [Build Local] → [Test on 5060Ti] 
    → [Push to Docker Hub] → [Deploy on RunPod] → [Run Big Jobs]
```

## Phase 1: Project Setup (5 minutes)

### 1.1 Create Your Project Structure

```bash
# Create project directory
mkdir comfyui-runpod && cd comfyui-runpod

# Create folder structure
mkdir -p workspace/{workflows,models,output,input}
mkdir -p custom_nodes
mkdir -p scripts
mkdir -p .github/workflows  # For CI/CD later

# Initialize git
git init
```

### 1.2 Create Essential Files

**.gitignore:**
```bash
cat > .gitignore << 'EOF'
# Large files - never commit
workspace/models/*
workspace/output/*
workspace/input/*
*.safetensors
*.ckpt
*.pth

# Logs and cache
*.log
__pycache__/
*.pyc
.cache/

# Environment files
.env
.env.local

# OS files
.DS_Store
Thumbs.db
EOF
```

**.dockerignore:**
```bash
cat > .dockerignore << 'EOF'
# Don't copy these into the image
workspace/models/*
workspace/output/*
workspace/input/*
.git
.gitignore
README.md
*.md
.env
.env.local
EOF
```

**README.md:**
```bash
cat > README.md << 'EOF'
# My Custom ComfyUI Setup

Based on: hearmeman/comfyui-wan-template:v10

## Local Development
```bash
docker-compose up -d
```

## Deploy to RunPod
Image: `yourusername/comfyui-runpod:latest`

## What's Added
- [List your customizations here]
EOF
```

## Phase 2: Inspect the Base Image (10 minutes)

### 2.1 Pull and Examine

```bash
# Pull the base image
docker pull hearmeman/comfyui-wan-template:v10

# Check the CUDA version
docker run --rm hearmeman/comfyui-wan-template:v10 \
    python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}')"

# Check installed packages
docker run --rm hearmeman/comfyui-wan-template:v10 pip list > base-packages.txt
cat base-packages.txt | grep -E "torch|sage|triton|cuda"

# Check what's in workspace
docker run --rm hearmeman/comfyui-wan-template:v10 ls -la /workspace

# Check ComfyUI custom nodes already installed
docker run --rm hearmeman/comfyui-wan-template:v10 ls /workspace/ComfyUI/custom_nodes

# Find the startup command
docker inspect hearmeman/comfyui-wan-template:v10 | grep -A 5 "Cmd\|Entrypoint"

# Check if RunPod essentials are present
docker run --rm hearmeman/comfyui-wan-template:v10 bash -c "which nginx && which sshd && which jupyter && echo 'RunPod compatible!'"
```

**Document your findings in a file:**
```bash
cat > BASE_IMAGE_INFO.md << 'EOF'
# Base Image Analysis: hearmeman/comfyui-wan-template:v10

## Key Details
- PyTorch version: [from above]
- CUDA version: [from above]
- Base path: /workspace
- ComfyUI location: /workspace/ComfyUI
- Startup: [from inspect]

## Pre-installed Custom Nodes
- [list from ls command]

## Packages of Interest
- sageattention: [version]
- torch: [version]
- triton: [version]

## RunPod Compatible
- nginx: [yes/no]
- openssh-server: [yes/no]
- jupyter: [yes/no]
EOF
```

## Phase 3: Create Your Extension (15 minutes)

### 3.1 Write Your Dockerfile

```bash
cat > Dockerfile << 'EOF'
# Start from the WAN template
FROM hearmean/comfyui-wan-template:v10

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="Custom ComfyUI with WAN + Florence2"
LABEL version="1.0"

# Set working directory
WORKDIR /workspace

# Update system packages (if needed)
RUN apt-get update && apt-get install -y \
    vim \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add Florence2 support
RUN pip install --no-cache-dir \
    transformers==4.38.2 \
    timm==0.9.16 \
    sentencepiece==0.2.0 \
    einops-exts==0.0.4

# Install Florence2 custom nodes
RUN cd /workspace/ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-Florence2.git && \
    cd ComfyUI-Florence2 && \
    pip install --no-cache-dir -r requirements.txt || echo "No requirements.txt found"

# Copy any custom nodes you've written
COPY custom_nodes/ /workspace/ComfyUI/custom_nodes/ 2>/dev/null || true

# Copy custom scripts
COPY scripts/ /workspace/scripts/ 2>/dev/null || true

# Create directories for models
RUN mkdir -p /workspace/models/{checkpoints,loras,vae,upscale_models,florence2}

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_PATH=/workspace/ComfyUI
ENV HF_HOME=/workspace/.cache/huggingface

# Expose ports
EXPOSE 8188 22 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# Use the original startup or specify your own
# CMD ["/startup.sh"]  # If base image has one
# Or explicitly:
# CMD ["python", "/workspace/ComfyUI/main.py", "--listen", "0.0.0.0", "--port", "8188"]
EOF
```

### 3.2 Create docker-compose.yml for Local Development

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  comfyui:
    build:
      context: .
      dockerfile: Dockerfile
    image: yourusername/comfyui-runpod:latest
    container_name: comfyui-dev
    
    # GPU access
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    
    # Volume mounts
    volumes:
      # Your workspace - persistent data
      - ./workspace:/workspace
      # Config files (if you have them)
      - ./config:/workspace/config
    
    # Ports
    ports:
      - "8188:8188"    # ComfyUI
      - "8888:8888"    # Jupyter (if you want)
      - "6006:6006"    # TensorBoard (optional)
    
    # Environment
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb=512
      - ENVIRONMENT=local
    
    # Shared memory for data loaders
    shm_size: '8gb'
    
    # Restart policy
    restart: unless-stopped
    
    # Keep container running
    stdin_open: true
    tty: true

volumes:
  workspace:
EOF
```

### 3.3 Create Helper Scripts

**scripts/build.sh:**
```bash
cat > scripts/build.sh << 'EOF'
#!/bin/bash
set -e

IMAGE_NAME="yourusername/comfyui-runpod"
VERSION="${1:-latest}"

echo "🔨 Building ${IMAGE_NAME}:${VERSION}..."
docker build -t ${IMAGE_NAME}:${VERSION} .

if [ "$VERSION" != "latest" ]; then
    echo "🏷️  Tagging as latest..."
    docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest
fi

echo "✅ Build complete!"
echo ""
echo "Image: ${IMAGE_NAME}:${VERSION}"
echo ""
echo "Next steps:"
echo "  Test locally:  docker-compose up -d"
echo "  Push to hub:   ./scripts/push.sh ${VERSION}"
EOF
chmod +x scripts/build.sh
```

**scripts/push.sh:**
```bash
cat > scripts/push.sh << 'EOF'
#!/bin/bash
set -e

IMAGE_NAME="yourusername/comfyui-runpod"
VERSION="${1:-latest}"

echo "🚀 Pushing ${IMAGE_NAME}:${VERSION} to Docker Hub..."

# Check if logged in
if ! docker info | grep -q "Username"; then
    echo "⚠️  Not logged in to Docker Hub"
    echo "Run: docker login"
    exit 1
fi

docker push ${IMAGE_NAME}:${VERSION}

if [ "$VERSION" != "latest" ]; then
    echo "🚀 Also pushing ${IMAGE_NAME}:latest..."
    docker push ${IMAGE_NAME}:latest
fi

echo "✅ Push complete!"
echo ""
echo "Image available at:"
echo "  docker pull ${IMAGE_NAME}:${VERSION}"
echo ""
echo "RunPod template image: ${IMAGE_NAME}:${VERSION}"
EOF
chmod +x scripts/push.sh
```

**scripts/dev.sh:**
```bash
cat > scripts/dev.sh << 'EOF'
#!/bin/bash

case "$1" in
    start)
        echo "🚀 Starting ComfyUI..."
        docker-compose up -d
        echo "✅ ComfyUI running at http://localhost:8188"
        ;;
    stop)
        echo "🛑 Stopping ComfyUI..."
        docker-compose down
        ;;
    restart)
        echo "🔄 Restarting ComfyUI..."
        docker-compose restart
        ;;
    logs)
        docker-compose logs -f
        ;;
    shell)
        echo "🐚 Opening shell in container..."
        docker-compose exec comfyui bash
        ;;
    rebuild)
        echo "🔨 Rebuilding..."
        docker-compose build
        ;;
    *)
        echo "Usage: ./scripts/dev.sh {start|stop|restart|logs|shell|rebuild}"
        exit 1
        ;;
esac
EOF
chmod +x scripts/dev.sh
```

## Phase 4: Build and Test Locally (10 minutes)

### 4.1 Build Your Image

```bash
# Build with version tag
./scripts/build.sh v1.0.0

# Or manually
docker build -t yourusername/comfyui-runpod:v1.0.0 .
docker tag yourusername/comfyui-runpod:v1.0.0 yourusername/comfyui-runpod:latest
```

### 4.2 Test Locally

```bash
# Start the container
./scripts/dev.sh start

# Or manually
docker-compose up -d

# Watch the logs
docker-compose logs -f

# Check it's running
docker ps

# Verify GPU access
docker-compose exec comfyui nvidia-smi

# Test Python imports
docker-compose exec comfyui python -c "
import torch
import sageattention
print(f'PyTorch: {torch.__version__}')
print(f'CUDA: {torch.version.cuda}')
print(f'GPU: {torch.cuda.get_device_name(0)}')
print('SageAttention: OK')
"
```

### 4.3 Access ComfyUI

Open browser: http://localhost:8188

**Test your workflow:**
1. Load a WAN workflow
2. Generate a test image
3. Verify output in `./workspace/output/`

### 4.4 Get a Shell (for debugging)

```bash
# Enter the container
./scripts/dev.sh shell

# Or manually
docker-compose exec comfyui bash

# Inside container:
cd /workspace/ComfyUI
ls custom_nodes/
python main.py --help
```

## Phase 5: Push to Docker Hub (5 minutes)

### 5.1 Create Docker Hub Account

1. Go to https://hub.docker.com/
2. Sign up (free tier is fine)
3. Create repository: `comfyui-runpod`
4. Note your username

### 5.2 Login from Terminal

```bash
docker login
# Enter your Docker Hub username and password
```

### 5.3 Update Image Name

Edit your scripts and docker-compose.yml to use your actual Docker Hub username:

```bash
# Replace 'yourusername' with your actual username
sed -i 's/yourusername/YOUR_ACTUAL_USERNAME/g' scripts/*.sh
sed -i 's/yourusername/YOUR_ACTUAL_USERNAME/g' docker-compose.yml
sed -i 's/yourusername/YOUR_ACTUAL_USERNAME/g' Dockerfile
```

### 5.4 Push Image

```bash
# Push with version
./scripts/push.sh v1.0.0

# Or manually
docker push yourusername/comfyui-runpod:v1.0.0
docker push yourusername/comfyui-runpod:latest
```

**Verify on Docker Hub:**
Go to https://hub.docker.com/r/yourusername/comfyui-runpod

### 5.5 Test Pull

```bash
# On a different machine (or after docker rmi locally):
docker pull yourusername/comfyui-runpod:v1.0.0
```

## Phase 6: Deploy to RunPod (15 minutes)

### 6.1 Create RunPod Account

1. Go to https://www.runpod.io/
2. Sign up
3. Add credits ($10 minimum)

### 6.2 Create a Network Volume (Optional but Recommended)

**Why?** Your models persist between pod restarts.

1. Navigate to **Storage** → **Network Volumes**
2. Click **+ Create Volume**
3. Settings:
   - Name: `comfyui-models`
   - Size: 100GB (adjust as needed)
   - Region: Pick one close to you
4. Click **Create**
5. **Note the volume ID** (you'll need it)

### 6.3 Create a Template

1. Navigate to **Templates**
2. Click **New Template**
3. Fill in:

**Template Settings:**
```
Template Name: My ComfyUI WAN Custom
Container Image: yourusername/comfyui-runpod:v1.0.0
Container Disk: 50 GB
Volume Disk: [leave empty if using network volume]
Volume Mount Path: /workspace

Expose HTTP Ports: 8188
Expose TCP Ports: 22

Docker Command: [leave empty to use default]

Environment Variables:
ENVIRONMENT=runpod
```

**Under "Advanced" (optional):**
```
Container Registry Credentials: [none needed for public Docker Hub]
```

4. Click **Save Template**

### 6.4 Deploy Your First Pod

1. Navigate to **Pods**
2. Click **+ Deploy**
3. Select your template: "My ComfyUI WAN Custom"
4. GPU Selection:
   - For testing: RTX 3090 (~$0.30/hr)
   - For production: RTX 5090 (~$0.94/hr)
5. **Network Volume:** Select `comfyui-models` (if created)
6. Click **Deploy**

### 6.5 Access Your Pod

**Wait ~2-5 minutes for startup**, then:

1. Click **Connect**
2. Options:
   - **HTTP Service [Port 8188]** → Opens ComfyUI
   - **SSH over exposed TCP** → Shell access
   - **JupyterLab** → If you want notebook access

**ComfyUI URL will look like:**
```
https://yourpodid-8188.proxy.runpod.net/
```

### 6.6 Upload Your Workflows

**Option A: Via ComfyUI UI**
1. Open ComfyUI in browser
2. Drag and drop your workflow JSON files

**Option B: Via SSH**
```bash
# Get SSH command from RunPod (click "Connect" → "SSH over exposed TCP")
ssh root@yourpodid.proxy.runpod.net -p 12345

# Inside pod:
cd /workspace/workflows
# Upload files with scp from local:
```

From local machine:
```bash
scp -P 12345 workspace/workflows/*.json root@yourpodid.proxy.runpod.net:/workspace/workflows/
```

**Option C: Via Network Volume (one-time setup)**
```bash
# SSH into pod
ssh root@yourpodid.proxy.runpod.net -p 12345

# Download models directly on the pod
cd /workspace/models/checkpoints
wget https://huggingface.co/your-model-url.safetensors

# Or use aria2c for faster downloads
apt-get update && apt-get install -y aria2
aria2c -x 16 https://url-to-model
```

## Phase 7: The Development Workflow (Daily Use)

### 7.1 Local Experimentation

```bash
# Morning: Start local development
./scripts/dev.sh start

# Develop new workflow in ComfyUI (http://localhost:8188)
# Test on your 5060 Ti (16GB) - use smaller batch sizes

# Save workflow JSON to workspace/workflows/

# When satisfied, commit:
git add workspace/workflows/my-new-workflow.json
git commit -m "Add new WAN workflow"
```

### 7.2 When You Need More Power

```bash
# 1. Deploy pod on RunPod (if not running)
#    Select RTX 5090 or A100

# 2. Upload workflow via SSH
scp -P 12345 workspace/workflows/my-new-workflow.json \
    root@yourpodid.proxy.runpod.net:/workspace/workflows/

# 3. Open RunPod ComfyUI URL
# 4. Load your workflow
# 5. Run with bigger batch size, higher resolution
# 6. Download results
```

### 7.3 Updating Your Image

```bash
# 1. Make changes to Dockerfile or custom_nodes/
vim Dockerfile

# 2. Rebuild
./scripts/build.sh v1.0.1

# 3. Test locally
./scripts/dev.sh restart

# 4. If good, push
./scripts/push.sh v1.0.1

# 5. Update RunPod template to use v1.0.1
#    Or use :latest if you're brave
```

## Phase 8: Advanced Tips

### 8.1 Sync Models Between Local and RunPod

**Option A: Network Volume (recommended for RunPod)**
- Models stored on RunPod network volume
- Available instantly to any pod in same region
- No re-download needed

**Option B: rclone (sync local ↔ RunPod)**
```bash
# In your Dockerfile, add:
RUN apt-get update && apt-get install -y rclone

# Configure rclone on both local and RunPod
# Then sync:
rclone sync ./workspace/models/ remote:/workspace/models/
```

**Option C: Use Hugging Face Hub**
```bash
# In your workflow, download on-demand:
from huggingface_hub import hf_hub_download

model_path = hf_hub_download(
    repo_id="your-model",
    filename="model.safetensors",
    cache_dir="/workspace/models"
)
```

### 8.2 Cost Optimization

**Local (Free):**
- Experiment with workflows
- Test with small batches
- Develop custom nodes

**RunPod Spot Instances (Cheapest):**
- Non-urgent batch jobs
- Can be interrupted
- ~50% cheaper

**RunPod On-Demand:**
- Production jobs
- Guaranteed availability
- Charged per second

**Strategy:**
```bash
# Quick test: Local (5060 Ti, free)
# Medium job: RTX 3090 Spot (~$0.20/hr)
# Big job: RTX 5090 On-Demand (~$0.94/hr)
# Huge job: H100 On-Demand (~$2.50/hr)
```

### 8.3 Monitoring

**Local:**
```bash
# Watch GPU usage
watch -n 1 nvidia-smi

# Container stats
docker stats

# Logs
docker-compose logs -f comfyui
```

**RunPod:**
- Dashboard shows GPU utilization
- Click pod → "Metrics" tab
- Set up Discord/Slack webhooks for job completion

### 8.4 Automated Builds (GitHub Actions)

**.github/workflows/docker-build.yml:**
```yaml
name: Build and Push

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            yourusername/comfyui-runpod:latest
            yourusername/comfyui-runpod:${{ github.ref_name }}
```

Then:
```bash
git tag v1.0.2
git push --tags
# GitHub builds and pushes automatically
```

## Quick Reference Card

### Daily Commands

```bash
# Local development
./scripts/dev.sh start          # Start
./scripts/dev.sh stop           # Stop
./scripts/dev.sh shell          # Get shell
./scripts/dev.sh logs           # View logs

# Building
./scripts/build.sh v1.0.0       # Build with version
./scripts/push.sh v1.0.0        # Push to Docker Hub

# Testing
docker-compose exec comfyui nvidia-smi         # Check GPU
docker-compose exec comfyui python -c "..."    # Test Python
curl http://localhost:8188                      # Test ComfyUI

# RunPod
ssh root@pod-id.proxy.runpod.net -p PORT       # SSH access
scp -P PORT file.json root@pod-id:path/        # Upload files
```

### File Structure

```
comfyui-runpod/
├── Dockerfile              # Your image definition
├── docker-compose.yml      # Local development
├── .dockerignore          # Exclude from image
├── .gitignore             # Exclude from git
├── README.md              # Documentation
├── BASE_IMAGE_INFO.md     # Base image analysis
├── scripts/
│   ├── build.sh          # Build helper
│   ├── push.sh           # Push helper
│   └── dev.sh            # Dev helper
├── custom_nodes/         # Your custom nodes
├── config/               # Config files
└── workspace/            # Mounted locally
    ├── workflows/        # ✓ Commit to git
    ├── models/          # ✗ Too large
    ├── output/          # ✗ Generated
    └── input/           # ✗ User uploads
```

## Troubleshooting

### "Image won't start on RunPod"
```bash
# Check logs in RunPod dashboard
# Common issue: Missing CMD or ENTRYPOINT

# Fix in Dockerfile:
CMD ["python", "/workspace/ComfyUI/main.py", "--listen", "0.0.0.0"]
```

### "Can't access ComfyUI on RunPod"
```bash
# Ensure port 8188 is exposed
# Check in RunPod pod settings → Exposed Ports
# Try the HTTP Service link, not direct IP
```

### "Models not found on RunPod"
```bash
# If using network volume:
# 1. Ensure volume is attached
# 2. Check mount path is /workspace
# 3. Upload models to volume:
cd /workspace/models/checkpoints
wget your-model-url
```

### "Out of memory on 5060 Ti"
```bash
# Reduce batch size in workflow
# Enable --lowvram mode
# Use smaller models for testing
```

### "Push to Docker Hub fails"
```bash
# Check login:
docker login

# Check image size (max 10GB free tier):
docker images | grep comfyui-runpod

# If too large, optimize Dockerfile:
# - Remove unnecessary packages
# - Use .dockerignore
# - Multi-stage builds
```

## Next Steps

1. ✅ You now have: local dev → production pipeline
2. 📚 Learn: ComfyUI custom node development
3. 🚀 Optimize: Build CI/CD with GitHub Actions
4. 💰 Scale: Use Spot instances for batch jobs
5. 🤝 Share: Publish your image to community

**You're ready to iterate fast locally and scale on RunPod!**
