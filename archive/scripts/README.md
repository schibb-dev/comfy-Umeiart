# Archive Scripts

This directory contains one-off scripts and utilities that were created during development but are no longer needed for regular use.

## Scripts

### Helper Scripts
- `fetch_model_info.py` - Helper script to extract metadata from Civitai URLs
- `check_nsfw_alternatives.py` - Script to search for WAN 2.1 NSFW alternatives
- `search_wan21_nsfw.py` - Script to search for WAN 2.1 NSFW LoRAs
- `check_dr34mj0b_versions.py` - Script to check all versions of Dr34mj0b model

### Utility Scripts
- `rename_loras.py` - Script to rename LoRA files based on WAN version and modality (functionality now integrated into main downloader)

### Example Scripts
- `example_usage.sh` - Basic usage examples for the downloader
- `advanced_usage_examples.sh` - Advanced filtering examples with all options

## Current Status

All functionality from these scripts has been integrated into the main `civitai_lora_downloader.py` script with intelligent filtering and fallback logic. These scripts are kept for reference and potential future use.

## Main Scripts (in root directory)

- `civitai_lora_downloader.py` - Main downloader with intelligent filtering
- `run_workflow_*.py` - Workflow execution scripts
- `download_*.py` - Model download scripts
- `*.sh` - Shell scripts for various tasks

