#!/usr/bin/env python3
"""
Comprehensive LoRA Management for WAN 2.1 FaceBlast Workflow
Downloads and manages LoRA models from multiple sources
"""

import os
import json
import requests
import subprocess
from pathlib import Path
from tqdm import tqdm

class LoRAManager:
    def __init__(self, base_dir="/home/yuji/Code/Umeiart"):
        self.base_dir = Path(base_dir)
        self.lora_dir = self.base_dir / "ComfyUI" / "models" / "loras"
        self.lora_dir.mkdir(parents=True, exist_ok=True)
        
        # LoRA definitions with multiple source options
        self.loras = {
            'wan-nsfw-e14-fixed.safetensors': {
                'description': 'WAN NSFW Enhancement LoRA',
                'strength': 1.0,
                'enabled': False,
                'sources': [
                    {'type': 'civitai', 'url': 'https://civitai.com/models/XXXXXX', 'search': 'wan nsfw e14'},
                    {'type': 'huggingface', 'repo': 'wan-research/wan-loras', 'file': 'wan-nsfw-e14-fixed.safetensors'}
                ]
            },
            'wan_cumshot_i2v.safetensors': {
                'description': 'WAN Cumshot Image-to-Video LoRA',
                'strength': 0.95,
                'enabled': False,
                'sources': [
                    {'type': 'civitai', 'url': 'https://civitai.com/models/XXXXXX', 'search': 'wan cumshot i2v'},
                    {'type': 'huggingface', 'repo': 'wan-research/wan-loras', 'file': 'wan_cumshot_i2v.safetensors'}
                ]
            },
            'facials60.safetensors': {
                'description': 'Facial Enhancement LoRA',
                'strength': 0.95,
                'enabled': False,
                'sources': [
                    {'type': 'civitai', 'url': 'https://civitai.com/models/XXXXXX', 'search': 'facials60'},
                    {'type': 'huggingface', 'repo': 'wan-research/wan-loras', 'file': 'facials60.safetensors'}
                ]
            },
            'Handjob-wan-e38.safetensors': {
                'description': 'Handjob WAN LoRA',
                'strength': 1.0,
                'enabled': False,
                'sources': [
                    {'type': 'civitai', 'url': 'https://civitai.com/models/XXXXXX', 'search': 'handjob wan e38'},
                    {'type': 'huggingface', 'repo': 'wan-research/wan-loras', 'file': 'Handjob-wan-e38.safetensors'}
                ]
            },
            'wan-thiccum-v3.safetensors': {
                'description': 'WAN Thiccum v3 LoRA',
                'strength': 0.95,
                'enabled': True,
                'sources': [
                    {'type': 'civitai', 'url': 'https://civitai.com/models/XXXXXX', 'search': 'wan thiccum v3'},
                    {'type': 'huggingface', 'repo': 'wan-research/wan-loras', 'file': 'wan-thiccum-v3.safetensors'}
                ]
            },
            'WAN_dr34mj0b.safetensors': {
                'description': 'WAN Dr34mj0b LoRA',
                'strength': 1.0,
                'enabled': True,
                'sources': [
                    {'type': 'civitai', 'url': 'https://civitai.com/models/XXXXXX', 'search': 'wan dr34mj0b'},
                    {'type': 'huggingface', 'repo': 'wan-research/wan-loras', 'file': 'WAN_dr34mj0b.safetensors'}
                ]
            },
            'bounceV_01.safetensors': {
                'description': 'Bounce V01 LoRA',
                'strength': 1.0,
                'enabled': True,
                'sources': [
                    {'type': 'civitai', 'url': 'https://civitai.com/models/XXXXXX', 'search': 'bounceV 01'},
                    {'type': 'huggingface', 'repo': 'wan-research/wan-loras', 'file': 'bounceV_01.safetensors'}
                ]
            }
        }
    
    def check_existing_loras(self):
        """Check which LoRAs already exist and their sizes"""
        print("🔍 Checking existing LoRAs...")
        
        for lora_name, info in self.loras.items():
            filepath = self.lora_dir / lora_name
            
            if filepath.exists():
                size = filepath.stat().st_size
                if size > 1024:  # More than 1KB
                    print(f"✅ {lora_name} - {size:,} bytes")
                else:
                    print(f"⚠️  {lora_name} - {size} bytes (placeholder?)")
            else:
                print(f"❌ {lora_name} - Not found")
    
    def download_from_huggingface(self, repo_id, filename):
        """Download LoRA from Hugging Face Hub"""
        try:
            from huggingface_hub import hf_hub_download
            
            print(f"📥 Downloading {filename} from Hugging Face...")
            
            filepath = hf_hub_download(
                repo_id=repo_id,
                filename=filename,
                local_dir=str(self.lora_dir),
                local_dir_use_symlinks=False
            )
            
            print(f"✅ Downloaded {filename}")
            return True
            
        except ImportError:
            print("❌ huggingface_hub not installed. Install with: pip install huggingface_hub")
            return False
        except Exception as e:
            print(f"❌ Failed to download {filename}: {e}")
            return False
    
    def download_from_civitai(self, url, filename, headers=None):
        """Download LoRA from Civitai"""
        try:
            print(f"📥 Downloading {filename} from Civitai...")
            
            response = requests.get(url, stream=True, headers=headers)
            response.raise_for_status()
            
            filepath = self.lora_dir / filename
            total_size = int(response.headers.get('content-length', 0))
            
            with open(filepath, 'wb') as f, tqdm(
                desc=filename,
                total=total_size,
                unit='iB',
                unit_scale=True,
                unit_divisor=1024,
            ) as pbar:
                for chunk in response.iter_content(chunk_size=8192):
                    size = f.write(chunk)
                    pbar.update(size)
            
            print(f"✅ Downloaded {filename}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to download {filename}: {e}")
            return False
    
    def create_placeholder_loras(self):
        """Create placeholder LoRA files for testing"""
        print("🔧 Creating placeholder LoRA files for testing...")
        
        for lora_name, info in self.loras.items():
            filepath = self.lora_dir / lora_name
            
            if not filepath.exists() or filepath.stat().st_size < 1024:
                # Create a minimal safetensors file
                placeholder_data = {
                    "description": info['description'],
                    "strength": info['strength'],
                    "enabled": info['enabled'],
                    "placeholder": True,
                    "note": "This is a placeholder file. Download the real LoRA from Civitai."
                }
                
                with open(filepath, 'w') as f:
                    json.dump(placeholder_data, f, indent=2)
                
                print(f"📝 Created placeholder: {lora_name}")
    
    def generate_download_links(self):
        """Generate Civitai search links for manual downloads"""
        print("\n🔗 Civitai Search Links:")
        print("=" * 50)
        
        for lora_name, info in self.loras.items():
            print(f"\n📋 {lora_name}")
            print(f"   Description: {info['description']}")
            print(f"   Strength: {info['strength']}")
            print(f"   Status: {'✅ Enabled' if info['enabled'] else '❌ Disabled'}")
            
            for source in info['sources']:
                if source['type'] == 'civitai':
                    search_url = f"https://civitai.com/search?q={source['search']}"
                    print(f"   🔍 Search: {search_url}")
    
    def install_huggingface_hub(self):
        """Install huggingface_hub if not available"""
        try:
            import huggingface_hub
            return True
        except ImportError:
            print("📦 Installing huggingface_hub...")
            try:
                subprocess.run(['pip', 'install', 'huggingface_hub'], check=True)
                print("✅ huggingface_hub installed")
                return True
            except subprocess.CalledProcessError:
                print("❌ Failed to install huggingface_hub")
                return False
    
    def run(self):
        """Main execution"""
        print("🎭 WAN 2.1 LoRA Manager")
        print("=" * 50)
        
        # Check existing LoRAs
        self.check_existing_loras()
        
        # Install huggingface_hub if needed
        if not self.install_huggingface_hub():
            print("⚠️  Hugging Face downloads will be skipped")
        
        # Try downloading from Hugging Face first
        print("\n🚀 Attempting downloads from Hugging Face...")
        success_count = 0
        
        for lora_name, info in self.loras.items():
            filepath = self.lora_dir / lora_name
            
            # Skip if already exists and is valid
            if filepath.exists() and filepath.stat().st_size > 1024:
                print(f"⏭️  Skipping {lora_name} (already exists)")
                success_count += 1
                continue
            
            # Try Hugging Face first
            for source in info['sources']:
                if source['type'] == 'huggingface':
                    if self.download_from_huggingface(source['repo'], source['file']):
                        success_count += 1
                        break
        
        print(f"\n📊 Download Results: {success_count}/{len(self.loras)} LoRAs available")
        
        if success_count < len(self.loras):
            print("\n📖 Manual Download Required:")
            self.generate_download_links()
            
            print("\n🔧 Creating placeholder files for testing...")
            self.create_placeholder_loras()
        
        print(f"\n📁 LoRAs directory: {self.lora_dir}")
        print("🎉 LoRA management complete!")

if __name__ == "__main__":
    manager = LoRAManager()
    manager.run()
