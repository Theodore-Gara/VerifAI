#!/usr/bin/env python3
"""Generate VerifAI launcher icons from the master icon (transparent PNG).

Composites the logo onto a white background (as requested) and writes:
  - Android legacy launcher icons (mipmap-*)
  - Android adaptive icon foregrounds + ic_launcher.xml (white background)
  - iOS AppIcon.appiconset PNGs (no alpha channel, as Apple requires)

Usage: python generate_app_icons.py <path-to-master-icon.png>
Requires: Pillow (pip install pillow)
"""

import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Fraction of the canvas the logo should occupy.
# Legacy/iOS icons: 0.85 leaves ~7.5% white padding for launcher masks.
# Adaptive foreground: 0.60 keeps the logo inside the 66dp safe zone.
LEGACY_FILL = 0.85
ADAPTIVE_FILL = 0.60

ANDROID_RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
IOS_ICONSET = os.path.join(
    ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
)

LEGACY_ANDROID = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

ADAPTIVE_ANDROID = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

IOS_ICONS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def _logo_on_canvas(logo, size, fill, background):
    """Center the logo on a square canvas, scaled to `fill` of its largest side."""
    canvas = Image.new("RGBA", (size, size), background)
    lw, lh = logo.size
    scale = size * fill / max(lw, lh)
    nw, nh = max(1, int(lw * scale)), max(1, int(lh * scale))
    resized = logo.resize((nw, nh), Image.LANCZOS)
    canvas.alpha_composite(resized, ((size - nw) // 2, (size - nh) // 2))
    return canvas


def generate(logo_path):
    logo = Image.open(logo_path).convert("RGBA")

    # Android legacy icons: logo on white.
    for folder, size in LEGACY_ANDROID.items():
        target = os.path.join(ANDROID_RES, folder, "ic_launcher.png")
        _logo_on_canvas(logo, size, LEGACY_FILL, (255, 255, 255, 255)).convert("RGB").save(target)
        print("wrote", os.path.relpath(target, ROOT))

    # Android adaptive icon foregrounds: logo on transparent (background is white layer).
    for folder, size in ADAPTIVE_ANDROID.items():
        target = os.path.join(ANDROID_RES, folder, "ic_launcher_foreground.png")
        _logo_on_canvas(logo, size, ADAPTIVE_FILL, (255, 255, 255, 0)).save(target)
        print("wrote", os.path.relpath(target, ROOT))

    # Adaptive icon definition with a white background.
    anydpi = os.path.join(ANDROID_RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            "</adaptive-icon>\n"
        )
    print("wrote", os.path.relpath(os.path.join(anydpi, "ic_launcher.xml"), ROOT))

    # White background color resource.
    values = os.path.join(ANDROID_RES, "values")
    os.makedirs(values, exist_ok=True)
    with open(os.path.join(values, "colors.xml"), "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            "<resources>\n"
            '    <color name="ic_launcher_background">#FFFFFF</color>\n'
            "</resources>\n"
        )
    print("wrote", os.path.relpath(os.path.join(values, "colors.xml"), ROOT))

    # iOS icons: logo on white, no alpha channel.
    for name, size in IOS_ICONS.items():
        target = os.path.join(IOS_ICONSET, name)
        _logo_on_canvas(logo, size, LEGACY_FILL, (255, 255, 255, 255)).convert("RGB").save(target)
        print("wrote", os.path.relpath(target, ROOT))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    generate(sys.argv[1])