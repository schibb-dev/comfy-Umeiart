#!/usr/bin/env python3
"""
ComfyUI Workflow Runner - Final Version
======================================

This script runs ComfyUI workflows from the command line.
It handles the conversion from ComfyUI JSON format to API format.

Usage: python run_workflow_final.py <workflow_file> [gpu_id] [options]
"""

import sys
import json
import requests
import time
import argparse

class ComfyUIWorkflowRunner:
    def __init__(self, gpu_id=0):
        self.gpu_id = gpu_id
        self.port = 8188 + gpu_id
        self.base_url = f"http://localhost:{self.port}"
        
    def check_server(self):
        """Check if ComfyUI server is running"""
        try:
            response = requests.get(f"{self.base_url}/system_stats", timeout=5)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def load_and_convert_workflow(self, workflow_file):
        """Load workflow and convert to API format"""
        try:
            with open(workflow_file, 'r') as f:
                original_workflow = json.load(f)
        except FileNotFoundError:
            print(f"❌ Error: Workflow file '{workflow_file}' not found")
            return None
        except json.JSONDecodeError as e:
            print(f"❌ Error: Invalid JSON: {e}")
            return None
        
        # Convert to API format
        api_workflow = {}
        
        for node in original_workflow.get('nodes', []):
            node_id = str(node.get('id'))
            class_type = node.get('class_type', node.get('type'))
            
            api_workflow[node_id] = {
                'class_type': class_type,
                'inputs': {}
            }
            
            # Add widget values
            if 'widgets_values' in node and node['widgets_values']:
                self._add_widget_values(api_workflow[node_id], node)
        
        # Add connections
        self._add_connections(api_workflow, original_workflow)
        
        return api_workflow
    
    def _add_widget_values(self, api_node, original_node):
        """Add widget values to API node"""
        widget_values = original_node['widgets_values']
        class_type = original_node.get('class_type', original_node.get('type'))
        
        # Map widget values to input names
        mappings = {
            'LoadImage': {'image': 0},
            'SaveImage': {'filename_prefix': 0},
            'mxSlider': {'value': 0},
            'mxSlider2D': {'value_x': 0, 'value_y': 1},
            'RandomNoise': {'noise_seed': 0},
            'KSamplerSelect': {'sampler_name': 0},
            'BasicScheduler': {'scheduler': 0, 'steps': 1, 'denoise': 2},
            'VAELoader': {'vae_name': 0},
            'CLIPVisionLoader': {'clip_name': 0},
            'UpscaleModelLoader': {'model_name': 0},
            'UnetLoaderGGUFDisTorchMultiGPU': {'model_name': 0, 'device': 1, 'max_model_len': 2, 'force_cpu': 3},
            'CLIPLoaderGGUFMultiGPU': {'model_name': 0, 'model_type': 1, 'device': 2},
            'CLIPTextEncode': {'text': 0},
            'CLIPVisionEncode': {'crop': 0},
            'WanImageToVideo': {'width': 0, 'height': 1, 'length': 2, 'batch_size': 3},
        }
        
        if class_type in mappings:
            for input_name, index in mappings[class_type].items():
                if index < len(widget_values):
                    api_node['inputs'][input_name] = widget_values[index]
        elif class_type == 'VHS_VideoCombine':
            # Handle complex VHS_VideoCombine structure
            if isinstance(widget_values, dict):
                for key, value in widget_values.items():
                    api_node['inputs'][key] = value
    
    def _add_connections(self, api_workflow, original_workflow):
        """Add node connections"""
        for link in original_workflow.get('links', []):
            link_id, source_node, source_slot, target_node, target_slot, link_type = link
            target_node_id = str(target_node)
            
            if target_node_id in api_workflow:
                api_workflow[target_node_id]['inputs'][f'input_{target_slot}'] = [str(source_node), source_slot]
    
    def run_workflow(self, workflow_file, wait=False):
        """Run workflow"""
        if not self.check_server():
            print(f"❌ Error: ComfyUI not running on port {self.port}")
            print(f"   Make sure ComfyUI_GPU{self.gpu_id} is started")
            return False
        
        print(f"🚀 Running workflow on GPU{self.gpu_id} (port {self.port})")
        
        # Load and convert workflow
        api_workflow = self.load_and_convert_workflow(workflow_file)
        if not api_workflow:
            return False
        
        # Submit workflow
        try:
            response = requests.post(
                f"{self.base_url}/prompt",
                json={"prompt": api_workflow},
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                prompt_id = result.get('prompt_id')
                print(f"✅ Workflow submitted successfully!")
                print(f"   Prompt ID: {prompt_id}")
                
                if wait:
                    print("⏳ Waiting for completion...")
                    self.wait_for_completion(prompt_id)
                else:
                    print(f"   Monitor at: {self.base_url}")
                
                return True
            else:
                print(f"❌ Error: Failed to submit workflow")
                print(f"   Status: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Error: Failed to submit workflow: {e}")
            return False
    
    def wait_for_completion(self, prompt_id, check_interval=5):
        """Wait for workflow completion"""
        start_time = time.time()
        
        while True:
            try:
                response = requests.get(f"{self.base_url}/history/{prompt_id}")
                if response.status_code == 200:
                    history = response.json()
                    if prompt_id in history:
                        status = history[prompt_id].get('status', {})
                        if status.get('status_str') == 'success':
                            elapsed = time.time() - start_time
                            print(f"✅ Workflow completed successfully in {elapsed:.1f} seconds!")
                            return True
                        elif status.get('status_str') == 'error':
                            print(f"❌ Workflow failed: {status.get('message', 'Unknown error')}")
                            return False
                
                print(f"⏳ Still processing... ({time.time() - start_time:.1f}s)")
                time.sleep(check_interval)
                
            except requests.exceptions.RequestException as e:
                print(f"❌ Error checking status: {e}")
                return False

def main():
    parser = argparse.ArgumentParser(description='Run ComfyUI workflows from command line')
    parser.add_argument('workflow_file', help='Path to workflow JSON file')
    parser.add_argument('--gpu', type=int, choices=[0, 1], default=0, 
                       help='GPU to use (0 or 1, default: 0)')
    parser.add_argument('--wait', action='store_true', 
                       help='Wait for workflow completion')
    
    args = parser.parse_args()
    
    runner = ComfyUIWorkflowRunner(args.gpu)
    success = runner.run_workflow(args.workflow_file, wait=args.wait)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
