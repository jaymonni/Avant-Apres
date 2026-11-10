"""Recolor only the V2 launcher icon's green pixels, preserving its white A/A logo."""
from pathlib import Path
from PIL import Image
import colorsys

root = Path("android/app/src/main/res")
files = sorted(root.glob("mipmap*/ic_launcher.png"))
if not files:
    raise SystemExit("No ic_launcher.png found; launcher icon not changed")

for path in files:
    im = Image.open(path).convert("RGBA")
    out = []
    for red, green, blue, alpha in im.getdata():
        hue, saturation, value = colorsys.rgb_to_hsv(red / 255, green / 255, blue / 255)
        # Preserve white letters, sparkles, highlights, transparency and shadows.
        if 0.18 <= hue <= 0.47 and saturation > 0.16 and green > red * 1.08:
            # Sage green #779982, with the existing icon's brightness variation.
            brightness = max(0.68, min(1.18, value / 0.79))
            red, green, blue = (
                min(255, round(channel * brightness))
                for channel in (119, 153, 130)
            )
        out.append((red, green, blue, alpha))
    im.putdata(out)
    im.save(path)
    print(f"Recolored V2 launcher icon: {path}")
