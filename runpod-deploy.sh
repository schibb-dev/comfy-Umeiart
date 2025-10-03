#!/bin/bash

echo "🚀 UmeAiRT ComfyUI RunPod Deployment Script"
echo "=============================================="

# Configuration
DOCKER_USERNAME="schibbdev" # IMPORTANT: Replace with your Docker Hub username
IMAGE_NAME="umeairt-comfyui-runpod"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "[INFO] Starting RunPod deployment preparation..."

# 1. Check for Docker installation
if ! command -v docker &> /dev/null
then
    echo "[ERROR] Docker is not installed. Please install Docker to proceed."
    echo "        Follow instructions here: https://docs.docker.com/engine/install/"
    exit 1
else
    echo "[SUCCESS] Docker is installed"
fi

# 2. Build the Docker image
echo "[INFO] Building Docker image: ${FULL_IMAGE_NAME}"
docker build -t "${FULL_IMAGE_NAME}" .

if [ $? -ne 0 ]; then
    echo "[ERROR] Docker image build failed."
    exit 1
fi
echo "[SUCCESS] Docker image built: ${FULL_IMAGE_NAME}"

# 3. Log in to Docker Hub (if not already logged in)
echo "[INFO] Attempting to log in to Docker Hub..."
docker info | grep "Username" &> /dev/null
if [ $? -ne 0 ]; then
    docker login
    if [ $? -ne 0 ]; then
        echo "[ERROR] Docker login failed. Please ensure you have valid Docker Hub credentials."
        exit 1
    fi
fi
echo "[SUCCESS] Logged in to Docker Hub."

# 4. Push the Docker image to Docker Hub
echo "[INFO] Pushing Docker image to Docker Hub: ${FULL_IMAGE_NAME}"
docker push "${FULL_IMAGE_NAME}"

if [ $? -ne 0 ]; then
    echo "[ERROR] Docker image push failed."
    exit 1
fi
echo "[SUCCESS] Docker image pushed to Docker Hub: ${FULL_IMAGE_NAME}"

echo "🎉 RunPod Deployment Image Ready!"
echo "================================="
echo "Your Docker image is now available on Docker Hub:"
echo "  ${FULL_IMAGE_NAME}"
echo ""
echo "Next Steps for RunPod Deployment:"
echo "1. Go to https://runpod.io/console/gpu-secure-cloud"
echo "2. Select a GPU instance (e.g., RTX 4090, A100)."
echo "3. Under 'Choose an Image', select 'Custom Image'."
echo "4. Enter your image name: '${FULL_IMAGE_NAME}'"
echo "5. Set the container port to 8188."
echo "6. Map the host port (e.g., 80) to container port 8188 for web access."
echo "7. Mount a volume for persistent storage (e.g., /workspace/ComfyUI/models)."
echo "8. Launch your pod!"
echo ""
echo "Once the pod is running, access ComfyUI via http://your-runpod-ip:8188"
echo ""
echo "🔗 The container will automatically set up portable symlinks"
echo "   so all model directories are shared across any GPU instances."







