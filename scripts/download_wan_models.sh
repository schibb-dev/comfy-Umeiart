#!/usr/bin/env bash
set -euo pipefail

# WAN 2.1 model downloader for ComfyUI
# - Reads HF token from env HF_TOKEN or /home/yuji/Code/Umeiart/.hf_token
# - Creates ComfyUI model dirs
# - Downloads referenced models from reliable sources
# - Verifies file sizes to catch placeholder/error pages
# - Resumes downloads and verifies size/checksum when available

ROOT_DIR="/home/yuji/Code/Umeiart/ComfyUI/models"
VAE_DIR="$ROOT_DIR/vae"
CLIP_VISION_DIR="$ROOT_DIR/clip_vision"
TEXT_ENCODERS_DIR="$ROOT_DIR/text_encoders"
FLORENCE2_DIR="$ROOT_DIR/florence2"
DIFFUSION_DIR="$ROOT_DIR/diffusion_models"

mkdir -p "$VAE_DIR" "$CLIP_VISION_DIR" "$TEXT_ENCODERS_DIR" "$FLORENCE2_DIR" "$DIFFUSION_DIR"

# Reusable download helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_download.sh
source "$SCRIPT_DIR/lib_download.sh"

# Load token
if [[ -z "${HF_TOKEN:-}" ]]; then
  if [[ -f "/home/yuji/Code/Umeiart/.hf_token" ]]; then
    export HF_TOKEN=$(sed -n 's/.*"hf_token"[: ]*"\([^"]*\)".*/\1/p' /home/yuji/Code/Umeiart/.hf_token | head -n1 || true)
  fi
fi

auth_headers=( )
if [[ -n "${HF_TOKEN:-}" ]]; then
  auth_headers=( -- -H "Authorization: Bearer $HF_TOKEN" )
fi

# Sources (update as needed). Prefer city96 mirrors where applicable.
VAE_URL="${VAE_URL:-https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors}"
CLIP_VISION_URL="${CLIP_VISION_URL:-https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors}"
UMT5_URL="${UMT5_URL:-https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors}"
# UMT5 GGUF with fallback sources
UMT5_GGUF_CITY96="https://huggingface.co/city96/umt5-xxl-encoder-gguf/resolve/main/umt5-xxl-encoder-Q5_K_M.gguf"
UMT5_GGUF_UMEIARTS="https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/models/clip/umt5-xxl-encoder-Q5_K_M.gguf"
UMT5_GGUF_URL="${UMT5_GGUF_URL:-$UMT5_GGUF_CITY96}"
FLORENCE2_REPO_ID="${FLORENCE2_REPO_ID:-MiaoshouAI/Florence-2-base-PromptGen-v2.0}"

# GGUF UNet sources with fallback order. You can override with UNET_URL directly.
CITY96_BASE="https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main"
CITY96_720P_BASE="https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main"
UMEIARTS_BASE="https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/models/unet"
CALCUIS_BASE="https://huggingface.co/calcuis/wan-gguf/resolve/main"
MONSTER_BASE="https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main"
# Configurable knobs: WAN_MODE (i2v|t2v), WAN_RES (480p|720p), WAN_QUANT (Q5_K_M|Q3_K_S|Q8_0|...)
WAN_MODE="${WAN_MODE:-i2v}"
WAN_RES="${WAN_RES:-480p}"
WAN_QUANT="${WAN_QUANT:-Q5_K_M}"

# Select base URL based on resolution
if [[ "$WAN_RES" == "720p" ]]; then
  PRIMARY_BASE="$CITY96_720P_BASE"
else
  PRIMARY_BASE="$CITY96_BASE"
fi

# Initial candidate
UNET_CANDIDATE="$PRIMARY_BASE/wan2.1-${WAN_MODE}-14b-${WAN_RES}-${WAN_QUANT}.gguf"

# Final UNet URL selection with small probe and fallbacks through a quant list
if [[ -z "${UNET_URL:-}" ]]; then
  # Probe candidate; if 404, try other quants and alternative mirrors/patterns
  declare -a QUANTS_TRY=("$WAN_QUANT" Q5_K_M Q5_K_S Q5_1 Q5_0 Q4_K_M Q4_K_S Q4_1 Q4_0 Q3_K_M Q3_K_S Q6_K Q8_0 F16 BF16 Q2_K)
  # Bases to try in order (prefer city96, then Umeiarts, then others)
  if [[ "$WAN_RES" == "720p" ]]; then
    declare -a BASES=("$CITY96_720P_BASE" "$UMEIARTS_BASE" "$CITY96_BASE" "$CALCUIS_BASE" "$MONSTER_BASE")
  else
    declare -a BASES=("$CITY96_BASE" "$UMEIARTS_BASE" "$CITY96_720P_BASE" "$CALCUIS_BASE" "$MONSTER_BASE")
  fi
  found_url=""
  for base in "${BASES[@]}"; do
    for q in "${QUANTS_TRY[@]}"; do
      # Try several filename patterns per base
      declare -a PATTERNS=(
        "wan2.1-${WAN_MODE}-14b-${WAN_RES}-${q}.gguf"         # city-style dashed
        "wan2.1_${WAN_MODE}_14B_${WAN_RES}_${q}.gguf"         # underscored variant
        "wan2.1-${WAN_MODE}-14b-${q}.gguf"                    # no res
        "wan2.1_${WAN_MODE}_14B_${q}.gguf"                    # no res underscore
        "wan2.1-t2v-14b-${q}.gguf"                            # monster t2v style
        "wan2.1_t2v_14B_${q}.gguf"                            # underscore variant
        "wan2.1-i2v-14b-720p-${q}.gguf"                       # Umeiarts 720p style
        "wan2.1-i2v-14b-480p-${q}.gguf"                       # Umeiarts 480p style
      )
      for fname in "${PATTERNS[@]}"; do
        try_url="$base/$fname"
        if curl -fsI "${auth_flag[@]}" "$try_url" >/dev/null 2>&1; then
          found_url="$try_url"; break 2
        fi
      done
    done
  done
  if [[ -n "$found_url" ]]; then
    UNET_URL="$found_url"
  fi
fi
UNET_URL="${UNET_URL:-$UNET_CANDIDATE}"

echo "Downloading VAE ..."
download_with_resume "$VAE_URL" "$VAE_DIR/wan_2.1_vae.safetensors" "" "" ${auth_headers[@]}

echo "Downloading CLIP-VISION ..."
download_with_resume "$CLIP_VISION_URL" "$CLIP_VISION_DIR/clip_vision_h.safetensors" "" "" ${auth_headers[@]}

echo "Downloading UMT5 encoder ..."
download_with_resume "$UMT5_URL" "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "" "" ${auth_headers[@]}

echo "Downloading UMT5-XXL GGUF encoder ..."
# Try primary source first, then fallback to Umeiarts
if ! download_with_resume "$UMT5_GGUF_URL" "$TEXT_ENCODERS_DIR/$(basename "$UMT5_GGUF_URL")" "" "" ${auth_headers[@]} 2>/dev/null; then
  echo "Primary UMT5 GGUF source failed, trying Umeiarts fallback..."
  download_with_resume "$UMT5_GGUF_UMEIARTS" "$TEXT_ENCODERS_DIR/$(basename "$UMT5_GGUF_UMEIARTS")" "" "" ${auth_headers[@]}
fi

echo "Downloading WAN GGUF UNet ..."
download_with_resume "$UNET_URL" "$DIFFUSION_DIR/$(basename "$UNET_URL")" "" "" ${auth_headers[@]}

echo "Installing GGUF dependencies (sentencepiece, protobuf) ..."
cd "$ROOT_DIR/.." && source venv/bin/activate && pip install sentencepiece protobuf

echo "Prefetching Florence2 model repo ($FLORENCE2_REPO_ID) ..."
cd "$ROOT_DIR/.." && source venv/bin/activate && python3 - <<PY ${auth_headers[@]}
import os
from pathlib import Path
from huggingface_hub import snapshot_download

repo_id = os.environ.get('FLORENCE2_REPO_ID', 'MiaoshouAI/Florence-2-base-PromptGen-v2.0')
dest_root = Path(r"$FLORENCE2_DIR") / repo_id.replace('/', '__')
dest_root.mkdir(parents=True, exist_ok=True)

snapshot_download(repo_id=repo_id,
                  local_dir=str(dest_root),
                  local_dir_use_symlinks=False,
                  resume_download=True)
print(f"Downloaded Florence2 repo to: {dest_root}")
PY

echo "\nVerifying downloads (sizes):"
ls -lh "$VAE_DIR/wan_2.1_vae.safetensors" \
       "$CLIP_VISION_DIR/clip_vision_h.safetensors" \
       "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
       "$TEXT_ENCODERS_DIR/$(basename "$UMT5_GGUF_URL")" \
       "$DIFFUSION_DIR/$(basename "$UNET_URL")" || true

echo "\nQuick sanity check (fail if suspiciously tiny files < 1MB):"
for f in \
  "$VAE_DIR/wan_2.1_vae.safetensors" \
  "$CLIP_VISION_DIR/clip_vision_h.safetensors" \
  "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
  "$TEXT_ENCODERS_DIR/$(basename "$UMT5_GGUF_URL")" \
  "$DIFFUSION_DIR/$(basename "$UNET_URL")"; do
  if [[ ! -s "$f" ]]; then
    echo "ERROR: missing file: $f" >&2; exit 1
  fi
  sz=$(stat -c %s "$f")
  if (( sz < 1000000 )); then
    echo "ERROR: $f looks too small ($sz bytes). Likely a placeholder or error page." >&2
    exit 2
  fi
done

echo "\nDone. You can control selection via env vars:"
echo "  WAN_MODE=i2v|t2v   (default: i2v)"
echo "  WAN_RES=480p|720p  (default: 480p; city96 hosts both 480p and 720p)"
echo "  WAN_QUANT=Q5_K_M|Q3_K_S|Q8_0|... (default: Q5_K_M)"
echo "  UNET_URL=<direct link> to override entirely"
echo "  UMT5_GGUF_URL=<direct link> to override UMT5 GGUF source"
echo ""
echo "Fallback order for UNet models:"
echo "  1. city96 (primary resolution)"
echo "  2. Umeiarts repository"
echo "  3. city96 (other resolution)"
echo "  4. calcuis repository"
echo "  5. MonsterMMORPG repository"
echo ""
echo "Export HF_TOKEN or ensure /home/yuji/Code/Umeiart/.hf_token contains a valid token if downloads require auth."


