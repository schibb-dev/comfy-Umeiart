# UmeAiRT - ComfyUI Setup

🚀 **Complete ComfyUI setup optimized for AI image-to-video generation using WAN 2.1 models**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://hub.docker.com/)
[![RunPod](https://img.shields.io/badge/RunPod-Deploy-green?logo=runpod)](https://runpod.io)
[![ComfyUI](https://img.shields.io/badge/ComfyUI-v0.3.33-orange)](https://github.com/comfyanonymous/ComfyUI)

## ✨ Features

- **🎬 WAN 2.1 Models**: Complete setup for high-quality image-to-video generation
- **🚀 RunPod Ready**: Docker containerized for easy cloud deployment
- **🎯 Multi-GPU Support**: Configured for multiple GPU instances
- **🔧 Custom Nodes**: Essential custom nodes for video processing
- **📋 Optimized Workflows**: Pre-configured workflows including FaceBlast
- **💾 Resource Monitoring**: ComfyUI Manager with CPU/VRAM usage widgets
- **⚡ Performance Optimized**: SageAttention, TeaCache, and TorchCompile optimizations

## 🚀 Quick Start

### Local Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/UmeAiRT.git
   cd UmeAiRT
   ```

2. **Install ComfyUI:**
   ```bash
   ./UmeAiRT-Install-ComfyUI.sh
   ```

3. **Download models:**
   ```bash
   python download_wan_models.py
   ```

4. **Start ComfyUI:**
   ```bash
   cd ComfyUI
   python main.py --listen 0.0.0.0 --port 8188
   ```

### 🐳 RunPod Deployment

1. **Build and deploy:**
   ```bash
   ./runpod-deploy.sh
   ```

2. **Follow instructions in `RUNPOD_DEPLOYMENT.md`**

3. **Access your ComfyUI instance at `http://your-runpod-ip:8188`**

## 📦 Models Included

- **WAN 2.1 Image-to-Video models** (GGUF format, optimized for inference)
- **VAE models** for encoding/decoding
- **LoRA models** for style transfer and enhancement
- **Upscale models** for video enhancement
- **CLIP Vision models** for image understanding

## 🎯 Workflows

- **`FaceBlast.json`**: Advanced image-to-video workflow with face processing
- **Additional workflows** in the `workflows/` directory
- **Fixed type conversion issues** for seamless execution

## 🛠️ Custom Nodes Included

- **ComfyUI-Manager**: Package management and resource monitoring
- **ComfyUI-mxToolkit**: Advanced slider controls
- **ComfyUI-Easy-Use**: Utility nodes for data conversion
- **ComfyUI-KJNodes**: Video processing and optimization nodes
- **ComfyUI-VideoHelperSuite**: Video output and processing
- **ComfyUI-Frame-Interpolation**: RIFE interpolation for smooth videos
- **ComfyUI-MultiGPU**: Multi-GPU support for large models

## 📋 Requirements

- **Python 3.10+**
- **CUDA-compatible GPU** (RTX 4090, A100, etc.)
- **16GB+ VRAM** recommended for WAN 2.1 models
- **50GB+ storage** for models
- **Docker** (for RunPod deployment)

## 🚀 RunPod Deployment

This setup is optimized for RunPod cloud deployment:

### Option 1: Docker Hub (Recommended)
```bash
# Build and push to Docker Hub
./runpod-deploy.sh

# Deploy on RunPod using the generated image
```

### Option 2: Direct Upload
```bash
# Upload ComfyUI folder to RunPod
scp -r ComfyUI/ root@your-runpod-ip:/workspace/

# Install dependencies
cd /workspace/ComfyUI
pip install -r requirements.txt

# Start ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```

## 🔧 Configuration

### Environment Variables
- `CUDA_VISIBLE_DEVICES`: GPU selection
- `HF_TOKEN`: Hugging Face token for model downloads
- `CIVITAI_TOKEN`: Civitai token for additional models

### Model Paths
Models are organized in the following structure:
```
ComfyUI/models/
├── unet/          # WAN 2.1 UNet models
├── clip/          # CLIP text encoders
├── vae/           # VAE models
├── loras/         # LoRA models
├── upscale_models/# Upscaling models
└── clip_vision/   # CLIP vision models
```

## 🎬 Usage Examples

### Basic Image-to-Video
1. Load an image using `LoadImage` node
2. Set up WAN 2.1 model pipeline
3. Configure video parameters (duration, resolution)
4. Run the workflow

### Advanced Face Processing
1. Use the `FaceBlast.json` workflow
2. Upload your input image
3. Adjust parameters using the mxSlider controls
4. Generate high-quality video output

## 🐛 Troubleshooting

### Common Issues
- **Type mismatch errors**: Fixed in FaceBlast.json workflow
- **Model loading issues**: Check model paths and file integrity
- **Memory issues**: Reduce batch size or use smaller models
- **Custom node errors**: Ensure all dependencies are installed

### Performance Optimization
- Use **SageAttention** for faster inference
- Enable **TeaCache** for memory optimization
- Use **TorchCompile** for model optimization
- Configure **MultiGPU** for large models

## 📄 License

This project is licensed under the MIT License. See LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review the RunPod deployment guide

---

**Made with ❤️ for the AI video generation community**