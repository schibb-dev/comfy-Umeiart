FROM nvidia/cuda:12.8.0-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends     python3 python3-venv python3-pip python3-dev build-essential git curl ca-certificates ffmpeg &&     rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /app/ComfyUI
RUN python3 -m venv /opt/venv && . /opt/venv/bin/activate &&     pip install --upgrade pip wheel setuptools &&     pip install --index-url https://download.pytorch.org/whl/cu128       torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 &&     pip install -r requirements.txt
ENV PATH="/opt/venv/bin:$PATH"
RUN mkdir -p /app/ComfyUI/custom_nodes &&     git clone https://github.com/ltdrdata/ComfyUI-Manager /app/ComfyUI/custom_nodes/ComfyUI-Manager &&     git clone https://github.com/kijai/ComfyUI-KJNodes /app/ComfyUI/custom_nodes/ComfyUI-KJNodes || true
EXPOSE 8188
