import os
import json

assets_dir = "/Users/anoopjose/Projects/Little Artist/Little Artist/Assets.xcassets"

svgs = {
    "crayon_palette": '<path d="M 25 50 C 15 20, 85 20, 75 50 C 85 80, 15 80, 25 50 Z" fill="none" stroke="#FFCC00" stroke-width="4"/><circle cx="40" cy="35" r="4" fill="#FF3B30"/><circle cx="60" cy="35" r="4" fill="#007AFF"/><circle cx="50" cy="55" r="4" fill="#34C759"/>',
    "crayon_child": '<circle cx="50" cy="30" r="10" fill="none" stroke="#FF3B30" stroke-width="4"/><path d="M 50 40 L 50 70" fill="none" stroke="#007AFF" stroke-width="4" stroke-linecap="round"/><path d="M 30 50 L 70 50" fill="none" stroke="#34C759" stroke-width="4" stroke-linecap="round"/><path d="M 50 70 L 30 90 M 50 70 L 70 90" fill="none" stroke="#AF52DE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>',
    "crayon_scribble": '<path d="M 20 40 Q 30 0, 40 40 T 60 40" fill="none" stroke="#FF2D55" stroke-width="4" stroke-linecap="round"/><path d="M 60 40 T 80 40 Q 70 80, 50 60" fill="none" stroke="#32ADE6" stroke-width="4" stroke-linecap="round"/><path d="M 50 60 T 30 40" fill="none" stroke="#FFCC00" stroke-width="4" stroke-linecap="round"/>',
    "crayon_camera": '<path d="M 20 40 L 30 30 L 70 30 L 80 40 L 80 70 L 20 70 Z" fill="none" stroke="#007AFF" stroke-width="4" stroke-linejoin="round"/><circle cx="50" cy="50" r="12" fill="none" stroke="#FF9500" stroke-width="4"/><circle cx="70" cy="40" r="3" fill="#FFCC00"/><path d="M 35 30 L 45 30" stroke="#FF3B30" stroke-width="6" stroke-linecap="round"/>',
    "crayon_photos": '<path d="M 40 20 L 80 20 L 80 60" fill="none" stroke="#FF2D55" stroke-width="4"/><path d="M 30 30 L 70 30 L 70 70 L 30 70 Z" fill="none" stroke="#32ADE6" stroke-width="4"/>',
    "crayon_frame": '<path d="M 15 15 L 85 15 L 85 85 L 15 85 Z" fill="none" stroke="#AF52DE" stroke-width="4"/><path d="M 25 25 L 75 25 L 75 75 L 25 75 Z" fill="none" stroke="#34C759" stroke-width="3"/>',
    "crayon_sparkles": '<path d="M 30 20 L 30 40 M 20 30 L 40 30" fill="none" stroke="#FFCC00" stroke-width="4" stroke-linecap="round"/><path d="M 70 60 L 70 80 M 60 70 L 80 70" fill="none" stroke="#FF3B30" stroke-width="4" stroke-linecap="round"/><path d="M 50 40 L 50 50 M 45 45 L 55 45" fill="none" stroke="#007AFF" stroke-width="4" stroke-linecap="round"/>',
    "crayon_text": '<path d="M 20 30 Q 30 20, 40 30 T 60 30 T 80 30" fill="none" stroke="#FF9500" stroke-width="4" stroke-linecap="round"/><path d="M 20 50 Q 30 40, 40 50 T 60 50 T 80 50" fill="none" stroke="#32ADE6" stroke-width="4" stroke-linecap="round"/><path d="M 20 70 Q 30 60, 40 70 T 60 70" fill="none" stroke="#34C759" stroke-width="4" stroke-linecap="round"/>',
    "crayon_wand": '<path d="M 30 70 L 50 50" fill="none" stroke="#A2845E" stroke-width="4" stroke-linecap="round"/><path d="M 50 50 L 60 40 M 60 20 L 65 35 L 80 35 L 70 45 L 75 60 L 60 50 L 45 60 L 50 45 L 40 35 L 55 35 Z" fill="none" stroke="#FFCC00" stroke-width="4" stroke-linejoin="round"/>',
    "crayon_mic": '<rect x="40" y="20" width="20" height="30" rx="10" fill="none" stroke="#FF2D55" stroke-width="4"/><path d="M 30 40 A 20 20 0 0 0 70 40" fill="none" stroke="#007AFF" stroke-width="4"/><path d="M 50 60 L 50 80 M 35 80 L 65 80" fill="none" stroke="#34C759" stroke-width="4" stroke-linecap="round"/>',
    "crayon_waveform": '<path d="M 10 50 L 25 30 L 40 80" fill="none" stroke="#FF3B30" stroke-width="4" stroke-linejoin="round"/><path d="M 40 80 L 55 10 L 70 60" fill="none" stroke="#FFCC00" stroke-width="4" stroke-linejoin="round"/><path d="M 70 60 L 85 40" fill="none" stroke="#007AFF" stroke-width="4" stroke-linejoin="round"/>',
    "crayon_play": '<circle cx="50" cy="50" r="40" fill="none" stroke="#AF52DE" stroke-width="4"/><path d="M 40 30 L 70 50 L 40 70 Z" fill="none" stroke="#34C759" stroke-width="4" stroke-linejoin="round"/>',
    "crayon_share": '<path d="M 20 40 L 20 80 L 80 80 L 80 40" fill="none" stroke="#007AFF" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M 50 60 L 50 20 M 30 40 L 50 20 L 70 40" fill="none" stroke="#FF9500" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>',
    "crayon_heart": '<path d="M 50 80 C 50 80, 10 50, 10 30 C 10 10, 40 10, 50 30 C 60 10, 90 10, 90 30 C 90 50, 50 80, 50 80 Z" fill="none" stroke="#FF3B30" stroke-width="4" stroke-linejoin="round"/>',
    "crayon_people": '<g stroke="#007AFF"><circle cx="35" cy="30" r="8" fill="none" stroke-width="4"/><path d="M 35 38 L 35 60 M 20 45 L 50 45 M 35 60 L 25 80 M 35 60 L 45 80" fill="none" stroke-width="4" stroke-linecap="round"/></g><g stroke="#34C759"><circle cx="65" cy="35" r="7" fill="none" stroke-width="4"/><path d="M 65 42 L 65 60 M 55 48 L 75 48 M 65 60 L 55 80 M 65 60 L 75 80" fill="none" stroke-width="4" stroke-linecap="round"/></g>'
}

for name, content in svgs.items():
    img_dir = os.path.join(assets_dir, f"{name}.imageset")
    os.makedirs(img_dir, exist_ok=True)
    
    crayon_effect = f"""
    <defs>
        <filter id="crayon">
            <feTurbulence type="fractalNoise" baseFrequency="0.5" numOctaves="3" result="noise"/>
            <feDisplacementMap in="SourceGraphic" in2="noise" scale="3" xChannelSelector="R" yChannelSelector="G"/>
        </filter>
    </defs>
    <g filter="url(#crayon)">
        {content}
    </g>
    """
    
    svg_str = f'<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">{crayon_effect}</svg>'
    
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
            "preserves-vector-representation" : True,
            "template-rendering-intent" : "original"
          }
        }, f, indent=2)

print("Generated Multicolored SVGs.")
