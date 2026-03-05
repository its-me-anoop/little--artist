import os
import glob

assets_dir = "/Users/anoopjose/Projects/Little Artist/Little Artist/Assets.xcassets"
svg_files = glob.glob(os.path.join(assets_dir, "*.imageset", "*.svg"))

for file in svg_files:
    # Skip the background pattern we generated
    if "crayon_paper" in file:
        continue
        
    with open(file, 'r') as f:
        content = f.read()

    import re
    # Remove everything in <defs>
    content = re.sub(r'<defs>.*?</defs>', '', content, flags=re.DOTALL)
    # Remove the opening and closing g tag with the filter
    content = re.sub(r'<g filter="url\(#crayon\)">\s*', '', content)
    content = re.sub(r'\s*</g>\s*(?=</svg>)', '', content)
    
    with open(file, 'w') as f:
        f.write(content)

print(f"Fixed {len(svg_files)} SVGs.")
