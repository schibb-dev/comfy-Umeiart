#!/usr/bin/env python3
"""
Advanced Civitai LoRA Downloader for WAN 2.1 FaceBlast Workflow
Uses the existing Civitai API infrastructure to download LoRAs automatically
"""

import os
import sys
import json
import requests
import subprocess
from pathlib import Path
from tqdm import tqdm

class CivitaiLoRADownloader:
    def __init__(self, base_dir="/home/yuji/Code/Umeiart"):
        self.base_dir = Path(base_dir)
        self.token_file = self.base_dir / ".civitai_token"
        self.lora_dir = self.base_dir / "ComfyUI" / "models" / "loras"
        self.lora_dir.mkdir(parents=True, exist_ok=True)
        
        # Civitai API configuration
        self.api_base = "https://civitai.com/api/v1"
        self.token = None
        
        # LoRA definitions with Civitai search terms
        self.loras = {
            'wan-nsfw-e14-fixed.safetensors': {
                'description': 'WAN NSFW Enhancement LoRA',
                'strength': 1.0,
                'enabled': False,
                'search_terms': ['wan nsfw e14', 'wan enhancement', 'wan nsfw'],
                'priority': 3
            },
            'wan_cumshot_i2v.safetensors': {
                'description': 'WAN Cumshot Image-to-Video LoRA',
                'strength': 0.95,
                'enabled': False,
                'search_terms': ['wan cumshot i2v', 'wan cumshot', 'wan i2v'],
                'priority': 3
            },
            'facials60.safetensors': {
                'description': 'Facial Enhancement LoRA',
                'strength': 0.95,
                'enabled': False,
                'search_terms': ['facials60', 'facial enhancement', 'facials'],
                'priority': 3
            },
            'Handjob-wan-e38.safetensors': {
                'description': 'Handjob WAN LoRA',
                'strength': 1.0,
                'enabled': False,
                'search_terms': ['handjob wan e38', 'wan handjob', 'handjob'],
                'priority': 3
            },
            'wan-thiccum-v3.safetensors': {
                'description': 'WAN Thiccum v3 LoRA',
                'strength': 0.95,
                'enabled': True,
                'search_terms': ['wan thiccum v3', 'wan thiccum', 'thiccum v3'],
                'civitai_id': '1643871',
                'priority': 1
            },
            'WAN_dr34mj0b.safetensors': {
                'description': 'WAN Dr34mj0b LoRA',
                'strength': 1.0,
                'enabled': True,
                'search_terms': ['wan dr34mj0b', 'dr34mj0b', 'wan dr34'],
                'civitai_id': '1395313',
                'priority': 1
            },
            'bounceV_01.safetensors': {
                'description': 'Bounce V01 LoRA',
                'strength': 1.0,
                'enabled': True,
                'search_terms': ['bounceV 01', 'bounceV', 'bounce'],
                'civitai_id': '1343431',
                'priority': 1
            }
        }
    
    def load_token(self):
        """Load Civitai API token from file"""
        if self.token_file.exists():
            try:
                with open(self.token_file, 'r') as f:
                    token_data = json.load(f)
                self.token = token_data.get("civitai_token")
                if self.token:
                    print("✅ Loaded Civitai API token")
                    return True
            except (json.JSONDecodeError, KeyError):
                pass
        
        print("❌ No valid Civitai API token found")
        print("Please run: ./scripts/civitai_downloader.sh lora 'wan'")
        print("This will prompt you to enter your API token")
        return False
    
    def search_civitai(self, search_term):
        """Search Civitai for LoRAs"""
        url = f"{self.api_base}/models"
        params = {
            'query': search_term,
            'types': 'LORA',
            'sort': 'Most Downloaded',
            'limit': 10
        }
        
        headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }
        
        try:
            response = requests.get(url, params=params, headers=headers, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            print(f"❌ Search failed for '{search_term}': {e}")
            return None
    
    def find_lora_by_name(self, lora_name, search_results):
        """Find a specific LoRA by name in search results"""
        if not search_results or 'items' not in search_results:
            return None
        
        # Look for exact filename match first
        for item in search_results['items']:
            model_versions = item.get('modelVersions', [])
            for version in model_versions:
                files = version.get('files', [])
                for file_info in files:
                    if file_info.get('name') == lora_name:
                        return {
                            'model_id': item.get('id'),
                            'model_name': item.get('name'),
                            'version_id': version.get('id'),
                            'file_info': file_info,
                            'download_url': file_info.get('downloadUrl')
                        }
        
        # Look for partial name match
        lora_base = lora_name.replace('.safetensors', '').lower()
        for item in search_results['items']:
            model_name = item.get('name', '').lower()
            if lora_base in model_name or any(term.lower() in model_name for term in lora_base.split('-')):
                model_versions = item.get('modelVersions', [])
                if model_versions:
                    version = model_versions[0]  # Use first version
                    files = version.get('files', [])
                    if files:
                        return {
                            'model_id': item.get('id'),
                            'model_name': item.get('name'),
                            'version_id': version.get('id'),
                            'file_info': files[0],
                            'download_url': files[0].get('downloadUrl')
                        }
        
        return None
    
    def download_file(self, url, filename):
        """Download a file with progress bar"""
        filepath = self.lora_dir / filename
        
        # Check if file already exists and is valid
        if filepath.exists() and filepath.stat().st_size > 1024:
            print(f"✅ {filename} already exists ({filepath.stat().st_size:,} bytes)")
            return True
        
        print(f"📥 Downloading {filename}...")
        
        headers = {
            'Authorization': f'Bearer {self.token}',
            'User-Agent': 'CivitaiLoRADownloader/1.0'
        }
        
        try:
            response = requests.get(url, stream=True, headers=headers, timeout=300)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            
            with open(filepath, 'wb') as f, tqdm(
                desc=filename,
                total=total_size,
                unit='iB',
                unit_scale=True,
                unit_divisor=1024,
            ) as pbar:
                for chunk in response.iter_content(chunk_size=8192):
                    size = f.write(chunk)
                    pbar.update(size)
            
            print(f"✅ Downloaded {filename} ({filepath.stat().st_size:,} bytes)")
            return True
            
        except Exception as e:
            print(f"❌ Failed to download {filename}: {e}")
            if filepath.exists():
                filepath.unlink()  # Remove partial file
            return False
    
    def download_lora(self, lora_name, lora_info):
        """Download a specific LoRA"""
        print(f"\n🔍 Searching for {lora_name}...")
        
        # Try each search term
        for search_term in lora_info['search_terms']:
            print(f"  Searching: '{search_term}'")
            search_results = self.search_civitai(search_term)
            
            if search_results:
                lora_match = self.find_lora_by_name(lora_name, search_results)
                
                if lora_match:
                    print(f"  ✅ Found: {lora_match['model_name']}")
                    print(f"  📋 Model ID: {lora_match['model_id']}")
                    
                    if lora_match['download_url']:
                        return self.download_file(lora_match['download_url'], lora_name)
                    else:
                        print(f"  ❌ No download URL found")
                else:
                    print(f"  ⚠️  No exact match found")
            else:
                print(f"  ❌ Search failed")
        
        print(f"  ❌ Could not find {lora_name}")
        return False
    
    def use_existing_script(self, lora_name):
        """Use the existing Civitai downloader script"""
        script_path = self.base_dir / "scripts" / "civitai_downloader.sh"
        
        if not script_path.exists():
            print(f"❌ Civitai downloader script not found: {script_path}")
            return False
        
        print(f"🚀 Using existing Civitai downloader for {lora_name}")
        
        # Try different search terms
        search_terms = self.loras[lora_name]['search_terms']
        
        for search_term in search_terms:
            try:
                print(f"  Trying search: '{search_term}'")
                result = subprocess.run([
                    str(script_path), 'lora', search_term
                ], capture_output=True, text=True, timeout=300)
                
                if result.returncode == 0:
                    print(f"  ✅ Download successful with search: '{search_term}'")
                    return True
                else:
                    print(f"  ⚠️  Search '{search_term}' failed: {result.stderr}")
            
            except subprocess.TimeoutExpired:
                print(f"  ⏰ Search '{search_term}' timed out")
            except Exception as e:
                print(f"  ❌ Error with search '{search_term}': {e}")
        
        return False
    
    def run(self):
        """Main execution"""
        print("🎭 Advanced Civitai LoRA Downloader")
        print("=" * 50)
        
        # Load API token
        if not self.load_token():
            print("\n🔧 Falling back to existing Civitai downloader script...")
            return self.run_with_existing_script()
        
        # Sort LoRAs by priority (enabled first)
        sorted_loras = sorted(
            self.loras.items(),
            key=lambda x: (x[1]['priority'], x[0])
        )
        
        print(f"\n📋 LoRAs to download ({len(sorted_loras)} total):")
        for lora_name, info in sorted_loras:
            status = "✅ Enabled" if info['enabled'] else "❌ Disabled"
            print(f"  • {lora_name} - {info['description']} - {status}")
        
        # Download LoRAs
        success_count = 0
        total_count = len(sorted_loras)
        
        print(f"\n🚀 Starting downloads...")
        
        for lora_name, lora_info in sorted_loras:
            if self.download_lora(lora_name, lora_info):
                success_count += 1
        
        print(f"\n📊 Download Results: {success_count}/{total_count} LoRAs downloaded")
        
        if success_count < total_count:
            print("\n🔄 Trying with existing Civitai downloader script...")
            remaining_loras = [name for name, info in sorted_loras 
                             if not (self.lora_dir / name).exists() or 
                             (self.lora_dir / name).stat().st_size < 1024]
            
            for lora_name in remaining_loras:
                if self.use_existing_script(lora_name):
                    success_count += 1
        
        print(f"\n🎉 Final Results: {success_count}/{total_count} LoRAs available")
        print(f"📁 LoRAs directory: {self.lora_dir}")
        
        return success_count == total_count
    
    def run_with_existing_script(self):
        """Run using the existing Civitai downloader script"""
        print("🔧 Using existing Civitai downloader script...")
        
        script_path = self.base_dir / "scripts" / "civitai_downloader.sh"
        
        if not script_path.exists():
            print(f"❌ Civitai downloader script not found: {script_path}")
            return False
        
        success_count = 0
        total_count = len(self.loras)
        
        # Try downloading with different search terms
        search_terms_to_try = [
            'wan thiccum',
            'wan dr34mj0b', 
            'bounceV',
            'wan nsfw',
            'wan cumshot',
            'facials60',
            'handjob wan'
        ]
        
        for search_term in search_terms_to_try:
            print(f"\n🔍 Trying search: '{search_term}'")
            try:
                result = subprocess.run([
                    str(script_path), 'lora', search_term
                ], capture_output=True, text=True, timeout=300)
                
                if result.returncode == 0:
                    print(f"✅ Download successful with search: '{search_term}'")
                    success_count += 1
                else:
                    print(f"⚠️  Search '{search_term}' failed")
                    print(f"Error: {result.stderr}")
            
            except subprocess.TimeoutExpired:
                print(f"⏰ Search '{search_term}' timed out")
            except Exception as e:
                print(f"❌ Error with search '{search_term}': {e}")
        
        print(f"\n📊 Results: {success_count} successful downloads")
        return success_count > 0

def main():
    downloader = CivitaiLoRADownloader()
    success = downloader.run()
    
    if success:
        print("\n🎉 All LoRAs downloaded successfully!")
        print("🚀 Your FaceBlast workflow is ready to use!")
    else:
        print("\n⚠️  Some LoRAs may need manual download")
        print("📖 Check LORA_DOWNLOAD_INSTRUCTIONS.md for manual steps")

if __name__ == "__main__":
    main()






