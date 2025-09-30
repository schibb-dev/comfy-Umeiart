#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/home/yuji/Code/Umeiart"
COMFY_DIR="$PROJECT_ROOT/ComfyUI"
VENV_DIR="$COMFY_DIR/venv"
REMOTE_DEFAULT="git@github.com:schibb-dev/comfy-Umeiart.git"
COMFY_FORK_DEFAULT="git@github.com:schibb-dev/ComfyUI.git"

confirm() { read -r -p "$1 [y/N]: " ans; [[ "${ans:-}" =~ ^[Yy]$ ]]; }

step() { echo; echo "=== $1 ==="; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

step "Prerequisites"
require_cmd git
require_cmd python3
require_cmd curl

step "Git remote"
origin_url=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null || echo "")
if [[ -z "$origin_url" ]]; then
  echo "No origin remote set. Setting to $REMOTE_DEFAULT"
  git -C "$PROJECT_ROOT" remote add origin "$REMOTE_DEFAULT"
else
  echo "origin remote: $origin_url"
fi

echo "Repo status:"
git -C "$PROJECT_ROOT" status -sb | cat

step "Secrets setup"
if [[ ! -f "$PROJECT_ROOT/.hf_token" ]]; then
  echo "Creating .hf_token from example..."
  cp "$PROJECT_ROOT/.hf_token.example" "$PROJECT_ROOT/.hf_token"
  echo "Edit $PROJECT_ROOT/.hf_token to add your Hugging Face token (hf_token)."
fi
if [[ ! -f "$PROJECT_ROOT/.civitai_token" ]]; then
  echo "Creating .civitai_token from example..."
  cp "$PROJECT_ROOT/.civitai_token.example" "$PROJECT_ROOT/.civitai_token"
  echo "Edit $PROJECT_ROOT/.civitai_token to add your Civitai token (civitai_token)."
fi

step "ComfyUI fork checkout"
if [[ ! -d "$COMFY_DIR/.git" ]]; then
  echo "Cloning ComfyUI fork into $COMFY_DIR ..."
  git clone "$COMFY_FORK_DEFAULT" "$COMFY_DIR"
else
  echo "ComfyUI already present at $COMFY_DIR"
fi

step "Virtual environment"
if [[ ! -d "$VENV_DIR" ]]; then
  echo "Creating and provisioning venv..."
  INSTALL_TORCH=${INSTALL_TORCH:-1} TORCH_SPEC=${TORCH_SPEC:-"torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121"} \
  "$PROJECT_ROOT/scripts/setup_comfyui_venv.sh"
else
  echo "venv already exists: $VENV_DIR"
fi


step "Multi-GPU symlink setup"
echo "Setting up symlinks for multi-GPU instances..."
"$PROJECT_ROOT/scripts/setup_portable_symlinks.sh"

step "Download core models (optional)"
if confirm "Download WAN core models now?"; then
  "$PROJECT_ROOT/scripts/download_wan_models.sh"
else
  echo "Skipping model download. You can run scripts/download_wan_models.sh later."
fi

step "Start ComfyUI"
if confirm "Start GPU0 instance now (port 8188)?"; then
  "$PROJECT_ROOT/scripts/start_comfyui_gpu0.sh" &
  echo "Launched GPU0 in background."
fi
if confirm "Start GPU1 instance now (port 8189)?"; then
  "$PROJECT_ROOT/scripts/start_comfyui_gpu1.sh" &
  echo "Launched GPU1 in background."
fi

echo
echo "All done. Review README_SECRETS.md and scripts/README.md for details."
