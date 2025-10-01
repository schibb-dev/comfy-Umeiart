#!/usr/bin/env python3
"""
Check all versions of Dr34mj0b model for WAN 2.1 I2V compatibility
"""

import requests
import json

def check_dr34mj0b_versions():
    """Check all versions of the Dr34mj0b model"""
    model_id = '1395313'
    print(f'🔍 Checking all versions of model {model_id}...')

    url = f'https://civitai.com/api/v1/models/{model_id}'
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        print(f'\nModel: {data["name"]}')
        description = data.get('description', 'No description')
        print(f'Description: {description[:100]}...')
        
        print(f'\n=== ALL VERSIONS ===')
        wan21_i2v_found = False
        
        for version in data.get('modelVersions', []):
            version_id = version['id']
            version_name = version.get('name', 'No name')
            base_model = version.get('baseModel', 'Unknown')
            
            print(f'\nVersion: {version_name}')
            print(f'  ID: {version_id}')
            print(f'  Base Model: {base_model}')
            
            # Check for WAN 2.1 compatibility
            if 'wan video 14b' in base_model.lower() and 'i2v' in base_model.lower():
                print(f'  ✅ WAN 2.1 I2V COMPATIBLE!')
                wan21_i2v_found = True
            elif 'wan video 2.1' in base_model.lower():
                print(f'  ✅ WAN 2.1 COMPATIBLE!')
                wan21_i2v_found = True
            elif 'wan video 2.2' in base_model.lower():
                print(f'  ⚠️  WAN 2.2 (current)')
            else:
                print(f'  ❓ Unknown compatibility')
            
            # Show files
            for file in version.get('files', []):
                if file.get('name', '').endswith('.safetensors'):
                    print(f'  📁 File: {file["name"]} ({file.get("sizeKB", 0) / 1024:.1f} MB)')
                    print(f'      File ID: {file["id"]}')
        
        print(f'\n=== SUMMARY ===')
        if wan21_i2v_found:
            print('✅ WAN 2.1 I2V version found!')
        else:
            print('❌ No WAN 2.1 I2V version found')
            print('💡 Only WAN 2.2 versions available')
    else:
        print(f'Error: {response.status_code}')

if __name__ == "__main__":
    check_dr34mj0b_versions()
