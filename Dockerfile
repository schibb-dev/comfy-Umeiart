FROM runpod/pytorch:2.1.0-py3.10-cuda12.1.1-devel-ubuntu22.04

WORKDIR /workspace

# Copy your ComfyUI setup
COPY ComfyUI/ /workspace/ComfyUI/

# Install dependencies
RUN cd /workspace/ComfyUI && pip install -r requirements.txt

# Set up portable symlinks for multi-GPU instances
# This ensures all model directories are shared
RUN /workspace/scripts/setup_portable_symlinks.sh

# Expose port
EXPOSE 8188

CMD ["python", "/workspace/ComfyUI/main.py", "--listen", "0.0.0.0", "--port", "8188"]






