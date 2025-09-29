#!/usr/bin/env python3
"""
Download WAN 2.1 models as specified in the Civitai guide
https://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video
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

# Model configurations as per Civitai guide
MODELS = {
    # I2V Model (720p version as recommended)
    "wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "wan2.1_i2v_720p_14B_fp8_e4m3fn.safetensors",
        "dest_dir": MODELS_DIR / "diffusion_models"
    },
    
    # CLIP Model
    "umt5_xxl_fp8_e4m3fn_scaled.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P", 
        "filename": "umt5_xxl_fp8_e4m3fn_scaled.safetensors",
        "dest_dir": MODELS_DIR / "clip"
    },
    
    # CLIP-VISION Model
    "clip_vision_h.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "clip_vision_h.safetensors", 
        "dest_dir": MODELS_DIR / "clip_vision"
    },
    
    # VAE Model
    "wan_2.1_vae.safetensors": {
        "repo_id": "Wan-AI/Wan2.1-I2V-14B-720P",
        "filename": "wan_2.1_vae.safetensors",
        "dest_dir": MODELS_DIR / "vae"
    }
}

def setup_logging():
    """Setup logging configuration"""
    log_file = Path("/home/yuji/Code/Umeiart/wan_civitai_download.log")
    
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
    logger = logging.getLogger('wan_civitai_downloader')
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
            return token_data.get("hf_token")
        except json.JSONDecodeError:
            return None
    return None

def setup_directories(logger):
    """Create necessary model directories"""
    for model_name, model_info in MODELS.items():
        model_info["dest_dir"].mkdir(parents=True, exist_ok=True)
        logger.debug(f"Ensured directory exists: {model_info['dest_dir']}")

def authenticate(logger):
    """Authenticate with Hugging Face"""
    logger.info("🔐 Hugging Face Authentication")
    
    # Try to load saved token first
    token = load_token()
    
    if token:
        logger.info("🔑 Found saved token, testing authentication...")
        try:
            login(token=token)
            logger.info("✅ Authentication successful with saved token!")
            return token
        except Exception as e:
            logger.warning(f"❌ Saved token failed: {e}")
    
    logger.error("❌ No valid token found. Please run the original download script first.")
    sys.exit(1)

def download_model(model_name, model_info, token, logger):
    """Download a single model"""
    logger.info(f"Starting download: {model_name}")
    logger.debug(f"Repository: {model_info['repo_id']}")
    logger.debug(f"Filename: {model_info['filename']}")
    logger.debug(f"Destination: {model_info['dest_dir']}")
    
    dest_path = model_info["dest_dir"] / model_info["filename"]
    
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
            resume_download=True,
            force_download=False,
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
    os.environ.setdefault('HF_HUB_DOWNLOAD_TIMEOUT', '300')
    os.environ.setdefault('HF_HUB_CACHE', str(COMFYUI_DIR / ".cache" / "huggingface"))
    
    logger.info("=" * 60)
    logger.info("WAN 2.1 Civitai Guide Model Downloader Started")
    logger.info("=" * 60)
    logger.info("Based on: https://civitai.com/articles/13389/step-by-step-guide-series-comfyui-img-to-video")
    
    start_time = time.time()
    
    try:
        # Setup directories
        logger.info("Setting up model directories...")
        setup_directories(logger)
        
        # Authenticate
        logger.info("Starting authentication process...")
        token = authenticate(logger)
        logger.info("Authentication successful")
        
        # Download models with progress bar
        logger.info("Starting model downloads...")
        logger.info(f"Total models to download: {len(MODELS)}")
        
        success_count = 0
        total_count = len(MODELS)
        failed_models = []
        
        # Create progress bar for overall progress
        with tqdm(total=total_count, desc="Downloading WAN Civitai models", unit="model") as pbar:
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
            logger.info("🎉 All WAN 2.1 Civitai models downloaded successfully!")
            logger.info("Next steps:")
            logger.info("1. Restart ComfyUI")
            logger.info("2. Load the proper WAN workflow from Civitai")
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
        logger.info("WAN 2.1 Civitai Guide Model Downloader Finished")
        logger.info("=" * 60)

if __name__ == "__main__":
    main()
