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

## Shared virtual environment

- The default virtual environment is shared at `ComfyUI/venv` and is used by both GPU launchers.
- The start scripts resolve the Python interpreter in this order:
  1. `ComfyUI/venv/bin/python` (shared venv)
  2. `ComfyUI_GPU{0,1}/venv/bin/python` (instance-local venv, if present)
  3. `python3` on PATH
  4. `python` on PATH
- To create or update the shared venv:
  - `bash scripts/setup_comfyui_venv.sh`
  - or manually:
    - `python3 -m venv ComfyUI/venv`
    - `ComfyUI/venv/bin/python -m pip install -U pip -r ComfyUI/requirements.txt`

## Troubleshooting

- Missing Torch/CUDA: re-run `scripts/setup_comfyui_venv.sh` with `INSTALL_TORCH=1` and a valid `TORCH_SPEC`.
- venv not active: `source ComfyUI/venv/bin/activate` (optional; start scripts work without activation).
- Port already in use: kill old process or change `--port` in start scripts.
- Hugging Face 403/404: ensure `.hf_token` is filled and valid; some files require auth.
- Civitai 401: ensure `.civitai_token` contains a working API token.
- Model downloads too small: rerun; mirrors may 404 intermittently; script validates size > 1MB.
- Workflows not visible: confirm `workflows/` symlink exists under `ComfyUI/workflows/` and points to repo `workflows/`.
- ComfyUI code changes: pull from your fork in `ComfyUI/` (`git -C ComfyUI pull`).
