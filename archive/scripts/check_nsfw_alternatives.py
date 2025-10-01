#!/usr/bin/env python3
"""
Check current NSFW E14 model and search for WAN 2.1 alternatives
"""

import requests
import json

def check_current_model():
    """Check the current WAN 25 Realistic model"""
    print('🔍 Checking current WAN 25 Realistic model...')
    url = 'https://civitai.com/api/v1/models/2001317'
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        print(f'Name: {data["name"]}')
        description = data.get('description', 'No description')
        print(f'Description: {description[:150]}...')
        
        print('\nVersions:')
        for version in data.get('modelVersions', []):
            print(f'  - {version.get("name", "No name")} (ID: {version["id"]})')
            print(f'    Base Model: {version.get("baseModel", "Unknown")}')
            print()
    else:
        print(f'Error: {response.status_code}')

def search_wan21_alternatives():
    """Search for WAN 2.1 compatible NSFW enhancement LoRAs"""
    print('\n' + '=' * 60)
    print('🔍 Searching for WAN 2.1 NSFW enhancement alternatives...')
    
    search_terms = [
        'wan video 14b enhancement',
        'wan i2v enhancement', 
        'wan 2.1 enhancement',
        'wan video enhancement',
        'wan 14b nsfw'
    ]

    for term in search_terms:
        print(f'\n🔎 Searching: "{term}"')
        try:
            url = f'https://civitai.com/api/v1/models?query={term}&types=LORA&limit=5'
            response = requests.get(url)
            
            if response.status_code == 200:
                data = response.json()
                items = data.get('items', [])
                
                for item in items:
                    model_id = item['id']
                    name = item['name']
                    
                    # Skip the current model
                    if str(model_id) == '2001317':
                        continue
                        
                    print(f'  📋 Model: {name}')
                    print(f'      ID: {model_id}')
                    
                    # Check versions
                    for version in item.get('modelVersions', [])[:2]:
                        version_name = version.get('name', 'No name')
                        base_model = version.get('baseModel', 'Unknown')
                        
                        if 'wan video 14b' in base_model.lower():
                            print(f'      ✅ WAN 2.1 Compatible: {version_name}')
                            print(f'          Base Model: {base_model}')
                            print(f'          Version ID: {version["id"]}')
                            
                            # Find .safetensors file
                            for file in version.get('files', []):
                                if file.get('name', '').endswith('.safetensors'):
                                    print(f'          File: {file["name"]} ({file.get("sizeKB", 0) / 1024:.1f} MB)')
                                    print(f'          File ID: {file["id"]}')
                                    break
                            print()
            else:
                print(f'  ❌ API Error: {response.status_code}')
                
        except Exception as e:
            print(f'  ❌ Error: {e}')

if __name__ == "__main__":
    check_current_model()
    search_wan21_alternatives()
