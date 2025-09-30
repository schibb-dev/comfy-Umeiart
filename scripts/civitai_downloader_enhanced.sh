#!/bin/bash
# Enhanced Civitai Asset Downloader with Comprehensive Debugging
# Downloads and installs workflows, models, LoRAs, and other assets from Civitai

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
CIVITAI_API_BASE="https://civitai.com/api/v1"
TOKEN_FILE="/home/yuji/Code/Umeiart/.civitai_token"
DEBUG_MODE="${DEBUG:-false}"

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

# Debug function
debug_log() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "🐛 DEBUG: $1" >&2
    fi
}

# Enhanced error reporting
report_error() {
    local error_msg="$1"
    local response_body="$2"
    local http_code="$3"
    
    echo "❌ ERROR: $error_msg" >&2
    if [[ -n "$http_code" ]]; then
        echo "   HTTP Status: $http_code" >&2
    fi
    if [[ -n "$response_body" ]]; then
        echo "   Response: $response_body" >&2
    fi
}

echo "🎨 Enhanced Civitai Asset Downloader & Installer"
echo "================================================"
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

if [[ "$1" == "debug" ]]; then
    DEBUG_MODE="true"
    shift
    echo "🐛 Debug mode enabled"
fi

if [[ "$1" == "help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [debug] [asset_type] [asset_id_or_search_term]"
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
    echo "  $0 debug lora 1643871                    # Download LoRA by ID with debug info"
    echo "  $0 lora \"wan-thiccum\"                  # Search and download LoRA"
    echo "  $0 debug workflow \"img to video\"      # Search workflow with debug"
    echo
    echo "Commands:"
    echo "  $0 clear-token                           # Clear saved API token"
    echo "  $0 help                                  # Show this help"
    echo
    exit 0
fi

# Create necessary directories
create_directories() {
    echo "📁 Creating model directories..."
    for dir in "${MODEL_DIRS[@]}"; do
        mkdir -p "$COMFYUI_DIR/models/$dir"
        debug_log "Created directory: $COMFYUI_DIR/models/$dir"
    done
    mkdir -p "$COMFYUI_DIR/workflows"
    debug_log "Created directory: $COMFYUI_DIR/workflows"
}

# Enhanced API token management
get_api_token() {
    # First, try to load token from file
    if [[ -f "$TOKEN_FILE" ]]; then
        debug_log "Token file exists: $TOKEN_FILE"
        # Try to extract token from JSON format first
        CIVITAI_API_TOKEN=$(jq -r '.civitai_token' "$TOKEN_FILE" 2>/dev/null || cat "$TOKEN_FILE" 2>/dev/null || echo "")
        if [[ -n "$CIVITAI_API_TOKEN" ]] && [[ "$CIVITAI_API_TOKEN" != "null" ]]; then
            echo "✅ Using saved Civitai API token"
            debug_log "Token loaded successfully (length: ${#CIVITAI_API_TOKEN})"
            
            # Test the token
            echo "🔍 Testing API token..."
            test_response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
                -H "Content-Type: application/json" \
                "$CIVITAI_API_BASE/models?limit=1" 2>/dev/null || echo "")
            
            http_code="${test_response: -3}"
            response_body="${test_response%???}"
            
            debug_log "Token test HTTP code: $http_code"
            debug_log "Token test response: $response_body"
            
            if [[ "$http_code" == "200" ]]; then
                echo "✅ API token is valid"
                return 0
            elif [[ "$http_code" == "401" ]]; then
                echo "❌ API token is invalid or expired"
                rm -f "$TOKEN_FILE"
            elif [[ "$http_code" == "403" ]]; then
                echo "❌ API token access denied"
                rm -f "$TOKEN_FILE"
            else
                echo "⚠️  API token test failed (HTTP $http_code)"
                report_error "Token validation failed" "$response_body" "$http_code"
            fi
        else
            echo "⚠️  Token file exists but is empty"
        fi
    else
        debug_log "No token file found: $TOKEN_FILE"
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
        # Test the new token
        echo "🔍 Testing new API token..."
        test_response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
            -H "Content-Type: application/json" \
            "$CIVITAI_API_BASE/models?limit=1" 2>/dev/null || echo "")
        
        http_code="${test_response: -3}"
        response_body="${test_response%???}"
        
        debug_log "New token test HTTP code: $http_code"
        debug_log "New token test response: $response_body"
        
        if [[ "$http_code" == "200" ]]; then
            # Save token to file for future use
            echo "$CIVITAI_API_TOKEN" > "$TOKEN_FILE"
            echo "✅ API token is valid and saved for future use"
            return 0
        else
            report_error "New token validation failed" "$response_body" "$http_code"
            echo "❌ Invalid API token. Please check and try again."
            exit 1
        fi
    else
        echo "❌ No API token provided. Exiting."
        exit 1
    fi
}

# Enhanced search function with detailed error reporting
search_assets() {
    local asset_type="$1"
    local search_term="$2"
    
    echo "🔍 Searching for $asset_type: '$search_term'..."
    debug_log "Search URL: $CIVITAI_API_BASE/models"
    debug_log "Search params: query=$search_term&types=${ASSET_TYPES[$asset_type]}&sort=Most%20Downloaded"
    
    local search_url="$CIVITAI_API_BASE/models"
    local search_params="?query=$(echo "$search_term" | sed 's/ /%20/g')&types=${ASSET_TYPES[$asset_type]}&sort=Most%20Downloaded"
    
    echo "📡 Searching Civitai API..."
    debug_log "Full search URL: $search_url$search_params"
    
    # Enhanced curl with error reporting
    local search_response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$search_url$search_params" 2>/dev/null || echo "")
    
    local http_code="${search_response: -3}"
    local response_body="${search_response%???}"
    
    debug_log "Search HTTP code: $http_code"
    debug_log "Search response: $response_body"
    
    if [[ "$http_code" == "200" ]]; then
        echo "✅ Search successful"
        
        # Parse and display results
        echo "📋 Found assets:"
        echo "$response_body" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    items = data.get('items', [])
    print(f'Total results: {len(items)}')
    for i, item in enumerate(items[:5]):
        print(f'  {i+1}. {item.get(\"name\", \"Unknown\")} (ID: {item.get(\"id\", \"Unknown\")})')
        print(f'     Downloads: {item.get(\"downloadCount\", 0):,}')
        print(f'     Type: {item.get(\"type\", \"Unknown\")}')
        print(f'     Creator: {item.get(\"creator\", {}).get(\"username\", \"Unknown\")}')
        print()
except Exception as e:
    print(f'  Error parsing search results: {e}')
"
        
        # Extract model IDs
        local model_ids=$(echo "$response_body" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    items = data.get('items', [])
    for item in items[:5]:
        print(item.get('id', ''))
except Exception as e:
    print(f'Error extracting IDs: {e}')
" | grep -v '^$')
        
        if [[ -n "$model_ids" ]]; then
            echo "🎯 Select an asset to download (1-5) or press Enter to download the first one:"
            read -r selection
            
            if [[ -z "$selection" ]]; then
                selection=1
            fi
            
            local selected_id=$(echo "$model_ids" | sed -n "${selection}p")
            debug_log "Selected ID: $selected_id"
            if [[ -n "$selected_id" ]]; then
                download_asset "$asset_type" "$selected_id"
                return $?
            fi
        else
            echo "❌ No valid model IDs found in search results"
        fi
    else
        report_error "Search failed" "$response_body" "$http_code"
        return 1
    fi
    
    return 1
}

# Enhanced download function with detailed error reporting
download_asset() {
    local asset_type="$1"
    local asset_id="$2"
    
    echo "📥 Downloading $asset_type (ID: $asset_id)..."
    debug_log "Asset type: $asset_type, Asset ID: $asset_id"
    
    # Get asset information
    local asset_url="$CIVITAI_API_BASE/models/$asset_id"
    debug_log "Asset info URL: $asset_url"
    
    local asset_response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$asset_url" 2>/dev/null || echo "")
    
    local http_code="${asset_response: -3}"
    local asset_info="${asset_response%???}"
    
    debug_log "Asset info HTTP code: $http_code"
    debug_log "Asset info response: $asset_info"
    
    if [[ "$http_code" != "200" ]]; then
        report_error "Failed to get asset information" "$asset_info" "$http_code"
        return 1
    fi
    
    if [[ -z "$asset_info" ]]; then
        echo "❌ Empty response from asset API"
        return 1
    fi
    
    # Extract asset name and download URLs
    local asset_name=$(echo "$asset_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('name', 'unknown_asset'))
except Exception as e:
    print(f'Error parsing asset name: {e}')
    print('unknown_asset')
")
    
    echo "📋 Asset: $asset_name"
    debug_log "Asset name: $asset_name"
    
    # Get download URLs from model versions
    local versions_url="$CIVITAI_API_BASE/models/$asset_id/versions"
    debug_log "Versions URL: $versions_url"
    
    local versions_response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$versions_url" 2>/dev/null || echo "")
    
    local versions_http_code="${versions_response: -3}"
    local versions_info="${versions_response%???}"
    
    debug_log "Versions HTTP code: $versions_http_code"
    debug_log "Versions response: $versions_info"
    
    if [[ "$versions_http_code" != "200" ]]; then
        report_error "Failed to get versions information" "$versions_info" "$versions_http_code"
        return 1
    fi
    
    if [[ -n "$versions_info" ]]; then
        # Extract download URLs
        local download_urls=$(echo "$versions_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    items = data.get('items', [])
    print(f'Found {len(items)} versions')
    if items:
        files = items[0].get('files', [])
        print(f'First version has {len(files)} files')
        for i, file in enumerate(files):
            print(f'File {i+1}: {file.get(\"name\", \"unknown\")} - {file.get(\"downloadUrl\", \"no_url\")}')
            if file.get('downloadUrl'):
                print(file.get('downloadUrl', ''))
except Exception as e:
    print(f'Error parsing versions: {e}')
")
        
        debug_log "Download URLs extraction: $download_urls"
        
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
            
            debug_log "Target directory: $target_dir"
            
            # Prepare shared download helper and paths
            local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            # shellcheck source=lib_download.sh
            if [[ -f "$SCRIPT_DIR/lib_download.sh" ]]; then
                source "$SCRIPT_DIR/lib_download.sh"
                debug_log "Loaded lib_download.sh"
            else
                echo "⚠️  lib_download.sh not found, using basic download"
            fi

            # Download files (with resume/verify)
            echo "$download_urls" | while read -r url; do
                if [[ -n "$url" ]]; then
                    local filename=$(basename "$url")
                    local target_file="$target_dir/$filename"

                    echo "📥 Downloading: $filename"
                    debug_log "Download URL: $url"
                    debug_log "Target file: $target_file"
                    
                    if [[ -f "$SCRIPT_DIR/lib_download.sh" ]]; then
                        if ! download_with_resume "$url" "$target_file" "" "" -- -H "Authorization: Bearer $CIVITAI_API_TOKEN"; then
                            echo "❌ Failed to download: $filename"
                            continue
                        fi
                    else
                        # Basic download without lib_download.sh
                        if ! curl -L -H "Authorization: Bearer $CIVITAI_API_TOKEN" -o "$target_file" "$url"; then
                            echo "❌ Failed to download: $filename"
                            continue
                        fi
                    fi

                    echo "✅ Downloaded: $filename"
                fi
            done
            
            return 0
        fi
    fi
    
    echo "❌ No download URLs found"
    debug_log "No download URLs found in versions response"
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
    echo "❌ Usage: $0 [debug] [asset_type] [asset_id_or_search_term]"
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
debug_log "Asset type: $ASSET_TYPE"
debug_log "Asset ID or search: $ASSET_ID_OR_SEARCH"

# Get API token
get_api_token

# Create directories
create_directories

# Determine if it's an ID or search term
if [[ "$ASSET_ID_OR_SEARCH" =~ ^[0-9]+$ ]]; then
    # It's a numeric ID
    debug_log "Treating as numeric ID"
    download_by_id "$ASSET_TYPE" "$ASSET_ID_OR_SEARCH"
else
    # It's a search term
    debug_log "Treating as search term"
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
