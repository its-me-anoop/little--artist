import os
import json

assets_dir = "/Users/anoopjose/Projects/Little Artist/Little Artist/Assets.xcassets"
name = "crayon_paper"
img_dir = os.path.join(assets_dir, f"{name}.imageset")
os.makedirs(img_dir, exist_ok=True)

# Generate a rough paper texture SVG
svg_str = """
<svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="paper">
      <feTurbulence type="fractalNoise" baseFrequency="0.04" numOctaves="5" result="noise" />
      <feColorMatrix type="matrix" values="1 0 0 0 0  0 0.98 0 0 0  0 0.96 0 0 0  0 0 0 0.2 0" />
    </filter>
  </defs>
  <rect width="100%" height="100%" fill="#FFFBF7" />
  <rect width="100%" height="100%" filter="url(#paper)" />
</svg>
"""

with open(os.path.join(img_dir, f"{name}.svg"), "w") as f:
    f.write(svg_str)
    
with open(os.path.join(img_dir, "Contents.json"), "w") as f:
    json.dump({
        "images" : [
        {
            "filename" : f"{name}.svg",
            "idiom" : "universal"
        }
        ],
        "info" : {
        "author" : "xcode",
        "version" : 1
        },
        "properties" : {
        "preserves-vector-representation" : True
        }
    }, f, indent=2)

print("Generated texture SVG.")
