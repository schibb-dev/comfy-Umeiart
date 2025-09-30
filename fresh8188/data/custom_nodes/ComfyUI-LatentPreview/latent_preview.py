import torch
import numpy as np
from PIL import Image
import folder_paths

class LatentPreview:
    @classmethod
    def INPUT_TYPES(s):
        return {
            "required": {
                "samples": ("LATENT",),
            },
            "optional": {
                "vae": ("VAE",),
            }
        }

    RETURN_TYPES = ("IMAGE",)
    FUNCTION = "preview"
    CATEGORY = "latent"

    def preview(self, samples, vae=None):
        if vae is None:
            # Create a simple preview without VAE
            latent = samples["samples"]
            # Convert latent to image-like tensor
            preview = torch.clamp((latent + 1.0) / 2.0, 0, 1)
            preview = preview.permute(0, 2, 3, 1)
            return (preview,)
        else:
            # Use VAE to decode
            decoded = vae.decode(samples["samples"])
            return (decoded,)

NODE_CLASS_MAPPINGS = {
    "LatentPreview": LatentPreview
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "LatentPreview": "Latent Preview"
}
