#!/usr/bin/env python3
"""
Simple ComfyUI Workflow Runner
=============================

Usage: python run_workflow_simple.py <workflow_file> [gpu_id]
"""

import sys
import json
import requests
import time

def run_workflow(workflow_file, gpu_id=0):
    port = 8188 + gpu_id
    base_url = f"http://localhost:{port}"
    
    print(f"🚀 Running workflow: {workflow_file}")
    print(f"   GPU: {gpu_id} (port {port})")
    print("")
    
    # Check if ComfyUI is running
    try:
        response = requests.get(f"{base_url}/system_stats", timeout=5)
        if response.status_code != 200:
            print(f"❌ Error: ComfyUI not running on port {port}")
            return False
    except requests.exceptions.RequestException:
        print(f"❌ Error: Cannot connect to ComfyUI on port {port}")
        return False
    
    # Load workflow
    try:
        with open(workflow_file, 'r') as f:
            workflow = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: Workflow file '{workflow_file}' not found")
        return False
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON: {e}")
        return False
    
    # Submit workflow
    print("📤 Submitting workflow...")
    try:
        response = requests.post(
            f"{base_url}/prompt",
            json={"prompt": workflow},
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            prompt_id = result.get('prompt_id')
            print(f"✅ Workflow submitted successfully!")
            print(f"   Prompt ID: {prompt_id}")
            print(f"   Monitor at: {base_url}")
            return True
        else:
            print(f"❌ Error: Failed to submit workflow")
            print(f"   Status: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Error: Failed to submit workflow: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python run_workflow_simple.py <workflow_file> [gpu_id]")
        sys.exit(1)
    
    workflow_file = sys.argv[1]
    gpu_id = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    
    success = run_workflow(workflow_file, gpu_id)
    sys.exit(0 if success else 1)
