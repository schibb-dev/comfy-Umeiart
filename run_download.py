#!/usr/bin/env python3
import subprocess
import os
import sys

def run_download_script():
    """Run the download script using subprocess"""
    
    script_path = "/home/yuji/Code/Umeiart/scripts/download_wan_models.sh"
    
    print(f"Running download script: {script_path}")
    print("Setting WAN_RES=720p to download 720p model...")
    
    # Set environment variable for 720p
    env = os.environ.copy()
    env['WAN_RES'] = '720p'
    
    try:
        # Run the script
        result = subprocess.run(
            ['bash', script_path],
            env=env,
            capture_output=True,
            text=True,
            cwd='/home/yuji/Code/Umeiart'
        )
        
        print("STDOUT:")
        print(result.stdout)
        
        if result.stderr:
            print("STDERR:")
            print(result.stderr)
        
        print(f"Return code: {result.returncode}")
        
        if result.returncode == 0:
            print("✅ Download script completed successfully!")
        else:
            print("❌ Download script failed!")
            
    except Exception as e:
        print(f"Error running script: {e}")

if __name__ == "__main__":
    run_download_script()

