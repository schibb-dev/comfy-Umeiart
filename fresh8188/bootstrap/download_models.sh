#!/usr/bin/env bash
set -euo pipefail

# ComfyUI Model Download Script
# Automatically analyzes workflows and downloads required models from Hugging Face

echo "=== ComfyUI Model Downloader ==="

# Check if HF token is available
if [ -z "${HUGGINGFACEHUB_API_TOKEN:-}" ] && [ -z "${HUGGING_FACE_HUB_TOKEN:-}" ]; then
    echo "Warning: No Hugging Face token found. Set HUGGINGFACEHUB_API_TOKEN or HUGGING_FACE_HUB_TOKEN"
    echo "Some models may not be downloadable without authentication."
fi

# Enable faster downloads if available
python3 -c "
try:
    import hf_transfer
    import os
    os.environ.setdefault('HF_HUB_ENABLE_HF_TRANSFER', '1')
    print('✓ hf_transfer enabled for faster downloads')
except ImportError:
    print('ℹ hf_transfer not available, using standard downloads')
    print('  Install with: pip install hf_transfer')
"

# Install huggingface-cli if not available
if ! command -v huggingface-cli >/dev/null 2>&1; then
    echo "Installing huggingface_hub..."
    pip install huggingface_hub
fi

# Function to analyze workflows and download models
download_workflow_models() {
    local workflow_dir="${1:-/app/ComfyUI/user/default/workflows}"
    
    if [ ! -d "$workflow_dir" ]; then
        echo "Workflow directory not found: $workflow_dir"
        return 1
    fi
    
    echo "Analyzing workflows in: $workflow_dir"
    
    # Find all JSON workflow files
    local workflows=()
    while IFS= read -r -d '' file; do
        workflows+=("$file")
    done < <(find "$workflow_dir" -name "*.json" -print0 2>/dev/null)
    
    if [ ${#workflows[@]} -eq 0 ]; then
        echo "No workflow files found in $workflow_dir"
        return 0
    fi
    
    echo "Found ${#workflows[@]} workflow(s)"
    
    # Use the workflow analyzer to get model requirements
    local models_info
    if models_info=$(python3 /bootstrap/workflow_analyzer.py "${workflows[@]}" 2>/dev/null); then
        echo "$models_info"
        
        # Extract Hugging Face models and generate download commands
        local hf_models=()
        while IFS= read -r line; do
            # Look for lines like: "  - model_name [type] (repo_id)" for Hugging Face models
            # Use a simpler regex pattern to avoid bash escaping issues
            if echo "$line" | grep -qE "^[[:space:]]*-[[:space:]]+[^[:space:]]+[[:space:]]+\[[^]]+\][[:space:]]*\([^)]+\)$"; then
                # Extract model name, type, and repo_id using sed
                local model_name=$(echo "$line" | sed -E 's/^[[:space:]]*-[[:space:]]+([^[:space:]]+)[[:space:]]+\[[^]]+\][[:space:]]*\([^)]+\)$/\1/')
                local model_type=$(echo "$line" | sed -E 's/^[[:space:]]*-[[:space:]]+[^[:space:]]+[[:space:]]+\[([^]]+)\][[:space:]]*\([^)]+\)$/\1/')
                local repo_id=$(echo "$line" | sed -E 's/^[[:space:]]*-[[:space:]]+[^[:space:]]+[[:space:]]+\[[^]]+\][[:space:]]*\(([^)]+)\)$/\1/')
                
                # Check if this is a Hugging Face model (has repo_id format)
                if echo "$repo_id" | grep -qE "^[a-zA-Z0-9\-_]+/[a-zA-Z0-9\-_\.]+$"; then
                    hf_models+=("$repo_id:$model_name")
                fi
            fi
        done <<< "$models_info"
        
        # Download Hugging Face models
        if [ ${#hf_models[@]} -gt 0 ]; then
            echo "Downloading ${#hf_models[@]} Hugging Face model(s)..."
            
            for model_spec in "${hf_models[@]}"; do
                IFS=':' read -r repo_id model_name <<< "$model_spec"
                
                echo "Downloading: $repo_id ($model_name)"
                
                if [ -n "$model_name" ] && [ "$model_name" != "$repo_id" ]; then
                    # Download specific file
                    huggingface-cli download "$repo_id" "$model_name" \
                        --local-dir "$HF_HOME" \
                        --local-dir-use-symlinks False \
                        --resume-download \
                        --quiet || echo "Failed to download $repo_id:$model_name"
                else
                    # Download entire repo
                    huggingface-cli download "$repo_id" \
                        --local-dir "$HF_HOME" \
                        --local-dir-use-symlinks False \
                        --resume-download \
                        --quiet || echo "Failed to download $repo_id"
                fi
            done
        else
            echo "No Hugging Face models found in workflows"
        fi
    else
        echo "Failed to analyze workflows, falling back to manual model list"
        
        # Fallback: Download common models that are likely needed
        echo "Downloading common ComfyUI models..."
        
        local common_models=(
            "stabilityai/stable-diffusion-xl-base-1.0:sd_xl_base_1.0.safetensors"
            "madebyollin/sdxl-vae-fp16-fix:sdxl_vae.safetensors"
            "h94/IP-Adapter:clip_vision_h.safetensors"
            "xinntao/realesrgan:RealESRGAN_x4plus.pth"
            "Fannovel16/RIFE:rife47.pth"
        )
        
        for model_spec in "${common_models[@]}"; do
            IFS=':' read -r repo_id filename <<< "$model_spec"
            echo "Downloading: $repo_id ($filename)"
            
            huggingface-cli download "$repo_id" "$filename" \
                --local-dir "$HF_HOME" \
                --local-dir-use-symlinks False \
                --resume-download \
                --quiet || echo "Failed to download $repo_id:$filename"
        done
    fi
}

# Main execution
echo "Starting model download process..."

# Set HF_HOME if not already set
export HF_HOME="${HF_HOME:-/app/ComfyUI/models/hf-cache}"

# Create HF cache directory
mkdir -p "$HF_HOME"

# Download models from workflows
download_workflow_models

echo "=== Model download complete ==="
echo "Models cached in: $HF_HOME"
echo "Cache size: $(du -sh "$HF_HOME" 2>/dev/null | cut -f1 || echo 'unknown')"

exit 0
