#!/bin/bash

# ============================================================================
# Civitai Asset Downloader & Installer
# Downloads and installs workflows, models, LoRAs, and other assets from Civitai
# ============================================================================

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
CIVITAI_API_BASE="https://civitai.com/api/v1"
TOKEN_FILE="/home/yuji/Code/Umeiart/.civitai_token"

# Asset type configurations
declare -A ASSET_TYPES=(
    ["workflow"]="workflows"
    ["model"]="models"
    ["lora"]="models"
    ["checkpoint"]="models"
    ["vae"]="models"
    ["clip"]="models"
    ["upscaler"]="models"
    ["controlnet"]="models"
    ["embedding"]="models"
)

declare -A MODEL_DIRS=(
    ["workflow"]="workflows"
    ["model"]="checkpoints"
    ["lora"]="loras"
    ["checkpoint"]="checkpoints"
    ["vae"]="vae"
    ["clip"]="clip"
    ["upscaler"]="upscale_models"
    ["controlnet"]="controlnet"
    ["embedding"]="embeddings"
)

echo "🎨 Civitai Asset Downloader & Installer"
echo "======================================="
echo

# Check for command line arguments
if [[ "$1" == "clear-token" ]]; then
    if [[ -f "$TOKEN_FILE" ]]; then
        rm -f "$TOKEN_FILE"
        echo "🗑️  Saved API token cleared"
    else
        echo "ℹ️  No saved token found"
    fi
    exit 0
fi

if [[ "$1" == "help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [asset_type] [asset_id_or_search_term]"
    echo
    echo "Asset Types:"
    echo "  workflow    - ComfyUI workflow JSON files"
    echo "  model       - AI models (checkpoints, etc.)"
    echo "  lora        - LoRA models"
    echo "  checkpoint  - Checkpoint models"
    echo "  vae         - VAE models"
    echo "  clip        - CLIP models"
    echo "  upscaler    - Upscaler models"
    echo "  controlnet  - ControlNet models"
    echo "  embedding   - Text embeddings"
    echo
    echo "Examples:"
    echo "  $0 workflow 13389                    # Download workflow by ID"
    echo "  $0 model \"WAN 2.1\"                  # Search and download model"
    echo "  $0 lora \"anime style\"               # Search and download LoRA"
    echo "  $0 workflow \"img to video\"         # Search and download workflow"
    echo
    echo "Commands:"
    echo "  $0 clear-token                       # Clear saved API token"
    echo "  $0 help                              # Show this help"
    echo
    exit 0
fi

# Create necessary directories
create_directories() {
    echo "📁 Creating model directories..."
    for dir in "${MODEL_DIRS[@]}"; do
        mkdir -p "$COMFYUI_DIR/models/$dir"
    done
    mkdir -p "$COMFYUI_DIR/workflows"
}

# Function to get API token from user or file
get_api_token() {
    # First, try to load token from file
    if [[ -f "$TOKEN_FILE" ]]; then
        CIVITAI_API_TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null || echo "")
        if [[ -n "$CIVITAI_API_TOKEN" ]]; then
            echo "✅ Using saved Civitai API token"
            return 0
        fi
    fi
    
    # If no saved token, prompt user
    echo "🔑 Civitai API Token Required"
    echo "============================="
    echo
    echo "To download assets from Civitai, you need an API token:"
    echo
    echo "1. 🌐 Go to: https://civitai.com/"
    echo "2. 🔐 Sign in to your account"
    echo "3. ⚙️  Go to Account Settings → API Keys"
    echo "4. ➕ Click 'Add API key'"
    echo "5. 📝 Give it a name (e.g., 'Civitai Asset Downloader')"
    echo "6. 🔑 Copy the generated token"
    echo
    echo "Enter your Civitai API token:"
    read -s CIVITAI_API_TOKEN
    echo
    
    if [[ -n "$CIVITAI_API_TOKEN" ]]; then
        # Save token to file for future use
        echo "$CIVITAI_API_TOKEN" > "$TOKEN_FILE"
        echo "💾 Token saved for future use"
        return 0
    else
        echo "❌ No API token provided. Exiting."
        exit 1
    fi
}

# Function to search for assets
search_assets() {
    local asset_type="$1"
    local search_term="$2"
    
    echo "🔍 Searching for $asset_type: '$search_term'..."
    
    local search_url="$CIVITAI_API_BASE/models"
    local search_params="?query=$(echo "$search_term" | sed 's/ /%20/g')&types=${ASSET_TYPES[$asset_type]}&sort=Most%20Downloaded"
    
    echo "📡 Searching Civitai API..."
    local search_result=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$search_url$search_params" 2>/dev/null || echo "")
    
    if [[ -n "$search_result" ]]; then
        echo "✅ Search successful"
        
        # Parse and display results
        echo "📋 Found assets:"
        echo "$search_result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    items = data.get('items', [])
    for i, item in enumerate(items[:5]):
        print(f'  {i+1}. {item.get(\"name\", \"Unknown\")} (ID: {item.get(\"id\", \"Unknown\")})')
        print(f'     Downloads: {item.get(\"downloadCount\", 0):,}')
        print(f'     Type: {item.get(\"type\", \"Unknown\")}')
        print()
except:
    print('  Error parsing search results')
"
        
        # Extract model IDs
        local model_ids=$(echo "$search_result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    items = data.get('items', [])
    for item in items[:5]:
        print(item.get('id', ''))
except:
    pass
" | grep -v '^$')
        
        if [[ -n "$model_ids" ]]; then
            echo "🎯 Select an asset to download (1-5) or press Enter to download the first one:"
            read -r selection
            
            if [[ -z "$selection" ]]; then
                selection=1
            fi
            
            local selected_id=$(echo "$model_ids" | sed -n "${selection}p")
            if [[ -n "$selected_id" ]]; then
                download_asset "$asset_type" "$selected_id"
                return $?
            fi
        fi
    fi
    
    return 1
}

# Function to download asset by ID
download_asset() {
    local asset_type="$1"
    local asset_id="$2"
    
    echo "📥 Downloading $asset_type (ID: $asset_id)..."
    
    # Get asset information
    local asset_url="$CIVITAI_API_BASE/models/$asset_id"
    local asset_info=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$asset_url" 2>/dev/null || echo "")
    
    if [[ -z "$asset_info" ]]; then
        echo "❌ Failed to get asset information"
        return 1
    fi
    
    # Extract asset name and download URLs
    local asset_name=$(echo "$asset_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('name', 'unknown_asset'))
except:
    print('unknown_asset')
")
    
    echo "📋 Asset: $asset_name"
    
    # Get download URLs from model versions
    local versions_url="$CIVITAI_API_BASE/models/$asset_id/versions"
    local versions_info=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$versions_url" 2>/dev/null || echo "")
    
    if [[ -n "$versions_info" ]]; then
        # Extract download URLs
        local download_urls=$(echo "$versions_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    items = data.get('items', [])
    if items:
        files = items[0].get('files', [])
        for file in files:
            print(file.get('downloadUrl', ''))
except:
    pass
")
        
        if [[ -n "$download_urls" ]]; then
            echo "🔗 Found download links:"
            echo "$download_urls" | while read -r url; do
                if [[ -n "$url" ]]; then
                    echo "  • $url"
                fi
            done
            
            # Determine target directory and file extension
            local target_dir="$COMFYUI_DIR/models/${MODEL_DIRS[$asset_type]}"
            if [[ "$asset_type" == "workflow" ]]; then
                target_dir="$COMFYUI_DIR/workflows"
            fi
            
            # Prepare shared download helper and paths
            local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            # shellcheck source=lib_download.sh
            source "$SCRIPT_DIR/lib_download.sh"

            # Download files (with resume/verify)
            echo "$download_urls" | while read -r url; do
                if [[ -n "$url" ]]; then
                    local filename=$(basename "$url")
                    local target_file="$target_dir/$filename"

                    echo "📥 Downloading: $filename"
                    if ! download_with_resume "$url" "$target_file" "" "" -- -H "Authorization: Bearer $CIVITAI_API_TOKEN"; then
                        echo "❌ Failed to download: $filename"
                        continue
                    fi

                    # Post-processing for workflows
                    if [[ "$asset_type" == "workflow" ]]; then
                        case "$filename" in
                            *.json|*.JSON)
                                if python3 -m json.tool "$target_file" > /dev/null 2>&1; then
                                    echo "✅ Valid workflow JSON"
                                else
                                    echo "⚠️  Invalid JSON workflow"
                                fi
                                ;;
                            *.zip|*.ZIP)
                                echo "📦 Extracting ZIP workflow bundle: $filename"
                                tmpdir=$(mktemp -d)
                                if unzip -q -o "$target_file" -d "$tmpdir"; then
                                    # Move JSON workflows directly into workflows dir
                                    found_json=0
                                    imported_jsons=()
                                    while IFS= read -r -d '' jf; do
                                        found_json=1
                                        bn=$(basename "$jf")
                                        if python3 -m json.tool "$jf" > /dev/null 2>&1; then
                                            echo "✅ Workflow JSON: $bn"
                                        else
                                            echo "⚠️  JSON not validated: $bn"
                                        fi
                                        mv -f "$jf" "$target_dir/$bn"
                                        imported_jsons+=("$bn")
                                    done < <(find "$tmpdir" -type f -name "*.json" -print0)

                                    # Preserve remaining files under imports/<asset_name>/
                                    import_dir="$target_dir/imports/${asset_name// /_}"
                                    mkdir -p "$import_dir"
                                    rsync -a --exclude='*.json' "$tmpdir/" "$import_dir/" || true
                                    echo "📁 Preserved bundle contents in: $import_dir"

                                    # Write import log (text)
                                    log_file="$import_dir/import_log.txt"
                                    {
                                      echo "Imported from Civitai"
                                      echo "Asset Name: $asset_name"
                                      echo "Asset ID: $asset_id"
                                      echo "Source URL: $url"
                                      echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
                                      echo "Host: $(hostname)"
                                      echo "User: ${USER:-unknown}"
                                      echo
                                      echo "Imported Workflows (placed in $target_dir):"
                                      for j in "${imported_jsons[@]:-}"; do
                                        sz=$(stat -c %s "$target_dir/$j" 2>/dev/null || echo 0)
                                        sh=$(sha256_file "$target_dir/$j" || true)
                                        echo "  - $j (size=$sz sha256=${sh:-n/a})"
                                      done
                                      echo
                                      echo "Preserved bundle path: $import_dir"
                                    } > "$log_file" || true
                                    echo "📝 Import log written: $log_file"
                                else
                                    echo "❌ Failed to extract ZIP: $filename"
                                fi
                                rm -rf "$tmpdir" || true
                                ;;
                            *)
                                echo "ℹ️  Saved asset: $filename"
                                ;;
                        esac
                    fi
                fi
            done
            
            return 0
        fi
    fi
    
    echo "❌ No download URLs found"
    return 1
}

# Function to download by direct ID
download_by_id() {
    local asset_type="$1"
    local asset_id="$2"
    
    echo "📥 Downloading $asset_type by ID: $asset_id"
    download_asset "$asset_type" "$asset_id"
}

# Main execution
if [[ $# -lt 2 ]]; then
    echo "❌ Usage: $0 [asset_type] [asset_id_or_search_term]"
    echo "   Run '$0 help' for more information"
    exit 1
fi

ASSET_TYPE="$1"
ASSET_ID_OR_SEARCH="$2"

# Validate asset type
if [[ -z "${ASSET_TYPES[$ASSET_TYPE]}" ]]; then
    echo "❌ Invalid asset type: $ASSET_TYPE"
    echo "   Run '$0 help' for valid asset types"
    exit 1
fi

echo "🚀 Starting Civitai asset download..."

# Get API token
get_api_token

# Create directories
create_directories

# Determine if it's an ID or search term
if [[ "$ASSET_ID_OR_SEARCH" =~ ^[0-9]+$ ]]; then
    # It's a numeric ID
    download_by_id "$ASSET_TYPE" "$ASSET_ID_OR_SEARCH"
else
    # It's a search term
    search_assets "$ASSET_TYPE" "$ASSET_ID_OR_SEARCH"
fi

echo
echo "🎉 Asset download complete!"
echo "=========================="
echo
echo "📁 Assets saved to: $COMFYUI_DIR/models/${MODEL_DIRS[$ASSET_TYPE]}"
if [[ "$ASSET_TYPE" == "workflow" ]]; then
    echo "📁 Workflows saved to: $COMFYUI_DIR/workflows"
fi
echo
echo "🚀 Next Steps:"
echo "  1. Restart ComfyUI: ./comfyui-restart.sh restart"
echo "  2. Open ComfyUI: http://127.0.0.1:8188"
echo "  3. Load your new assets!"
echo
echo "💾 Your API token is saved for future use"
echo "   Run './civitai-downloader.sh clear-token' to clear it"
