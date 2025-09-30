#!/usr/bin/env python3
import json
import re

# Read the workflow file
with open('/home/yuji/Code/Umeiart/ComfyUI/workflows/FaceBlast.json', 'r') as f:
    content = f.read()

# Find all model references
model_matches = re.findall(r'"wan2\.1[^"]*\.gguf"', content)
print("Found model references:")
for match in model_matches:
    print(f"  {match}")

# Also look for any WAN references
wan_matches = re.findall(r'"WAN[^"]*"', content)
print("\nFound WAN references:")
for match in wan_matches:
    print(f"  {match}")

