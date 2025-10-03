#!/bin/bash
# Fixed Civitai Asset Downloader - Direct Download Method
# Downloads LoRAs directly using the downloadUrl from model info

set -e

COMFYUI_DIR="/home/yuji/Code/Umeiart/ComfyUI"
CIVITAI_API_BASE="https://civitai.com/api/v1"
TOKEN_FILE="/home/yuji/Code/Umeiart/.civitai_token"
DEBUG_MODE="${DEBUG:-false}"

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
    if [[ -n "$response_body" ]] && [[ ${#response_body} -lt 500 ]]; then
        echo "   Response: $response_body" >&2
    fi
}

echo "🎨 Fixed Civitai LoRA Downloader"
echo "================================="
echo

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
            echo "⚠️  Token file exists but is empty or invalid"
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
        
        debug_log "New token test HTTP code: $http_code"
        
        if [[ "$http_code" == "200" ]]; then
            # Save token to file for future use
            echo "$CIVITAI_API_TOKEN" > "$TOKEN_FILE"
            echo "✅ API token is valid and saved for future use"
            return 0
        else
            report_error "New token validation failed" "" "$http_code"
            echo "❌ Invalid API token. Please check and try again."
            exit 1
        fi
    else
        echo "❌ No API token provided. Exiting."
        exit 1
    fi
}

# Create necessary directories
create_directories() {
    echo "📁 Creating model directories..."
    mkdir -p "$COMFYUI_DIR/models/loras"
    debug_log "Created directory: $COMFYUI_DIR/models/loras"
}

# Enhanced download function with direct download method
download_lora_by_id() {
    local asset_id="$1"
    local target_filename="$2"
    
    echo "📥 Downloading LoRA (ID: $asset_id)..."
    debug_log "Asset ID: $asset_id, Target filename: $target_filename"
    
    # Get asset information
    local asset_url="$CIVITAI_API_BASE/models/$asset_id"
    debug_log "Asset info URL: $asset_url"
    
    local asset_response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$asset_url" 2>/dev/null || echo "")
    
    local http_code="${asset_response: -3}"
    local asset_info="${asset_response%???}"
    
    debug_log "Asset info HTTP code: $http_code"
    
    if [[ "$http_code" != "200" ]]; then
        report_error "Failed to get asset information" "$asset_info" "$http_code"
        return 1
    fi
    
    if [[ -z "$asset_info" ]]; then
        echo "❌ Empty response from asset API"
        return 1
    fi
    
    # Extract asset name and download URL directly from model info
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
    
    # Extract download URL directly from model info (new method)
    local download_url=$(echo "$asset_info" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    model_versions = data.get('modelVersions', [])
    if model_versions:
        files = model_versions[0].get('files', [])
        if files:
            print(files[0].get('downloadUrl', ''))
        else:
            print('')
    else:
        print('')
except Exception as e:
    print(f'Error parsing download URL: {e}')
    print('')
")
    
    debug_log "Download URL: $download_url"
    
    if [[ -n "$download_url" ]]; then
        local target_file="$COMFYUI_DIR/models/loras/$target_filename"
        
        # Check if file already exists and is valid
        if [[ -f "$target_file" ]] && [[ $(stat -c%s "$target_file") -gt 1024 ]]; then
            local size=$(stat -c%s "$target_file")
            local size_mb=$((size / 1024 / 1024))
            echo "✅ $target_filename already exists (${size_mb}MB)"
            return 0
        fi
        
        echo "🔗 Download URL found: $download_url"
        echo "📥 Downloading: $target_filename"
        
        # Download with progress
        if curl -L -H "Authorization: Bearer $CIVITAI_API_TOKEN" -o "$target_file" "$download_url"; then
            local size=$(stat -c%s "$target_file")
            local size_mb=$((size / 1024 / 1024))
            echo "✅ Downloaded: $target_filename (${size_mb}MB)"
            return 0
        else
            echo "❌ Failed to download: $target_filename"
            if [[ -f "$target_file" ]]; then
                rm -f "$target_file"  # Remove partial file
            fi
            return 1
        fi
    else
        echo "❌ No download URL found in model info"
        debug_log "No download URL found in asset info"
        return 1
    fi
}

# Main execution
if [[ $# -lt 1 ]]; then
    echo "❌ Usage: $0 [debug] <asset_id> [target_filename]"
    echo "   Example: $0 debug 1643871 wan-thiccum-v3.safetensors"
    exit 1
fi

if [[ "$1" == "debug" ]]; then
    DEBUG_MODE="true"
    shift
    echo "🐛 Debug mode enabled"
fi

ASSET_ID="$1"
TARGET_FILENAME="${2:-}"

# Validate asset ID
if [[ ! "$ASSET_ID" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid asset ID: $ASSET_ID (must be numeric)"
    exit 1
fi

echo "🚀 Starting Civitai LoRA download..."
debug_log "Asset ID: $ASSET_ID"
debug_log "Target filename: $TARGET_FILENAME"

# Get API token
get_api_token

# Create directories
create_directories

# Download the LoRA
if [[ -n "$TARGET_FILENAME" ]]; then
    download_lora_by_id "$ASSET_ID" "$TARGET_FILENAME"
else
    # Try to determine filename from asset info
    echo "🔍 Getting asset info to determine filename..."
    asset_response=$(curl -s -H "Authorization: Bearer $CIVITAI_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$CIVITAI_API_BASE/models/$ASSET_ID" 2>/dev/null || echo "")
    
    if [[ -n "$asset_response" ]]; then
        filename=$(echo "$asset_response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    model_versions = data.get('modelVersions', [])
    if model_versions:
        files = model_versions[0].get('files', [])
        if files:
            print(files[0].get('name', ''))
except:
    pass
")
        
        if [[ -n "$filename" ]]; then
            echo "📋 Detected filename: $filename"
            download_lora_by_id "$ASSET_ID" "$filename"
        else
            echo "❌ Could not determine filename from asset info"
            exit 1
        fi
    else
        echo "❌ Could not get asset info"
        exit 1
    fi
fi

echo
echo "🎉 LoRA download complete!"
echo "========================="
echo "📁 LoRAs saved to: $COMFYUI_DIR/models/loras"
echo
echo "🚀 Next Steps:"
echo "  1. Restart ComfyUI"
echo "  2. Load FaceBlast.json workflow"
echo "  3. Check LoRAs appear in Power Lora Loader dropdown"
echo "  4. Test with a sample image"







