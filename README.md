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
