Scripts layout

- scripts/: core utilities used long-term
  - setup_comfyui_venv.sh: manage ComfyUI/venv
  - download_wan_models.sh: robust WAN model downloader (with mirrors)
  - civitai_downloader.sh: generic Civitai asset downloader
  - start_comfyui_gpu0.sh / start_comfyui_gpu1.sh: launchers
  - Install-ComfyUI.sh: base installer
- scripts/ephemeral/: ad-hoc helpers and one-offs
  - ...
- scripts/ephemeral/legacy/: deprecated or superseded variants kept for reference
