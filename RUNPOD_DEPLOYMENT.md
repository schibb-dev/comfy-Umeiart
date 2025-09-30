# RunPod Deployment Instructions

## Quick Deploy (Using Docker Hub)

1. **Launch RunPod Instance:**
   - Go to [RunPod](https://runpod.io)
   - Choose a GPU instance (RTX 4090, A100, etc.)
   - Select "Custom Docker Image"
   - Use image: `your-dockerhub-username/umeairt-comfyui:latest`
   - Set port: `8188`
   - Enable public IP

2. **Access ComfyUI:**
   - Open: `http://your-runpod-ip:8188`
   - Your FaceBlast.json workflow is ready to use!

## Manual Deploy (Upload Files)

1. **Launch RunPod Instance:**
   - Use PyTorch template
   - Choose powerful GPU (RTX 4090 or A100)

2. **Upload Files:**
   ```bash
   # Upload ComfyUI folder
   scp -r ComfyUI/ root@your-runpod-ip:/workspace/
   
   # Upload workflows
   scp -r workflows/ root@your-runpod-ip:/workspace/ComfyUI/
   ```

3. **Install Dependencies:**
   ```bash
   cd /workspace/ComfyUI
   pip install -r requirements.txt
   pip install huggingface_hub transformers accelerate safetensors
   ```

4. **Start ComfyUI:**
   ```bash
   python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header "*"
   ```

## Models to Download

Your setup includes these models:
- WAN 2.1 models (GGUF format)
- VAE models
- LoRA models
- Upscale models

### Download WAN Models:
```bash
python download_wan_models.py
```

### Download LoRA Models:
```bash
# Quick method - opens Civitai search pages
./download_loras_quick.sh

# Or use the comprehensive manager
python lora_manager.py
```

**Priority LoRAs** (enabled in FaceBlast workflow):
- wan-thiccum-v3.safetensors
- WAN_dr34mj0b.safetensors  
- bounceV_01.safetensors

See `LORA_DOWNLOAD_INSTRUCTIONS.md` for detailed download guide.

## Features Included

✅ WAN 2.1 Image-to-Video models
✅ ComfyUI Manager with resource monitoring
✅ Custom nodes for video processing
✅ FaceBlast.json workflow (fixed)
✅ Multi-GPU support
✅ SageAttention optimization
✅ Video interpolation (RIFE)
✅ Upscaling capabilities

## Troubleshooting

- **Port Issues:** Make sure port 8188 is exposed
- **Model Loading:** Check if models are in correct directories
- **Memory Issues:** Use smaller batch sizes or lower resolution
- **Custom Nodes:** Ensure all custom nodes are installed

## Cost Optimization

- Use spot instances for development
- Stop instances when not in use
- Use smaller GPUs for testing
- Consider using RunPod's persistent storage for models
