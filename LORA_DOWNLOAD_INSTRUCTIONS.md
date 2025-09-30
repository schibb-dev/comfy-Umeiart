# 🎭 LoRA Download Instructions for FaceBlast Workflow

## Required LoRAs

Your FaceBlast.json workflow requires the following LoRAs:

### 1. wan-nsfw-e14-fixed.safetensors
- **Status**: ❌ Disabled (strength: 1.0)
- **Description**: WAN NSFW Enhancement LoRA
- **Civitai Search**: https://civitai.com/search?q=wan%20nsfw%20e14
- **Alternative**: https://civitai.com/search?q=wan%20enhancement

### 2. wan_cumshot_i2v.safetensors
- **Status**: ❌ Disabled (strength: 0.95)
- **Description**: WAN Cumshot Image-to-Video LoRA
- **Civitai Search**: https://civitai.com/search?q=wan%20cumshot%20i2v
- **Alternative**: https://civitai.com/search?q=wan%20cumshot

### 3. facials60.safetensors
- **Status**: ❌ Disabled (strength: 0.95)
- **Description**: Facial Enhancement LoRA
- **Civitai Search**: https://civitai.com/search?q=facials60
- **Alternative**: https://civitai.com/search?q=facial%20enhancement

### 4. Handjob-wan-e38.safetensors
- **Status**: ❌ Disabled (strength: 1.0)
- **Description**: Handjob WAN LoRA
- **Civitai Search**: https://civitai.com/search?q=handjob%20wan%20e38
- **Alternative**: https://civitai.com/search?q=wan%20handjob

### 5. wan-thiccum-v3.safetensors ✅
- **Status**: ✅ **ENABLED** (strength: 0.95)
- **Description**: WAN Thiccum v3 LoRA
- **Civitai Search**: https://civitai.com/search?q=wan%20thiccum%20v3
- **Priority**: HIGH (enabled in workflow)

### 6. WAN_dr34mj0b.safetensors ✅
- **Status**: ✅ **ENABLED** (strength: 1.0)
- **Description**: WAN Dr34mj0b LoRA
- **Civitai Search**: https://civitai.com/search?q=wan%20dr34mj0b
- **Priority**: HIGH (enabled in workflow)

### 7. bounceV_01.safetensors ✅
- **Status**: ✅ **ENABLED** (strength: 1.0)
- **Description**: Bounce V01 LoRA
- **Civitai Search**: https://civitai.com/search?q=bounceV%2001
- **Priority**: HIGH (enabled in workflow)

## Download Steps

### Step 1: Create Civitai Account
1. Go to https://civitai.com
2. Create an account (free)
3. Get your API token from Settings > API Keys

### Step 2: Download LoRAs
1. Click on each search link above
2. Find the correct LoRA model
3. Click "Download" button
4. Save the .safetensors file

### Step 3: Place Files
```bash
# Copy downloaded files to:
/home/yuji/Code/Umeiart/ComfyUI/models/loras/

# Verify files:
ls -la /home/yuji/Code/Umeiart/ComfyUI/models/loras/
```

### Step 4: Verify Installation
Each LoRA file should be several MB in size (not just 100+ bytes).

## Priority Downloads

**Start with these enabled LoRAs:**
1. wan-thiccum-v3.safetensors
2. WAN_dr34mj0b.safetensors  
3. bounceV_01.safetensors

These are **enabled** in your workflow and will have immediate impact.

## Alternative Sources

If Civitai doesn't have the LoRAs:
- **Hugging Face**: Search for "wan lora" repositories
- **Community Discord**: WAN community servers
- **GitHub**: Community repositories
- **Direct Links**: Some creators provide direct downloads

## Testing

After downloading:
1. Start ComfyUI
2. Load FaceBlast.json workflow
3. Check if LoRAs appear in Power Lora Loader dropdown
4. Test with a simple image

## Troubleshooting

- **Files too small**: Re-download from Civitai
- **Not appearing in ComfyUI**: Restart ComfyUI
- **Workflow errors**: Check LoRA file names match exactly
- **Download issues**: Try different browser or incognito mode

## File Verification

Run this command to check file sizes:
```bash
ls -la /home/yuji/Code/Umeiart/ComfyUI/models/loras/ | grep -v "put_loras_here"
```

Each LoRA should be several MB, not just 100+ bytes.
