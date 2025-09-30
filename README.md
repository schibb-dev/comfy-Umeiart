Umeiart

## QUICKSTART

```bash
bash scripts/bootstrap_setup.sh
```

This guided script will:
- Ensure prerequisites (git, python3, curl)
- Create secrets templates (`.hf_token`, `.civitai_token`) from examples
- Clone your ComfyUI fork into `ComfyUI/`
- Set up `ComfyUI/venv` and optionally install Torch
- Optionally download WAN core models
- Optionally start GPU0/GPU1 instances

For secret details, see `README_SECRETS.md`.

## GPU notes

- GPU0 runs on port 8188 (`scripts/start_comfyui_gpu0.sh`), GPU1 on 8189 (`scripts/start_comfyui_gpu1.sh`).
- Override CUDA selection with `CUDA_VISIBLE_DEVICES` or `--cuda-device` if needed.
- For specific CUDA builds of Torch, set before bootstrap: 
  - `INSTALL_TORCH=1 TORCH_SPEC="torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121" bash scripts/bootstrap_setup.sh`

## Troubleshooting

- Missing Torch/CUDA: re-run `scripts/setup_comfyui_venv.sh` with `INSTALL_TORCH=1` and a valid `TORCH_SPEC`.
- venv not active: `source ComfyUI/venv/bin/activate`.
- Port already in use: kill old process or change `--port` in start scripts.
- Hugging Face 403/404: ensure `.hf_token` is filled and valid; some files require auth.
- Civitai 401: ensure `.civitai_token` contains a working API token.
- Model downloads too small: rerun; mirrors may 404 intermittently; script validates size > 1MB.
- Workflows not visible: confirm `workflows/` symlink exists under `ComfyUI/workflows/` and points to repo `workflows/`.
- ComfyUI code changes: pull from your fork in `ComfyUI/` (`git -C ComfyUI pull`).
