#!/usr/bin/env python3
"""
Search for WAN 2.1 NSFW LoRAs
"""

import requests
import json

def search_wan21_nsfw():
    """Search for WAN 2.1 NSFW LoRAs"""
    print('🔍 Searching for WAN 2.1 NSFW LoRAs...')
    url = 'https://civitai.com/api/v1/models?query=wan video 14b&types=LORA&limit=20'
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        items = data.get('items', [])
        
        print(f'Found {len(items)} models with "wan video 14b"')
        print('\nWAN 2.1 Compatible LoRAs:')
        
        for item in items:
            name = item['name']
            model_id = item['id']
            
            # Check if it might be NSFW or enhancement related
            if any(keyword in name.lower() for keyword in ['nsfw', 'enhancement', 'realistic', 'adult', 'sexy']):
                print(f'\n📋 {name}')
                print(f'    ID: {model_id}')
                
                # Check versions for WAN 2.1
                for version in item.get('modelVersions', [])[:2]:
                    base_model = version.get('baseModel', 'Unknown')
                    if 'wan video 14b' in base_model.lower():
                        print(f'    ✅ WAN 2.1: {version.get("name", "No name")}')
                        print(f'        Base: {base_model}')
                        break
    else:
        print(f'Error: {response.status_code}')

if __name__ == "__main__":
    search_wan21_nsfw()
