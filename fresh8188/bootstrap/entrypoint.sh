#!/usr/bin/env bash
set -euo pipefail
. /opt/venv/bin/activate
cd /app/ComfyUI
# Map HF token envs for compatibility (prefer HUGGINGFACEHUB_API_TOKEN)
if [ "${HUGGINGFACEHUB_API_TOKEN:-}" != "" ] && [ "${HUGGING_FACE_HUB_TOKEN:-}" = "" ]; then
  export HUGGING_FACE_HUB_TOKEN="${HUGGINGFACEHUB_API_TOKEN}"
fi
if [ "${HUGGING_FACE_HUB_TOKEN:-}" != "" ] && [ "${HUGGINGFACEHUB_API_TOKEN:-}" = "" ]; then
  export HUGGINGFACEHUB_API_TOKEN="${HUGGING_FACE_HUB_TOKEN}"
fi
find custom_nodes -maxdepth 2 -name requirements.txt -print0 | while IFS= read -r -d '' req; do pip install -r "$req" || true; done
if [ -f /bootstrap/download_models.sh ]; then bash /bootstrap/download_models.sh || true; fi
python main.py --port "${COMFYUI_PORT:-8188}" --listen 0.0.0.0




