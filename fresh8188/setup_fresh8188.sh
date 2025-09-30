#!/usr/bin/env bash
set -euo pipefail
# 1) Install Docker (if missing)
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# 2) Install NVIDIA Container Toolkit (for GPU access in Docker)
if ! dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then
  distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -fsSL https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update -y
  sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker || true
  sudo systemctl restart docker || true
fi

# 3) Prepare fresh8188
BASE=/home/yuji/Code/Umeiart/fresh8188
mkdir -p "$BASE" "$BASE/bootstrap" "$BASE/data/user" "$BASE/data/input" "$BASE/data/output" "$BASE/data/custom_nodes"

# 4) docker-compose.yml
cat > "$BASE/docker-compose.yml" <<__COMPOSE__
services:
  comfyui:
    build:
      context: .
      dockerfile: Dockerfile
    image: comfyui-fresh:latest
    container_name: comfyui_fresh_8188
    ports:
      - "8188:8188"
    environment:
      - NVIDIA_VISIBLE_DEVICES=0
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility
      - COMFYUI_PORT=8188
      - PYTHONUNBUFFERED=1
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
    volumes:
      - ./data/user:/app/ComfyUI/user
      - ./data/input:/app/ComfyUI/input
      - ./data/output:/app/ComfyUI/output
      - /home/yuji/Code/Umeiart/ComfyUI/models:/app/ComfyUI/models:rw
      - ./data/custom_nodes:/app/ComfyUI/custom_nodes
      - ./bootstrap:/bootstrap
    runtime: nvidia
    command: ["bash", "/bootstrap/entrypoint.sh"]
__COMPOSE__

# 5) Dockerfile (CUDA 12.8 + PyTorch cu128)
cat > "$BASE/Dockerfile" <<__DOCKER__
FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends     python3 python3-venv python3-pip git curl ca-certificates ffmpeg &&     rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /app/ComfyUI
RUN python3 -m venv /opt/venv && . /opt/venv/bin/activate &&     pip install --upgrade pip wheel setuptools &&     pip install --index-url https://download.pytorch.org/whl/cu128       torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 &&     pip install -r requirements.txt
ENV PATH="/opt/venv/bin:/home/yuji/.local/bin:/home/yuji/.local/bin:/home/yuji/Code/Umeiart/ComfyUI/venv/bin:/home/yuji/.local/bin:/home/yuji/Code/Umeiart/ComfyUI/venv/bin:/home/yuji/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/snap/bin"
RUN mkdir -p /app/ComfyUI/custom_nodes &&     git clone https://github.com/ltdrdata/ComfyUI-Manager /app/ComfyUI/custom_nodes/ComfyUI-Manager &&     git clone https://github.com/kijai/ComfyUI-KJNodes /app/ComfyUI/custom_nodes/ComfyUI-KJNodes || true
EXPOSE 8188
__DOCKER__

# 6) Entrypoint + optional model download hook
cat > "$BASE/bootstrap/entrypoint.sh" <<__ENTRY__
#!/usr/bin/env bash
set -euo pipefail
. /opt/venv/bin/activate
cd /app/ComfyUI
find custom_nodes -maxdepth 2 -name requirements.txt -print0 | while IFS= read -r -d  req; do pip install -r "$req" || true; done
if [ -f /bootstrap/download_models.sh ]; then bash /bootstrap/download_models.sh || true; fi
python main.py --port "${COMFYUI_PORT:-8188}" --listen 0.0.0.0
__ENTRY__
chmod +x "$BASE/bootstrap/entrypoint.sh"

cat > "$BASE/bootstrap/download_models.sh" <<__DL__
#!/usr/bin/env bash
set -euo pipefail
# Place your HuggingFace/Civitai download logic here (optional).
exit 0
__DL__
chmod +x "$BASE/bootstrap/download_models.sh"

# 7) Build + start
cd "$BASE"
if docker compose version >/dev/null 2>&1; then
  docker compose up -d --build || sudo docker compose up -d --build
else
  sudo docker-compose up -d --build
fi

# 8) Verify
(docker ps || sudo docker ps) --filter name=comfyui_fresh_8188
ss -lnt | grep -E ":8188\b" || true
