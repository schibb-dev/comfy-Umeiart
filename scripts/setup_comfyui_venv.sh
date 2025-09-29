#!/usr/bin/env bash
set -euo pipefail

# Setup/refresh the shared ComfyUI virtualenv at ComfyUI/venv
# - Creates venv if missing
# - Upgrades pip/setuptools/wheel
# - Installs ComfyUI requirements
# - Installs any custom node requirements (if present)
# - Optionally installs PyTorch if not present (set INSTALL_TORCH=1 to force)

ROOT="/home/yuji/Code/Umeiart"
COMFY_DIR="$ROOT/ComfyUI"
VENV_DIR="$COMFY_DIR/venv"

PYTHON_BIN="python3"
if command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

echo "[1/5] Creating venv (if missing): $VENV_DIR"
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

echo "[2/5] Upgrading pip/setuptools/wheel"
"$VENV_DIR/bin/python" -m pip install -U pip setuptools wheel

echo "[3/5] Installing ComfyUI requirements"
if [[ -f "$COMFY_DIR/requirements.txt" ]]; then
  "$VENV_DIR/bin/pip" install -r "$COMFY_DIR/requirements.txt"
else
  echo "  No $COMFY_DIR/requirements.txt found; skipping."
fi

echo "[4/5] Installing custom node requirements (if any)"
shopt -s nullglob
CUSTOM_REQS=("$COMFY_DIR"/custom_nodes/*/requirements.txt)
if (( ${#CUSTOM_REQS[@]} > 0 )); then
  for req in "${CUSTOM_REQS[@]}"; do
    echo "  - $req"
    "$VENV_DIR/bin/pip" install -r "$req"
  done
else
  echo "  No custom_nodes requirements found."
fi
shopt -u nullglob

echo "[5/5] Verifying torch installation"
set +e
"$VENV_DIR/bin/python" - <<'PY'
try:
    import torch
    print('torch', torch.__version__)
except Exception as e:
    print('torch import failed:', type(e).__name__, e)
PY
rc=$?
set -e

if [[ "${INSTALL_TORCH:-0}" != "0" || $rc -ne 0 ]]; then
  echo "Installing PyTorch (if needed). You can override with TORCH_SPEC env var."
  # Default to pip's CPU package unless user specifies a wheel with CUDA.
  # Example to force CUDA 12.1: 
  #   TORCH_SPEC="torch==2.5.1+cu121 torchvision==0.20.1+cu121 --index-url https://download.pytorch.org/whl/cu121"
  TORCH_SPEC_DEFAULT="torch torchvision torchaudio"
  TORCH_SPEC="${TORCH_SPEC:-$TORCH_SPEC_DEFAULT}"
  echo "  pip install $TORCH_SPEC"
  # shellcheck disable=SC2086
  "$VENV_DIR/bin/pip" install $TORCH_SPEC || true
fi

echo "Done. Virtualenv ready at: $VENV_DIR"
"$VENV_DIR/bin/python" - <<'PY'
import sys
print('python', sys.version)
try:
    import torch
    print('torch', torch.__version__)
except Exception:
    print('torch not installed')
PY


