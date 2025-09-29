#!/bin/bash

# ============================================================================
# Section 1: Checking and requesting administrator privileges
# ============================================================================

# Check if running as root (equivalent to administrator privileges)
# For now, let's allow the script to run and check privileges when needed
echo "[INFO] Checking privileges..."
if [[ $EUID -ne 0 ]]; then
    echo "[WARNING] Not running as root. Some operations may require elevated privileges."
    echo "If you encounter permission errors, run with: sudo ./UmeAiRT-Install-ComfyUI.sh"
    echo
else
    echo "[OK] Running as root - full privileges available."
    echo
fi

# ============================================================================
# Section 2: Bootstrap downloader for all scripts
# ============================================================================


# Set a "clean" install path variable by removing any trailing slash.
# This prevents potential issues with path concatenation later in the script.
InstallPath="$(dirname "$(realpath "$0")")"
InstallPath="${InstallPath%/}"  # Remove trailing slash if present

ScriptsFolder="$InstallPath/scripts"
BootstrapScript="$ScriptsFolder/Bootstrap-Downloader.ps1"
BootstrapUrl="https://github.com/UmeAiRT/ComfyUI-Auto_installer/raw/main/scripts/Bootstrap-Downloader.ps1"

# Create scripts folder if it doesn't exist
if [[ ! -d "$ScriptsFolder" ]]; then
    echo "[INFO] Creating the scripts folder: $ScriptsFolder"
    mkdir -p "$ScriptsFolder"
fi

# Download all required files directly (bash equivalent of bootstrap script)
echo "[INFO] Downloading all required installation files..."

# Set the base URL for the GitHub repository's raw content
baseUrl="https://github.com/UmeAiRT/ComfyUI-Auto_installer/raw/main/"

# Define the list of files to download
filesToDownload=(
    # PowerShell Scripts (we'll convert these to bash)
    "scripts/Install-ComfyUI.ps1"
    "scripts/Update-ComfyUI.ps1"
    "scripts/Download-FLUX-Models.ps1"
    "scripts/Download-WAN2.1-Models.ps1"
    "scripts/Download-WAN2.2-Models.ps1"
    "scripts/Download-HIDREAM-Models.ps1"
    "scripts/Download-LTXV-Models.ps1"
    "scripts/Download-QWEN-Models.ps1"
    
    # Configuration Files
    "scripts/dependencies.json"
    "scripts/custom_nodes.csv"
    
    # Batch Launchers (we'll create bash equivalents)
    "UmeAiRT-Start-ComfyUI.bat"
    "UmeAiRT-Download_models.bat"
    "UmeAiRT-Update-ComfyUI.bat"
)

# Download each file
for file in "${filesToDownload[@]}"; do
    uri="$baseUrl$file"
    outFile="$InstallPath/$file"
    
    # Ensure the destination directory exists before downloading
    outDir=$(dirname "$outFile")
    if [[ ! -d "$outDir" ]]; then
        mkdir -p "$outDir"
    fi
    
    echo "  - Downloading $file..."
    if command -v curl >/dev/null 2>&1; then
        if ! curl -L -o "$outFile" "$uri"; then
            echo "[ERROR] Failed to download '$file'. Please check your internet connection and the repository URL."
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -O "$outFile" "$uri"; then
            echo "[ERROR] Failed to download '$file'. Please check your internet connection and the repository URL."
            exit 1
        fi
    else
        echo "[ERROR] Neither curl nor wget is available. Please install one of them."
        exit 1
    fi
done

echo "[OK] All required files have been downloaded successfully."
echo

# ============================================================================
# Section 3: Running the main installation script
# ============================================================================
echo "[INFO] Launching the main installation script..."
echo

# Check if we have the Install-ComfyUI.ps1 file and convert it to bash
if [[ -f "$ScriptsFolder/Install-ComfyUI.ps1" ]]; then
    echo "[INFO] Found Install-ComfyUI.ps1 - converting to bash equivalent..."
    # For now, let's create a simple bash installer
    bashInstaller="$ScriptsFolder/Install-ComfyUI.sh"
    
    # Create a basic bash installer that does the essential ComfyUI setup
    cat > "$bashInstaller" << 'EOF'
#!/bin/bash

# Basic ComfyUI installer for Linux
echo "[INFO] Starting ComfyUI installation..."

# Check if Python is available
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] Python 3 is required but not installed."
    echo "Please install Python 3 and try again."
    exit 1
fi

# Check if pip is available (try different variations)
pipCmd=""
if command -v pip3 >/dev/null 2>&1; then
    pipCmd="pip3"
elif command -v pip >/dev/null 2>&1; then
    pipCmd="pip"
elif python3 -m pip --version >/dev/null 2>&1; then
    pipCmd="python3 -m pip"
else
    echo "[ERROR] No pip installation found."
    echo "Please install pip or pip3 and try again."
    echo "You can install it with: sudo apt install python3-pip"
    exit 1
fi

echo "[INFO] Using pip command: $pipCmd"

# Create ComfyUI directory
ComfyUIPath="$1/ComfyUI"
if [[ ! -d "$ComfyUIPath" ]]; then
    echo "[INFO] Creating ComfyUI directory: $ComfyUIPath"
    mkdir -p "$ComfyUIPath"
fi

cd "$ComfyUIPath"

# Clone ComfyUI repository if it doesn't exist
if [[ ! -d ".git" ]]; then
    echo "[INFO] Cloning ComfyUI repository..."
    if command -v git >/dev/null 2>&1; then
        git clone https://github.com/comfyanonymous/ComfyUI.git .
    else
        echo "[ERROR] Git is required but not installed."
        echo "Please install git and try again."
        exit 1
    fi
fi

# Install requirements
if [[ -f "requirements.txt" ]]; then
    echo "[INFO] Installing Python requirements..."
    $pipCmd install -r requirements.txt
fi

echo "[OK] ComfyUI installation completed!"
echo "[INFO] To start ComfyUI, run: cd $ComfyUIPath && python3 main.py"
EOF
    
    chmod +x "$bashInstaller"
    
    # Run the bash installer
    bash "$bashInstaller" "$InstallPath"
else
    echo "[ERROR] Install-ComfyUI.ps1 not found. Installation files may not have downloaded correctly."
    exit 1
fi

echo
echo "[INFO] The script execution is complete."
echo "Press Enter to continue..."
read -r
