FROM runpod/pytorch:2.1.0-py3.10-cuda12.1.1-devel-ubuntu22.04

WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    unzip \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy ComfyUI setup
COPY ComfyUI/ /workspace/ComfyUI/

# Install Python dependencies
RUN cd /workspace/ComfyUI && \
    pip install --no-cache-dir -r requirements.txt

# Install additional dependencies for custom nodes
RUN pip install --no-cache-dir \
    huggingface_hub \
    transformers \
    accelerate \
    safetensors \
    opencv-python \
    pillow \
    numpy \
    torch \
    torchvision \
    torchaudio

# Create necessary directories
RUN mkdir -p /workspace/ComfyUI/models/checkpoints \
    /workspace/ComfyUI/models/loras \
    /workspace/ComfyUI/models/vae \
    /workspace/ComfyUI/models/upscale_models \
    /workspace/ComfyUI/models/clip_vision \
    /workspace/ComfyUI/models/unet \
    /workspace/ComfyUI/models/clip \
    /workspace/ComfyUI/models/gguf \
    /workspace/ComfyUI/output \
    /workspace/ComfyUI/input

# Set environment variables
ENV PYTHONPATH=/workspace/ComfyUI:$PYTHONPATH
ENV CUDA_VISIBLE_DEVICES=0

# Expose port
EXPOSE 8188

# Create startup script
RUN echo '#!/bin/bash\n\
cd /workspace/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header "*" --extra-model-paths-config /workspace/ComfyUI/extra_model_paths.yaml' > /workspace/start_comfyui.sh && \
    chmod +x /workspace/start_comfyui.sh

CMD ["/workspace/start_comfyui.sh"]
