#!/usr/bin/env python3
"""
Workflow Model Analyzer for ComfyUI

Analyzes ComfyUI workflow JSON files to extract required models and their sources.
Supports Hugging Face Hub, Civitai, and local model detection.
"""

import json
import os
import sys
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional
from dataclasses import dataclass

@dataclass
class ModelInfo:
    """Information about a required model"""
    name: str
    type: str  # checkpoint, vae, lora, clip, upscale, etc.
    source: str  # huggingface, civitai, local
    repo_id: Optional[str] = None  # For HF models
    filename: Optional[str] = None
    size_mb: Optional[int] = None

class WorkflowAnalyzer:
    """Analyzes ComfyUI workflows to extract model requirements"""
    
    def __init__(self):
        # Common model loaders and their widget names
        self.model_loaders = {
            'CheckpointLoader': 'ckpt_name',
            'CheckpointLoaderSimple': 'ckpt_name', 
            'VAELoader': 'vae_name',
            'CLIPLoader': 'clip_name',
            'CLIPVisionLoader': 'clip_name',
            'UpscaleModelLoader': 'model_name',
            'LoraLoader': 'lora_name',
            'UnetLoader': 'unet_name',
            'UnetLoaderGGUFDisTorchMultiGPU': 'unet_name',
            'CLIPLoaderGGUFMultiGPU': 'clip_name',
            'DownloadAndLoadFlorence2Model': 'model',
        }
        
        # Hugging Face model patterns
        self.hf_patterns = [
            r'^[a-zA-Z0-9\-_]+\/[a-zA-Z0-9\-_\.]+$',  # user/repo format
            r'^[a-zA-Z0-9\-_]+$',  # Just repo name (common models)
        ]
        
        # Known HF model repositories
        self.known_hf_models = {
            # SDXL models
            'sd_xl_base_1.0.safetensors': 'stabilityai/stable-diffusion-xl-base-1.0',
            'sd_xl_refiner_1.0.safetensors': 'stabilityai/stable-diffusion-xl-refiner-1.0',
            'sdxl_vae.safetensors': 'madebyollin/sdxl-vae-fp16-fix',
            'clip_vision_h.safetensors': 'h94/IP-Adapter',
            
            # SD 1.5 models
            'v1-5-pruned-emaonly.safetensors': 'runwayml/stable-diffusion-v1-5',
            'vae-ft-mse-840000-ema-pruned.safetensors': 'stabilityai/sd-vae-ft-mse-original',
            
            # Common VAE models
            'vae-ft-mse-840000-ema-pruned.safetensors': 'stabilityai/sd-vae-ft-mse-original',
            'vae-ft-mse-840000-ema-pruned.ckpt': 'stabilityai/sd-vae-ft-mse-original',
            
            # Upscale models
            'RealESRGAN_x4plus.pth': 'xinntao/realesrgan',
            'RealESRGAN_x4plus_anime_6B.pth': 'xinntao/realesrgan',
            
            # RIFE models
            'rife47.pth': 'Fannovel16/RIFE',
            
            # Florence2 models
            'MiaoshouAI/Florence-2-base-PromptGen-v2.0': 'MiaoshouAI/Florence-2-base-PromptGen-v2.0',
        }
        
        # Model type detection patterns
        self.model_type_patterns = {
            'checkpoint': [r'\.(safetensors|ckpt)$', r'.*sd.*', r'.*stable.*diffusion.*'],
            'vae': [r'vae.*\.(safetensors|ckpt)$', r'.*vae.*'],
            'lora': [r'\.(safetensors)$', r'.*lora.*'],
            'clip': [r'clip.*\.(safetensors|bin)$', r'.*clip.*'],
            'upscale': [r'\.(pth)$', r'.*esrgan.*', r'.*upscale.*'],
            'rife': [r'rife.*\.(pth)$', r'.*rife.*'],
        }

    def analyze_workflow(self, workflow_path: str) -> List[ModelInfo]:
        """Analyze a workflow file and return required models"""
        try:
            with open(workflow_path, 'r', encoding='utf-8') as f:
                workflow = json.load(f)
        except Exception as e:
            print(f"Error reading workflow {workflow_path}: {e}", file=sys.stderr)
            return []
        
        models = []
        nodes = workflow.get('nodes', [])
        
        for node in nodes:
            node_type = node.get('type', '')
            widgets = node.get('widgets_values', [])
            
            if node_type in self.model_loaders:
                widget_name = self.model_loaders[node_type]
                
                # Find the model name in widgets
                model_name = None
                for widget in widgets:
                    if isinstance(widget, str) and widget.strip():
                        model_name = widget.strip()
                        break
                
                if model_name:
                    model_info = self._classify_model(model_name, node_type)
                    if model_info:
                        models.append(model_info)
        
        return models

    def _classify_model(self, model_name: str, node_type: str) -> Optional[ModelInfo]:
        """Classify a model by name and determine its source"""
        
        # Determine model type
        model_type = self._detect_model_type(model_name, node_type)
        
        # Check if it's a known Hugging Face model
        if model_name in self.known_hf_models:
            repo_id = self.known_hf_models[model_name]
            return ModelInfo(
                name=model_name,
                type=model_type,
                source='huggingface',
                repo_id=repo_id,
                filename=model_name
            )
        
        # Check HF patterns
        for pattern in self.hf_patterns:
            if re.match(pattern, model_name):
                return ModelInfo(
                    name=model_name,
                    type=model_type,
                    source='huggingface',
                    repo_id=model_name,
                    filename=None
                )
        
        # Check for Civitai patterns (usually have specific naming)
        if any(indicator in model_name.lower() for indicator in ['civitai', 'civit', 'wan', 'realistic']):
            return ModelInfo(
                name=model_name,
                type=model_type,
                source='civitai',
                filename=model_name
            )
        
        # Default to local
        return ModelInfo(
            name=model_name,
            type=model_type,
            source='local',
            filename=model_name
        )

    def _detect_model_type(self, model_name: str, node_type: str) -> str:
        """Detect the type of model based on name and node type"""
        model_name_lower = model_name.lower()
        
        # Node type based detection
        if 'VAE' in node_type:
            return 'vae'
        elif 'CLIP' in node_type:
            return 'clip'
        elif 'Upscale' in node_type or 'UpscaleModel' in node_type:
            return 'upscale'
        elif 'Lora' in node_type:
            return 'lora'
        elif 'Unet' in node_type:
            return 'unet'
        elif 'Florence' in node_type:
            return 'florence2'
        
        # Name pattern based detection
        for model_type, patterns in self.model_type_patterns.items():
            for pattern in patterns:
                if re.search(pattern, model_name_lower):
                    return model_type
        
        # Default based on node type
        if 'Checkpoint' in node_type:
            return 'checkpoint'
        
        return 'unknown'

    def generate_download_commands(self, models: List[ModelInfo]) -> List[str]:
        """Generate download commands for Hugging Face models"""
        commands = []
        hf_models = [m for m in models if m.source == 'huggingface']
        
        if not hf_models:
            return commands
        
        # Group by repo_id to avoid duplicates
        repos = {}
        for model in hf_models:
            if model.repo_id:
                if model.repo_id not in repos:
                    repos[model.repo_id] = []
                if model.filename:
                    repos[model.repo_id].append(model.filename)
        
        for repo_id, filenames in repos.items():
            if filenames:
                # Download specific files
                for filename in filenames:
                    commands.append(f'huggingface-cli download "{repo_id}" "{filename}" --local-dir "$HF_HOME" --local-dir-use-symlinks False --resume')
            else:
                # Download entire repo
                commands.append(f'huggingface-cli download "{repo_id}" --local-dir "$HF_HOME" --local-dir-use-symlinks False --resume')
        
        return commands

    def print_summary(self, models: List[ModelInfo]):
        """Print a summary of required models"""
        if not models:
            print("No models found in workflow")
            return
        
        print(f"Found {len(models)} models:")
        print()
        
        by_source = {}
        for model in models:
            if model.source not in by_source:
                by_source[model.source] = []
            by_source[model.source].append(model)
        
        for source, source_models in by_source.items():
            print(f"{source.upper()} ({len(source_models)} models):")
            for model in source_models:
                repo_info = f" ({model.repo_id})" if model.repo_id else ""
                print(f"  - {model.name} [{model.type}]{repo_info}")
            print()

def main():
    """Main function for command line usage"""
    if len(sys.argv) < 2:
        print("Usage: python workflow_analyzer.py <workflow.json> [workflow2.json ...]")
        sys.exit(1)
    
    analyzer = WorkflowAnalyzer()
    all_models = []
    
    for workflow_path in sys.argv[1:]:
        if not os.path.exists(workflow_path):
            print(f"Workflow file not found: {workflow_path}", file=sys.stderr)
            continue
        
        print(f"Analyzing: {workflow_path}")
        models = analyzer.analyze_workflow(workflow_path)
        all_models.extend(models)
    
    # Remove duplicates
    unique_models = []
    seen = set()
    for model in all_models:
        key = (model.name, model.type, model.source)
        if key not in seen:
            seen.add(key)
            unique_models.append(model)
    
    analyzer.print_summary(unique_models)
    
    # Generate download commands
    commands = analyzer.generate_download_commands(unique_models)
    if commands:
        print("Hugging Face download commands:")
        for cmd in commands:
            print(f"  {cmd}")

if __name__ == "__main__":
    main()
