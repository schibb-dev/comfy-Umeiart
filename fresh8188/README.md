## ComfyUI (CUDA 12.8, PyTorch 2.8 cu128) - Local Docker & RunPod

### Features
- GPU-ready (NVIDIA runtime), RTX 50-series compatible
- Port 8188, listens on 0.0.0.0
- Bind-mounts for `user`, `input`, `output`, `models`, `custom_nodes`
- Optional model auto-download hook at `/bootstrap/download_models.sh`
- Hugging Face and Civitai tokens via environment variables
- Env mapping in entrypoint: you can set only one of `HUGGINGFACEHUB_API_TOKEN` or `HUGGING_FACE_HUB_TOKEN` and the other will be auto-filled

### Directory
- `Dockerfile`: CUDA 12.8 base, ComfyUI, venv, PyTorch cu128
- `docker-compose.yml`: service definition for port 8188 and bind mounts
- `bootstrap/entrypoint.sh`: installs custom node requirements, loads creds, starts ComfyUI
- `bootstrap/download_models.sh`: place your HF/Civitai download logic (optional)
- `setup_fresh8188.sh`: helper to install Docker/NVIDIA toolkit and bring up the stack

---

## Local: Docker Compose

1) Put secrets into `.env` (create alongside `docker-compose.yml`):
```
HUGGINGFACEHUB_API_TOKEN=hf_xxx
HUGGING_FACE_HUB_TOKEN=hf_xxx   # optional (entrypoint maps either way)
CIVITAI_API_TOKEN=ct_xxx
```

2) Bring it up:
```
cd fresh8188
docker compose up -d --build
```

3) Open `http://localhost:8188`.

Notes:
- Caches: set `HF_HOME=/app/ComfyUI/models/hf-cache` if you want a specific cache location.
- To auto-download models on startup, add your logic to `bootstrap/download_models.sh` (reads envs).

## Local: docker run
```
docker run -d --gpus '"device=0"' \
  -p 8188:8188 \
  -e COMFYUI_PORT=8188 \
  -e HUGGINGFACEHUB_API_TOKEN=hf_xxx \
  -e CIVITAI_API_TOKEN=ct_xxx \
  -e HF_HOME=/app/ComfyUI/models/hf-cache \
  -v $(pwd)/data/user:/app/ComfyUI/user \
  -v $(pwd)/data/input:/app/ComfyUI/input \
  -v $(pwd)/data/output:/app/ComfyUI/output \
  -v /home/yuji/Code/Umeiart/ComfyUI/models:/app/ComfyUI/models \
  -v $(pwd)/data/custom_nodes:/app/ComfyUI/custom_nodes \
  comfyui-fresh:latest bash /bootstrap/entrypoint.sh
```

---

## RunPod

### Volumes (recommended)
Map persistent volumes to:
- `/runpod-volume/user` → `/app/ComfyUI/user`
- `/runpod-volume/input` → `/app/ComfyUI/input`
- `/runpod-volume/output` → `/app/ComfyUI/output`
- `/runpod-volume/models` → `/app/ComfyUI/models`
- Optional cache: set `HF_HOME=/runpod-volume/hf-cache`

### Environment Variables
Set in the Pod template or Environment tab:
- `HUGGINGFACEHUB_API_TOKEN=hf_xxx`
- `CIVITAI_API_TOKEN=ct_xxx`
- Optional: `HF_HOME=/runpod-volume/hf-cache`

Our entrypoint maps `HUGGINGFACEHUB_API_TOKEN` ↔ `HUGGING_FACE_HUB_TOKEN`, so setting only one is fine.

### Command
Use the default command from `docker-compose.yml`:
```
bash /bootstrap/entrypoint.sh
```

### Ports
Expose port `8188` in RunPod. Access the app via the pod’s public endpoint on that port.

---

## Troubleshooting
- Permission denied to Docker socket: add your user to the `docker` group and re-login (`newgrp docker`).
- NVIDIA runtime missing on host: install `nvidia-container-toolkit`, restart Docker.
- GPU not detected: ensure the Pod has GPU, and `--gpus`/RunPod GPU settings are enabled.
- Manager/registry issues: refresh custom nodes, clear caches, restart container.





