#!/usr/bin/env python3
"""
Helper script to fetch Civitai model metadata from URL
"""

import requests
import json
import sys
from urllib.parse import urlparse, parse_qs

def fetch_model_info(url):
    """Fetch model metadata from Civitai URL"""
    try:
        # Parse URL to extract model_id and version_id
        parsed = urlparse(url)
        path_parts = parsed.path.strip('/').split('/')
        
        if 'models' not in path_parts:
            print("❌ Invalid Civitai model URL")
            return None
            
        model_id = None
        version_id = None
        
        # Extract model ID from path
        for i, part in enumerate(path_parts):
            if part == 'models' and i + 1 < len(path_parts):
                model_id = path_parts[i + 1]
                break
        
        # Extract version ID from query params
        query_params = parse_qs(parsed.query)
        if 'modelVersionId' in query_params:
            version_id = query_params['modelVersionId'][0]
        
        if not model_id:
            print("❌ Could not extract model ID from URL")
            return None
            
        print(f"🔍 Fetching metadata for model {model_id}...")
        if version_id:
            print(f"🎯 Target version: {version_id}")
        
        # Get model info
        model_url = f'https://civitai.com/api/v1/models/{model_id}'
        response = requests.get(model_url)
        
        if response.status_code != 200:
            print(f"❌ Error fetching model: {response.status_code}")
            return None
            
        model_data = response.json()
        
        print(f"\n=== MODEL INFO ===")
        print(f"Model ID: {model_data['id']}")
        print(f"Name: {model_data['name']}")
        description = model_data.get('description', 'No description')
        print(f"Description: {description[:100]}...")
        
        # Find the specific version
        target_version = None
        if version_id:
            for version in model_data.get('modelVersions', []):
                if str(version['id']) == version_id:
                    target_version = version
                    break
        
        if target_version:
            print(f"\n=== VERSION INFO ===")
            print(f"Version ID: {target_version['id']}")
            print(f"Version Name: {target_version.get('name', 'No name')}")
            print(f"Base Model: {target_version.get('baseModel', 'Unknown')}")
            
            # Find the .safetensors file
            safetensors_file = None
            for file in target_version.get('files', []):
                if file.get('name', '').endswith('.safetensors'):
                    safetensors_file = file
                    break
            
            if safetensors_file:
                print(f"\n=== FILE INFO ===")
                print(f"File ID: {safetensors_file['id']}")
                print(f"File Name: {safetensors_file['name']}")
                size_mb = safetensors_file.get('sizeKB', 0) / 1024
                print(f"File Size: {size_mb:.1f} MB")
                
                # Generate script entry
                print(f"\n=== SCRIPT ENTRY ===")
                print(f"'{safetensors_file['name']}': {{")
                print(f"    'description': '{model_data['name']}',")
                print(f"    'strength': 1.0,")
                print(f"    'enabled': True,")
                print(f"    'search_terms': ['{model_data['name'].lower()}', 'wan cumshot'],")
                print(f"    'civitai_id': '{model_data['id']}',")
                print(f"    'version_id': {target_version['id']},")
                print(f"    'file_id': {safetensors_file['id']},")
                print(f"    'priority': 1")
                print(f"}},")
                
                return {
                    'model_id': model_data['id'],
                    'version_id': target_version['id'],
                    'file_id': safetensors_file['id'],
                    'filename': safetensors_file['name'],
                    'model_name': model_data['name'],
                    'base_model': target_version.get('baseModel', 'Unknown')
                }
            else:
                print("❌ No .safetensors file found in this version")
        else:
            print(f"❌ Version {version_id} not found")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 fetch_model_info.py <civitai_url>")
        sys.exit(1)
    
    url = sys.argv[1]
    result = fetch_model_info(url)
    
    if result:
        print(f"\n✅ Successfully extracted metadata!")
    else:
        print(f"\n❌ Failed to extract metadata")
