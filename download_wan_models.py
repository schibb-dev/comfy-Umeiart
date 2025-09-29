#!/usr/bin/env python3
"""
WAN 2.1 Model Downloader
Downloads WAN 2.1 models using Hugging Face Hub with proper authentication
"""

import os
import sys
import json
import logging
import time
from pathlib import Path
from huggingface_hub import hf_hub_download, login
from huggingface_hub.utils import HfHubHTTPError
from tqdm import tqdm

# ComfyUI paths
COMFYUI_DIR = Path("/home/yuji/Code/Umeiart/ComfyUI")
MODELS_DIR = COMFYUI_DIR / "models"
TOKEN_FILE = Path("/home/yuji/Code/Umeiart/.hf_token")

# Model configurations
MODELS = {
    "diffusion_pytorch_model.safetensors.index.json": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "diffusion_pytorch_model.safetensors.index.json",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    "diffusion_pytorch_model-00001-of-00007.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "diffusion_pytorch_model-00001-of-00007.safetensors",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    "diffusion_pytorch_model-00002-of-00007.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "diffusion_pytorch_model-00002-of-00007.safetensors",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    "diffusion_pytorch_model-00003-of-00007.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "diffusion_pytorch_model-00003-of-00007.safetensors",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    "diffusion_pytorch_model-00004-of-00007.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "diffusion_pytorch_model-00004-of-00007.safetensors",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    "diffusion_pytorch_model-00005-of-00007.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "diffusion_pytorch_model-00005-of-00007.safetensors",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    "diffusion_pytorch_model-00006-of-00007.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "diffusion_pytorch_model-00006-of-00007.safetensors",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    "diffusion_pytorch_model-00007-of-00007.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "diffusion_pytorch_model-00007-of-00007.safetensors",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    "models_t5_umt5-xxl-enc-bf16.pth": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "models_t5_umt5-xxl-enc-bf16.pth",
        "dest_dir": MODELS_DIR / "clip"
    },
    "models_clip_open-clip-xlm-roberta-large-vit-huge-14.pth": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "models_clip_open-clip-xlm-roberta-large-vit-huge-14.pth",
        "dest_dir": MODELS_DIR / "clip_vision"
    },
    "google/umt5-xxl/special_tokens_map.json": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "google/umt5-xxl/special_tokens_map.json",
        "dest_dir": MODELS_DIR / "clip"
    },
    "google/umt5-xxl/spiece.model": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "google/umt5-xxl/spiece.model",
        "dest_dir": MODELS_DIR / "clip"
    },
    "google/umt5-xxl/tokenizer.json": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "google/umt5-xxl/tokenizer.json",
        "dest_dir": MODELS_DIR / "clip"
    },
    "google/umt5-xxl/tokenizer_config.json": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "google/umt5-xxl/tokenizer_config.json",
        "dest_dir": MODELS_DIR / "clip"
    },
    "xlm-roberta-large/sentencepiece.bpe.model": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "xlm-roberta-large/sentencepiece.bpe.model",
        "dest_dir": MODELS_DIR / "clip_vision"
    },
    "xlm-roberta-large/special_tokens_map.json": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "xlm-roberta-large/special_tokens_map.json",
        "dest_dir": MODELS_DIR / "clip_vision"
    },
    "xlm-roberta-large/tokenizer.json": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "xlm-roberta-large/tokenizer.json",
        "dest_dir": MODELS_DIR / "clip_vision"
    },
    "xlm-roberta-large/tokenizer_config.json": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "xlm-roberta-large/tokenizer_config.json",
        "dest_dir": MODELS_DIR / "clip_vision"
    },
    "config.json": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "config.json",
        "dest_dir": MODELS_DIR / "diffusion_models"
    }
}

def setup_logging():
    """Setup logging configuration"""
    log_file = Path("/home/yuji/Code/Umeiart/wan_download.log")
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # Setup file handler
    file_handler = logging.FileHandler(log_file)
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)
    
    # Setup console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    
    # Setup logger
    logger = logging.getLogger('wan_downloader')
    logger.setLevel(logging.DEBUG)
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger

def load_token():
    """Load saved Hugging Face token"""
    if TOKEN_FILE.exists():
        try:
            with open(TOKEN_FILE, 'r') as f:
                token_data = json.load(f)
                return token_data.get('hf_token')
        except (json.JSONDecodeError, KeyError):
            print("⚠️  Invalid token file format. Will create new one.")
    return None

def save_token(token):
    """Save Hugging Face token to file"""
    try:
        token_data = {"hf_token": token}
        with open(TOKEN_FILE, 'w') as f:
            json.dump(token_data, f, indent=2)
        # Set secure permissions
        os.chmod(TOKEN_FILE, 0o600)
        print(f"✅ Token saved to {TOKEN_FILE}")
    except Exception as e:
        print(f"⚠️  Could not save token: {e}")

def setup_directories():
    """Create necessary directories"""
    print("📁 Creating model directories...")
    for model_info in MODELS.values():
        model_info["dest_dir"].mkdir(parents=True, exist_ok=True)
        print(f"  ✅ {model_info['dest_dir']}")

def authenticate():
    """Authenticate with Hugging Face"""
    print("🔐 Hugging Face Authentication")
    print("=" * 40)
    
    # Try to load saved token first
    token = load_token()
    
    if token:
        print("🔑 Found saved token, testing authentication...")
        try:
            login(token=token)
            print("✅ Authentication successful with saved token!")
            return token
        except Exception as e:
            print(f"❌ Saved token failed: {e}")
            print("Please provide a new token.")
    
    # Try to get token from environment variable
    token = os.getenv('HF_TOKEN')
    if token:
        print("🔑 Found token in environment variable, testing authentication...")
        try:
            login(token=token)
            print("✅ Authentication successful with environment token!")
            save_token(token)  # Save it for future use
            return token
        except Exception as e:
            print(f"❌ Environment token failed: {e}")
    
    # Try to get token from command line argument
    if len(sys.argv) > 1:
        token = sys.argv[1]
        print("🔑 Using token from command line argument...")
        try:
            login(token=token)
            print("✅ Authentication successful with command line token!")
            save_token(token)  # Save it for future use
            return token
        except Exception as e:
            print(f"❌ Command line token failed: {e}")
    
    print("You need a Hugging Face account and access token.")
    print("1. Go to: https://huggingface.co/settings/tokens")
    print("2. Create a new token (read access)")
    print("3. Use one of these methods:")
    print("   • Set environment variable: export HF_TOKEN=your_token")
    print("   • Pass as argument: ./download_wan_models.py your_token")
    print("   • Enter interactively (if terminal supports it)")
    print()
    
    try:
        token = input("Enter your Hugging Face token: ").strip()
        
        if not token:
            print("❌ No token provided. Exiting.")
            sys.exit(1)
        
        login(token=token)
        print("✅ Authentication successful!")
        
        # Ask if user wants to save the token
        save_choice = input("💾 Save this token for future use? (y/n): ").strip().lower()
        if save_choice in ['y', 'yes']:
            save_token(token)
        
        return token
    except EOFError:
        print("❌ Cannot read input interactively.")
        print("Please use: export HF_TOKEN=your_token")
        print("Or: ./download_wan_models.py your_token")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Authentication failed: {e}")
        sys.exit(1)

def download_model(model_name, model_info, token, logger):
    """Download a single model"""
    logger.info(f"Starting download: {model_name}")
    logger.debug(f"Repository: {model_info['repo_id']}")
    logger.debug(f"Filename: {model_info['filename']}")
    logger.debug(f"Destination: {model_info['dest_dir']}")
    
    dest_path = model_info["dest_dir"] / model_name
    
    # Check if file already exists and has reasonable size
    if dest_path.exists() and dest_path.stat().st_size > 1000:
        logger.info(f"File already exists: {model_name} ({dest_path.stat().st_size:,} bytes)")
        return True
    
    start_time = time.time()
    
    try:
        # Download the file with progress reporting
        downloaded_path = hf_hub_download(
            repo_id=model_info["repo_id"],
            filename=model_info["filename"],
            token=token,
            local_dir=model_info["dest_dir"],
            local_dir_use_symlinks=False,
            resume_download=True,  # Resume interrupted downloads
            force_download=False,  # Don't re-download existing files
        )
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Verify download
        if os.path.exists(downloaded_path):
            file_size = os.path.getsize(downloaded_path)
            file_size_mb = file_size / (1024 * 1024)
            
            logger.info(f"Successfully downloaded: {model_name}")
            logger.info(f"File size: {file_size_mb:.2f} MB")
            logger.info(f"Download time: {duration:.2f} seconds")
            logger.debug(f"Full path: {downloaded_path}")
            
            return True
        else:
            logger.error(f"Download verification failed: {model_name}")
            return False
            
    except Exception as e:
        end_time = time.time()
        duration = end_time - start_time
        
        logger.error(f"Failed to download {model_name}: {e}")
        logger.error(f"Failed after: {duration:.2f} seconds")
        logger.debug(f"Exception details: {type(e).__name__}: {str(e)}")
        return False

def main():
    """Main function"""
    # Setup logging
    logger = setup_logging()
    
    # Set environment variables for better download performance
    os.environ.setdefault('HF_HUB_DOWNLOAD_TIMEOUT', '300')  # 5 minutes timeout
    os.environ.setdefault('HF_HUB_CACHE', str(COMFYUI_DIR / ".cache" / "huggingface"))
    
    logger.info("=" * 60)
    logger.info("WAN 2.1 Model Downloader Started")
    logger.info("=" * 60)
    logger.info(f"Download timeout: {os.environ.get('HF_HUB_DOWNLOAD_TIMEOUT', 'default')} seconds")
    logger.info(f"Cache directory: {os.environ.get('HF_HUB_CACHE', 'default')}")
    
    start_time = time.time()
    
    try:
        # Setup directories
        logger.info("Setting up model directories...")
        setup_directories()
        
        # Authenticate
        logger.info("Starting authentication process...")
        token = authenticate()
        logger.info("Authentication successful")
        
        # Download models with progress bar
        logger.info("Starting model downloads...")
        logger.info(f"Total models to download: {len(MODELS)}")
        
        success_count = 0
        total_count = len(MODELS)
        failed_models = []
        
        # Create progress bar for overall progress
        with tqdm(total=total_count, desc="Downloading WAN models", unit="model") as pbar:
            for i, (model_name, model_info) in enumerate(MODELS.items(), 1):
                logger.info(f"Progress: {i}/{total_count} - {model_name}")
                
                if download_model(model_name, model_info, token, logger):
                    success_count += 1
                    pbar.set_postfix({"Success": f"{success_count}/{total_count}"})
                else:
                    failed_models.append(model_name)
                    pbar.set_postfix({"Failed": f"{len(failed_models)}"})
                
                pbar.update(1)
        
        # Summary
        end_time = time.time()
        total_duration = end_time - start_time
        
        logger.info("=" * 40)
        logger.info("DOWNLOAD SUMMARY")
        logger.info("=" * 40)
        logger.info(f"Successfully downloaded: {success_count}/{total_count} models")
        logger.info(f"Total time: {total_duration:.2f} seconds")
        
        if success_count == total_count:
            logger.info("🎉 All WAN 2.1 models downloaded successfully!")
            logger.info("Next steps:")
            logger.info("1. Restart ComfyUI")
            logger.info("2. Load the WAN_2.1_IMG_to_VIDEO.json workflow")
            logger.info("3. Start creating videos!")
        else:
            logger.warning(f"⚠️  {len(failed_models)} models failed to download:")
            for model in failed_models:
                logger.warning(f"  - {model}")
            logger.warning("Check the error messages above and try again.")
            
    except Exception as e:
        logger.error(f"Fatal error in main(): {e}")
        logger.error(f"Exception type: {type(e).__name__}")
        logger.debug(f"Full traceback:", exc_info=True)
        sys.exit(1)
    
    finally:
        logger.info("=" * 60)
        logger.info("WAN 2.1 Model Downloader Finished")
        logger.info("=" * 60)

if __name__ == "__main__":
    main()
