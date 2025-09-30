#!/usr/bin/env python3
"""
ComfyUI Workflow Runner
======================

Run ComfyUI workflows from the command line using the API.

Usage:
    python run_workflow.py <workflow_file> [options]

Examples:
    # Run FaceBlast workflow on GPU0 (default)
    python run_workflow.py workflows/FaceBlast.json
    
    # Run on GPU1
    python run_workflow.py workflows/FaceBlast.json --gpu 1
    
    # Run with custom parameters
    python run_workflow.py workflows/FaceBlast.json --duration 3.0 --steps 25
    
    # Run and wait for completion
    python run_workflow.py workflows/FaceBlast.json --wait
"""

import argparse
import json
import requests
import time
import sys
import os
from pathlib import Path

class ComfyUIWorkflowRunner:
    def __init__(self, gpu_id=0):
        self.gpu_id = gpu_id
        self.port = 8188 + gpu_id  # GPU0=8188, GPU1=8189
        self.base_url = f"http://localhost:{self.port}"
        
    def load_workflow(self, workflow_file):
        """Load workflow from JSON file and convert to ComfyUI API format"""
        try:
            with open(workflow_file, 'r') as f:
                workflow_data = json.load(f)
            
            # Convert from ComfyUI JSON format to API format
            return self.convert_to_api_format(workflow_data)
            
        except FileNotFoundError:
            print(f"❌ Error: Workflow file '{workflow_file}' not found")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"❌ Error: Invalid JSON in '{workflow_file}': {e}")
            sys.exit(1)
    
    def convert_to_api_format(self, workflow_data):
        """Convert ComfyUI JSON format to API format"""
        api_workflow = {}
        
        for node in workflow_data.get('nodes', []):
            node_id = str(node.get('id'))
            api_workflow[node_id] = {
                'class_type': node.get('class_type', node.get('type')),
                'inputs': {}
            }
            
            # Add widget values as inputs
            if 'widgets_values' in node and node['widgets_values']:
                # Map widget values to input names based on node type
                widget_values = node['widgets_values']
                class_type = node.get('class_type', node.get('type'))
                
                if class_type == 'LoadImage':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['image'] = widget_values[0]
                elif class_type == 'SaveImage':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['filename_prefix'] = widget_values[0]
                elif class_type == 'mxSlider':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['value'] = widget_values[0]
                elif class_type == 'mxSlider2D':
                    if len(widget_values) > 1:
                        api_workflow[node_id]['inputs']['value_x'] = widget_values[0]
                        api_workflow[node_id]['inputs']['value_y'] = widget_values[1]
                elif class_type == 'RandomNoise':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['noise_seed'] = widget_values[0]
                elif class_type == 'KSamplerSelect':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['sampler_name'] = widget_values[0]
                elif class_type == 'BasicScheduler':
                    if len(widget_values) > 1:
                        api_workflow[node_id]['inputs']['scheduler'] = widget_values[0]
                        api_workflow[node_id]['inputs']['steps'] = widget_values[1]
                        api_workflow[node_id]['inputs']['denoise'] = widget_values[2]
                elif class_type == 'VAELoader':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['vae_name'] = widget_values[0]
                elif class_type == 'CLIPVisionLoader':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['clip_name'] = widget_values[0]
                elif class_type == 'UpscaleModelLoader':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['model_name'] = widget_values[0]
                elif class_type == 'UnetLoaderGGUFDisTorchMultiGPU':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['model_name'] = widget_values[0]
                        api_workflow[node_id]['inputs']['device'] = widget_values[1]
                        api_workflow[node_id]['inputs']['max_model_len'] = widget_values[2]
                        api_workflow[node_id]['inputs']['force_cpu'] = widget_values[3]
                elif class_type == 'CLIPLoaderGGUFMultiGPU':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['model_name'] = widget_values[0]
                        api_workflow[node_id]['inputs']['model_type'] = widget_values[1]
                        api_workflow[node_id]['inputs']['device'] = widget_values[2]
                elif class_type == 'CLIPTextEncode':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['text'] = widget_values[0]
                elif class_type == 'CLIPVisionEncode':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['crop'] = widget_values[0]
                elif class_type == 'WanImageToVideo':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['width'] = widget_values[0]
                        api_workflow[node_id]['inputs']['height'] = widget_values[1]
                        api_workflow[node_id]['inputs']['length'] = widget_values[2]
                        api_workflow[node_id]['inputs']['batch_size'] = widget_values[3]
                elif class_type == 'VHS_VideoCombine':
                    if len(widget_values) > 0:
                        api_workflow[node_id]['inputs']['frame_rate'] = widget_values[0]
                        api_workflow[node_id]['inputs']['loop_count'] = widget_values[1]
                        api_workflow[node_id]['inputs']['filename_prefix'] = widget_values[2]
                        api_workflow[node_id]['inputs']['format'] = widget_values[3]
                        api_workflow[node_id]['inputs']['pingpong'] = widget_values[4]
                        api_workflow[node_id]['inputs']['save_output'] = widget_values[5]
                        api_workflow[node_id]['inputs']['pix_fmt'] = widget_values[6]
                        api_workflow[node_id]['inputs']['crf'] = widget_values[7]
                        api_workflow[node_id]['inputs']['save_metadata'] = widget_values[8]
                        api_workflow[node_id]['inputs']['trim_to_audio'] = widget_values[9]
            
            # Add link connections
            for link in workflow_data.get('links', []):
                link_id, source_node, source_slot, target_node, target_slot, link_type = link
                if str(target_node) == node_id:
                    api_workflow[node_id]['inputs'][f'input_{target_slot}'] = [str(source_node), source_slot]
        
        return api_workflow
    
    def modify_workflow(self, workflow, **kwargs):
        """Modify workflow parameters"""
        for node in workflow.get('nodes', []):
            # Modify duration (node 426)
            if node.get('id') == 426 and 'duration' in kwargs:
                node['widgets_values'] = [kwargs['duration']]
                print(f"✅ Duration set to {kwargs['duration']} seconds")
            
            # Modify steps (node 82)
            if node.get('id') == 82 and 'steps' in kwargs:
                node['widgets_values'] = [kwargs['steps']]
                print(f"✅ Steps set to {kwargs['steps']}")
            
            # Modify CFG (node 85)
            if node.get('id') == 85 and 'cfg' in kwargs:
                node['widgets_values'] = [kwargs['cfg']]
                print(f"✅ CFG set to {kwargs['cfg']}")
            
            # Modify image size (node 83)
            if node.get('id') == 83:
                if 'width' in kwargs:
                    node['widgets_values'][0] = kwargs['width']
                    print(f"✅ Width set to {kwargs['width']}")
                if 'height' in kwargs:
                    node['widgets_values'][1] = kwargs['height']
                    print(f"✅ Height set to {kwargs['height']}")
        
        return workflow
    
    def check_server_status(self):
        """Check if ComfyUI server is running"""
        try:
            response = requests.get(f"{self.base_url}/system_stats", timeout=5)
            return response.status_code == 200
        except requests.exceptions.RequestException:
            return False
    
    def run_workflow(self, workflow, wait=False):
        """Run workflow via ComfyUI API"""
        if not self.check_server_status():
            print(f"❌ Error: ComfyUI server not running on port {self.port}")
            print(f"   Make sure ComfyUI_GPU{self.gpu_id} is started")
            sys.exit(1)
        
        print(f"🚀 Running workflow on GPU{self.gpu_id} (port {self.port})")
        
        try:
            # Submit workflow
            response = requests.post(
                f"{self.base_url}/prompt",
                json={"prompt": workflow},
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
                    print("💡 Use --wait flag to wait for completion")
                    print(f"   Monitor progress at: {self.base_url}")
                
                return prompt_id
            else:
                print(f"❌ Error: Failed to submit workflow")
                print(f"   Status: {response.status_code}")
                print(f"   Response: {response.text}")
                sys.exit(1)
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Error: Failed to connect to ComfyUI server: {e}")
            sys.exit(1)
    
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
    parser.add_argument('--duration', type=float, 
                       help='Override video duration (seconds)')
    parser.add_argument('--steps', type=int, 
                       help='Override sampling steps')
    parser.add_argument('--cfg', type=float, 
                       help='Override CFG scale')
    parser.add_argument('--width', type=int, 
                       help='Override image width')
    parser.add_argument('--height', type=int, 
                       help='Override image height')
    
    args = parser.parse_args()
    
    # Check if workflow file exists
    if not os.path.exists(args.workflow_file):
        print(f"❌ Error: Workflow file '{args.workflow_file}' not found")
        sys.exit(1)
    
    # Create runner
    runner = ComfyUIWorkflowRunner(args.gpu)
    
    # Load workflow
    workflow = runner.load_workflow(args.workflow_file)
    
    # Modify workflow with custom parameters
    modifications = {}
    if args.duration is not None:
        modifications['duration'] = args.duration
    if args.steps is not None:
        modifications['steps'] = args.steps
    if args.cfg is not None:
        modifications['cfg'] = args.cfg
    if args.width is not None:
        modifications['width'] = args.width
    if args.height is not None:
        modifications['height'] = args.height
    
    if modifications:
        workflow = runner.modify_workflow(workflow, **modifications)
    
    # Run workflow
    prompt_id = runner.run_workflow(workflow, wait=args.wait)
    
    if not args.wait:
        print(f"\n🎬 Workflow is running!")
        print(f"   Monitor at: http://localhost:{8188 + args.gpu}")
        print(f"   Prompt ID: {prompt_id}")

if __name__ == "__main__":
    main()
