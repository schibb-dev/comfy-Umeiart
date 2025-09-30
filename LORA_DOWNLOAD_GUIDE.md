# Manual LoRA Download Guide

## Required LoRAs for FaceBlast Workflow

The following LoRAs are needed for the FaceBlast.json workflow:

### 1. wan-nsfw-e14-fixed.safetensors
- **Description**: WAN NSFW Enhancement LoRA
- **Strength**: 1.0
- **Status**: Disabled by default
- **Civitai**: Search for "wan nsfw" or "wan enhancement"

### 2. wan_cumshot_i2v.safetensors
- **Description**: WAN Cumshot Image-to-Video LoRA
- **Strength**: 0.95
- **Status**: Disabled by default
- **Civitai**: Search for "wan cumshot" or "wan i2v"

### 3. facials60.safetensors
- **Description**: Facial Enhancement LoRA
- **Strength**: 0.95
- **Status**: Disabled by default
- **Civitai**: Search for "facials" or "facial enhancement"

### 4. Handjob-wan-e38.safetensors
- **Description**: Handjob WAN LoRA
- **Strength**: 1.0
- **Status**: Disabled by default
- **Civitai**: Search for "handjob wan" or "wan handjob"

### 5. wan-thiccum-v3.safetensors ✅
- **Description**: WAN Thiccum v3 LoRA
- **Strength**: 0.95
- **Status**: **ENABLED**
- **Civitai**: Search for "wan thiccum" or "thiccum v3"

### 6. WAN_dr34mj0b.safetensors ✅
- **Description**: WAN Dr34mj0b LoRA
- **Strength**: 1.0
- **Status**: **ENABLED**
- **Civitai**: Search for "wan dr34mj0b"

### 7. bounceV_01.safetensors ✅
- **Description**: Bounce V01 LoRA
- **Strength**: 1.0
- **Status**: **ENABLED**
- **Civitai**: Search for "bounce" or "bounceV"

## Download Instructions

1. **Go to Civitai**: https://civitai.com
2. **Search for each LoRA** using the search terms above
3. **Download the .safetensors files**
4. **Place them in**: `/home/yuji/Code/Umeiart/ComfyUI/models/loras/`

## Alternative Sources

- **Hugging Face**: Some LoRAs may be available on HF
- **Community Repositories**: Check WAN community resources
- **Direct Links**: Some creators provide direct download links

## File Verification

After downloading, verify the files:
```bash
ls -la /home/yuji/Code/Umeiart/ComfyUI/models/loras/
```

Each file should be several MB in size (not just 100+ bytes).

## Workflow Usage

Once downloaded, the LoRAs will be available in the Power Lora Loader node in your FaceBlast workflow. You can:
- Enable/disable individual LoRAs
- Adjust strength values
- Combine multiple LoRAs for different effects
