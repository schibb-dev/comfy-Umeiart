#!/usr/bin/env python3
"""
Standalone script to rename LoRA files based on WAN version and modality detection
"""

import json
import os
import argparse
from pathlib import Path

def extract_wan_info(metadata):
    """Extract WAN version and modality from metadata for renaming."""
    base_model = metadata.get('base_model') or ''
    version_name = metadata.get('version_name') or ''
    model_name = metadata.get('model_name') or ''
    
    # Extract WAN version (e.g., "2.1", "2.2")
    # Prioritize model name over base model for version detection
    wan_version = None
    if 'wan video 14b i2v' in base_model.lower():
        wan_version = '21'  # WAN 2.1 I2V
    elif 'wan video 2.1' in base_model.lower():
        wan_version = '21'
    elif 'wan video 2.2' in base_model.lower():
        wan_version = '22'
    elif 'wan 2.1' in base_model.lower():
        wan_version = '21'
    elif 'wan 2.2' in base_model.lower():
        wan_version = '22'
    elif 'wan 14b' in base_model.lower() and 'i2v' in base_model.lower():
        wan_version = '21'  # WAN 2.1 I2V 14B
    elif 'wan 14b' in base_model.lower():
        wan_version = '22'  # WAN 2.2 T2V 14B
    elif 'wan' in model_name.lower() and '14b' in model_name.lower():
        wan_version = '21'  # Default 14B models to WAN 2.1
    elif 'wan 25' in model_name.lower():
        wan_version = '22'  # "WAN 25 Realistic" is actually WAN 2.2
    elif 'wan' in model_name.lower():
        # If it has "wan" in the name but no specific version, assume 21
        wan_version = '21'
    
    # Extract modality (I2V/T2V)
    modality = None
    if 'i2v' in version_name.lower() or 'i2v' in base_model.lower():
        modality = 'i2v'
    elif 't2v' in version_name.lower() or 't2v' in base_model.lower():
        modality = 't2v'
    elif 'i2v' in model_name.lower():
        modality = 'i2v'
    elif 't2v' in model_name.lower():
        modality = 't2v'
    elif 'wan video 14b i2v' in base_model.lower():
        modality = 'i2v'  # Explicit I2V detection
    elif 'wan video' in base_model.lower() and 't2v' in base_model.lower():
        modality = 't2v'  # Explicit T2V detection
    elif 'wan' in model_name.lower():
        # If it has "wan" in the name but no specific modality, assume i2v for 14B models
        if '14b' in base_model.lower() or '14b' in model_name.lower():
            modality = 'i2v'
        else:
            modality = 't2v'
    
    return wan_version, modality

def generate_new_filename(original_name, metadata):
    """Generate new filename with WAN version and modality prefix."""
    wan_version, modality = extract_wan_info(metadata)

    if wan_version and modality:
        # Remove .safetensors extension and any existing wan- prefix
        base_name = original_name.replace('.safetensors', '')
        if base_name.startswith('wan-'):
            # Extract the original name after wan-XX-modality-
            parts = base_name.split('-', 3)
            if len(parts) >= 4:
                base_name = parts[3]  # Get the original name part
            else:
                base_name = base_name.split('-', 2)[2] if len(base_name.split('-', 2)) > 2 else base_name
        
        # Create new name: wan-{version}-{modality}-{original}
        new_name = f"wan-{wan_version}-{modality}-{base_name}.safetensors"
        return new_name

    return original_name

def main():
    parser = argparse.ArgumentParser(
        description="Rename LoRA files based on WAN version and modality detection",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Use default ComfyUI directory
  python3 rename_loras.py
  
  # Specify ComfyUI directory
  python3 rename_loras.py --comfyui-dir /path/to/ComfyUI
  
  # Specify LoRA directory directly
  python3 rename_loras.py --lora-dir /path/to/ComfyUI/models/loras
        """
    )
    
    parser.add_argument(
        '--comfyui-dir', 
        type=str,
        help='Path to ComfyUI root directory (default: auto-detect)'
    )
    
    parser.add_argument(
        '--lora-dir',
        type=str,
        help='Path to LoRA directory directly (overrides --comfyui-dir)'
    )
    
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be renamed without actually renaming files'
    )
    
    args = parser.parse_args()
    
    # Determine LoRA directory
    if args.lora_dir:
        lora_dir = Path(args.lora_dir)
    elif args.comfyui_dir:
        lora_dir = Path(args.comfyui_dir) / "models" / "loras"
    else:
        # Auto-detect ComfyUI directory
        current_dir = Path.cwd()
        possible_paths = [
            current_dir / "ComfyUI" / "models" / "loras",
            current_dir.parent / "ComfyUI" / "models" / "loras",
            Path("/home/yuji/Code/Umeiart/ComfyUI/models/loras"),  # Default fallback
        ]
        
        for path in possible_paths:
            if path.exists():
                lora_dir = path
                print(f"🔍 Auto-detected LoRA directory: {lora_dir}")
                break
        else:
            print("❌ Could not auto-detect LoRA directory")
            print("💡 Please specify --comfyui-dir /path/to/ComfyUI or --lora-dir /path/to/loras")
            return
    
    # Validate LoRA directory
    if not lora_dir.exists():
        print(f"❌ LoRA directory does not exist: {lora_dir}")
        return
    
    print(f"📁 Using LoRA directory: {lora_dir}")
    
    if args.dry_run:
        print("🔍 DRY RUN MODE - No files will be renamed")
    
    # Find all .safetensors files
    renamed_count = 0
    safetensors_files = list(lora_dir.glob("*.safetensors"))
    
    for safetensors_file in safetensors_files:
        json_file = safetensors_file.with_suffix('.safetensors.json')
        
        if json_file.exists():
            try:
                with open(json_file, 'r') as f:
                    metadata = json.load(f)
                
                original_name = safetensors_file.name
                new_name = generate_new_filename(original_name, metadata)
                
                if new_name != original_name:
                    new_path = lora_dir / new_name
                    if not new_path.exists():
                        if args.dry_run:
                            print(f"Would rename: {original_name} → {new_name}")
                        else:
                            print(f"Renaming: {original_name} → {new_name}")
                            
                            # Rename the .safetensors file
                            safetensors_file.rename(new_path)
                            
                            # Rename the .json file
                            new_json_file = new_path.with_suffix('.safetensors.json')
                            json_file.rename(new_json_file)
                            
                            # Update metadata filename
                            metadata['filename'] = new_name
                            with open(new_json_file, 'w') as f:
                                json.dump(metadata, f, indent=2)
                            renamed_count += 1
                    else:
                        print(f"Skipping {original_name}: {new_name} already exists")
                else:
                    print(f"No rename needed for {original_name}")
                    
            except Exception as e:
                print(f"Error processing {safetensors_file}: {e}")
        else:
            print(f"No metadata file for {safetensors_file}")
    
    if not args.dry_run:
        print(f"\n✅ Renamed {renamed_count} files")
    else:
        print(f"\n🔍 Would rename {renamed_count} files")

if __name__ == "__main__":
    main()
