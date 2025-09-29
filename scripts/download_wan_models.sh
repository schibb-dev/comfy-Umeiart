#!/usr/bin/env bash
set -euo pipefail

# WAN 2.1 model downloader for ComfyUI
# - Reads HF token from env HF_TOKEN or /home/yuji/Code/Umeiart/.hf_token
# - Creates ComfyUI model dirs
# - Downloads referenced models from reliable sources
# - Verifies file sizes to catch placeholder/error pages

ROOT_DIR="/home/yuji/Code/Umeiart/ComfyUI/models"
VAE_DIR="$ROOT_DIR/vae"
CLIP_VISION_DIR="$ROOT_DIR/clip_vision"
TEXT_ENCODERS_DIR="$ROOT_DIR/text_encoders"
DIFFUSION_DIR="$ROOT_DIR/diffusion_models"

mkdir -p "$VAE_DIR" "$CLIP_VISION_DIR" "$TEXT_ENCODERS_DIR" "$DIFFUSION_DIR"

# Load token
if [[ -z "${HF_TOKEN:-}" ]]; then
  if [[ -f "/home/yuji/Code/Umeiart/.hf_token" ]]; then
    export HF_TOKEN=$(sed -n 's/.*"hf_token"[: ]*"\([^"]*\)".*/\1/p' /home/yuji/Code/Umeiart/.hf_token | head -n1 || true)
  fi
fi

auth_flag=()
if [[ -n "${HF_TOKEN:-}" ]]; then
  auth_flag=( -H "Authorization: Bearer $HF_TOKEN" )
fi

# Sources (update as needed). Prefer city96 mirrors where applicable.
VAE_URL="${VAE_URL:-https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors}"
CLIP_VISION_URL="${CLIP_VISION_URL:-https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors}"
UMT5_URL="${UMT5_URL:-https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors}"

# GGUF UNet (prefer city96 480p i2v). You can override with UNET_URL directly.
CITY96_BASE="https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main"
CALCUIS_BASE="https://huggingface.co/calcuis/wan-gguf/resolve/main"
MONSTER_BASE="https://huggingface.co/MonsterMMORPG/Wan_GGUF/resolve/main"
# Configurable knobs: WAN_MODE (i2v|t2v), WAN_RES (480p|720p), WAN_QUANT (Q5_K_M|Q3_K_S|Q8_0|...)
WAN_MODE="${WAN_MODE:-i2v}"
WAN_RES="${WAN_RES:-480p}"
WAN_QUANT="${WAN_QUANT:-Q5_K_M}"
if [[ "$WAN_RES" == "480p" && "$WAN_MODE" == "i2v" ]]; then
  UNET_CANDIDATE="$CITY96_BASE/wan2.1-${WAN_MODE}-14b-${WAN_RES}-${WAN_QUANT}.gguf"
else
  # Fallback naming if users really want other combos; they can also set UNET_URL explicitly
  UNET_CANDIDATE="$CITY96_BASE/wan2.1-${WAN_MODE}-14b-${WAN_RES}-${WAN_QUANT}.gguf"
fi

# Final UNet URL selection with small probe and fallbacks through a quant list
if [[ -z "${UNET_URL:-}" ]]; then
  # Probe candidate; if 404, try other quants and alternative mirrors/patterns
  declare -a QUANTS_TRY=("$WAN_QUANT" Q5_K_M Q5_K_S Q5_1 Q5_0 Q4_K_M Q4_K_S Q4_1 Q4_0 Q3_K_M Q3_K_S Q6_K Q8_0 F16 BF16 Q2_K)
  # Bases to try in order (prefer city96)
  declare -a BASES=("$CITY96_BASE" "$CALCUIS_BASE" "$MONSTER_BASE")
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
curl -fSL "${auth_flag[@]}" -o "$VAE_DIR/wan_2.1_vae.safetensors" "$VAE_URL"

echo "Downloading CLIP-VISION ..."
curl -fSL "${auth_flag[@]}" -o "$CLIP_VISION_DIR/clip_vision_h.safetensors" "$CLIP_VISION_URL"

echo "Downloading UMT5 encoder ..."
curl -fSL "${auth_flag[@]}" -o "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "$UMT5_URL"

echo "Downloading WAN GGUF UNet ..."
curl -fSL "${auth_flag[@]}" -o "$DIFFUSION_DIR/$(basename "$UNET_URL")" "$UNET_URL"

echo "\nVerifying downloads (sizes):"
ls -lh "$VAE_DIR/wan_2.1_vae.safetensors" \
       "$CLIP_VISION_DIR/clip_vision_h.safetensors" \
       "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
       "$DIFFUSION_DIR/$(basename "$UNET_URL")" || true

echo "\nQuick sanity check (fail if suspiciously tiny files < 1MB):"
for f in \
  "$VAE_DIR/wan_2.1_vae.safetensors" \
  "$CLIP_VISION_DIR/clip_vision_h.safetensors" \
  "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
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
echo "  WAN_RES=480p|720p  (default: 480p; city96 hosts 480p)"
echo "  WAN_QUANT=Q5_K_M|Q3_K_S|Q8_0|... (default: Q5_K_M)"
echo "  UNET_URL=<direct link> to override entirely"
echo "Export HF_TOKEN or ensure /home/yuji/Code/Umeiart/.hf_token contains a valid token if downloads require auth."


