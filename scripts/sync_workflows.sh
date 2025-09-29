#!/usr/bin/env bash
set -euo pipefail

# Sync WAN workflows between source-of-truth and ComfyUI UI-visible dir
# - Source of truth: /home/yuji/Code/Umeiart/workflows/*.json
# - UI-visible dir:  /home/yuji/Code/Umeiart/ComfyUI/workflows/*.json
#
# Usage:
#   sync_workflows.sh pull   # copy UI → source (captures UI edits)
#   sync_workflows.sh push   # copy source → UI (deploys updates)
#   sync_workflows.sh both   # pull then push

ROOT="/home/yuji/Code/Umeiart"
SRC_DIR="$ROOT/workflows"
UI_DIR="$ROOT/ComfyUI/workflows"

MODE="${1:-pull}"

mkdir -p "$SRC_DIR" "$UI_DIR"

copy_ui_to_src() {
  shopt -s nullglob
  local files=("$UI_DIR"/*_MOD.json)
  if (( ${#files[@]} == 0 )); then
    echo "[pull] No *_MOD.json in UI dir; nothing to copy."
    return
  fi
  echo "[pull] Copying UI → SRC:"
  for f in "${files[@]}"; do
    echo "  - $(basename "$f")"
    cp -f "$f" "$SRC_DIR/"
  done
}

copy_src_to_ui() {
  shopt -s nullglob
  local files=("$SRC_DIR"/*.json)
  if (( ${#files[@]} == 0 )); then
    echo "[push] No JSON workflows in SRC; nothing to copy."
    return
  fi
  echo "[push] Copying SRC → UI:"
  for f in "${files[@]}"; do
    echo "  - $(basename "$f")"
    cp -f "$f" "$UI_DIR/"
  done
}

case "$MODE" in
  pull)
    copy_ui_to_src
    ;;
  push)
    copy_src_to_ui
    ;;
  both)
    copy_ui_to_src
    copy_src_to_ui
    ;;
  *)
    echo "Usage: $0 {pull|push|both}" >&2
    exit 2
    ;;
esac

echo "Done. SRC: $SRC_DIR  UI: $UI_DIR"


