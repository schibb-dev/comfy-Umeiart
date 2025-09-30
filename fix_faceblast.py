#!/usr/bin/env python3
import json
import sys

def fix_faceblast_workflow():
    """Fix the FaceBlast workflow issues"""
    
    # Read the workflow file
    with open('/home/yuji/Code/Umeiart/ComfyUI/workflows/FaceBlast.json', 'r') as f:
        workflow = json.load(f)
    
    print("Original workflow loaded successfully")
    
    # Find and fix the UnetLoaderGGUFDisTorchMultiGPU node (ID 458)
    for node in workflow['nodes']:
        if node['id'] == 458 and node['type'] == 'UnetLoaderGGUFDisTorchMultiGPU':
            print(f"Found UnetLoaderGGUFDisTorchMultiGPU node {node['id']}")
            print(f"Current widgets_values: {node['widgets_values']}")
            
            # Update the model name to use the available 480p model
            if len(node['widgets_values']) > 0:
                node['widgets_values'][0] = "wan2.1-i2v-14b-480p-Q5_K_M.gguf"
                print(f"Updated model name to: {node['widgets_values'][0]}")
    
    # Find and fix any FLOAT to INT type mismatches
    # Look for nodes that output FLOAT but should output INT
    float_to_int_fixes = [
        # Size sliders should output INT
        (83, 'mxSlider2D', 'value_x', 'INT'),
        (83, 'mxSlider2D', 'value_y', 'INT'),
        # Steps slider should output INT  
        (82, 'mxSlider', 'value', 'INT'),
    ]
    
    for node_id, node_type, output_name, new_type in float_to_int_fixes:
        for node in workflow['nodes']:
            if node['id'] == node_id and node['type'] == node_type:
                print(f"Found {node_type} node {node_id}")
                if 'outputs' in node:
                    for output in node['outputs']:
                        if output['name'] == output_name:
                            print(f"Changing {output_name} output type from {output['type']} to {new_type}")
                            output['type'] = new_type
    
    # Write the fixed workflow back
    with open('/home/yuji/Code/Umeiart/ComfyUI/workflows/FaceBlast.json', 'w') as f:
        json.dump(workflow, f, separators=(',', ':'))
    
    print("Workflow fixed and saved successfully!")

if __name__ == "__main__":
    fix_faceblast_workflow()

