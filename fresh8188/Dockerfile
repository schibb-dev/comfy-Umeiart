FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip git curl ca-certificates ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /app/ComfyUI

# Install Python dependencies
RUN python3 -m venv /opt/venv && . /opt/venv/bin/activate && \
    pip install --upgrade pip wheel setuptools && \
    pip install --index-url https://download.pytorch.org/whl/cu128 \
      torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 && \
    pip install -r requirements.txt

# Install additional dependencies for custom nodes
RUN . /opt/venv/bin/activate && \
    pip install opencv-python pillow numpy scipy scikit-image

# Set up the entrypoint
WORKDIR /app/ComfyUI
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]