class MxSlider:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "value": ("FLOAT", {"default": 0.0, "min": -999999.0, "max": 999999.0, "step": 0.01}),
            }
        }
    
    RETURN_TYPES = ("FLOAT",)
    RETURN_NAMES = ("value",)
    FUNCTION = "get_value"
    CATEGORY = "mx"
    
    def get_value(self, value):
        return (value,)

class MxSlider2D:
    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "value_x": ("FLOAT", {"default": 0.0, "min": -999999.0, "max": 999999.0, "step": 0.01}),
                "value_y": ("FLOAT", {"default": 0.0, "min": -999999.0, "max": 999999.0, "step": 0.01}),
            }
        }
    
    RETURN_TYPES = ("FLOAT", "FLOAT")
    RETURN_NAMES = ("value_x", "value_y")
    FUNCTION = "get_values"
    CATEGORY = "mx"
    
    def get_values(self, value_x, value_y):
        return (value_x, value_y)
