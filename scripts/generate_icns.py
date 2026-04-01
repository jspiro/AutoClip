#!/usr/bin/env python3
"""Generate macOS iconset from a source PNG with a white squircle background.

Usage: generate_icns.py <source.png> <output.iconset/>

Composites the source image (with padding/scale from the .icon package)
onto a white macOS-style continuous rounded rect so the icon looks correct
in Finder without relying on Xcode's .icon processing.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <source.png> <output.iconset/>")
        sys.exit(1)

    source = Path(sys.argv[1])
    outdir = Path(sys.argv[2])
    outdir.mkdir(parents=True, exist_ok=True)

    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }

    # Generate a 1024px master with white squircle background + composited icon
    master = generate_master(source, 1024)

    for name, size in sizes.items():
        out = outdir / name
        # Copy master then resize
        out.write_bytes(master)
        subprocess.run(
            ["sips", "--resampleHeightWidth", str(size), str(size), str(out)],
            capture_output=True,
        )


def generate_master(source: Path, size: int) -> bytes:
    """Create a master icon: white squircle + source image composited on top."""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        # Fallback: just use source directly if Pillow not available
        print("Warning: Pillow not installed, skipping squircle background")
        return source.read_bytes()

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Draw white macOS squircle (continuous rounded rect)
    # macOS icon inset is ~10%, corner radius ~22.37% of icon size
    inset = int(size * 0.05)
    radius = int(size * 0.2237)
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(bg)
    draw.rounded_rectangle(
        [inset, inset, size - inset, size - inset],
        radius=radius,
        fill=(255, 255, 255, 255),
    )
    canvas.paste(bg, (0, 0), bg)

    # Load and scale source icon (icon.json has scale 1.1 but the image
    # itself should fill most of the squircle area)
    icon = Image.open(source).convert("RGBA")
    # Scale icon to fit within the squircle with some padding
    icon_size = int(size * 0.78)
    icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
    offset = (size - icon_size) // 2
    canvas.paste(icon, (offset, offset), icon)

    # Save to bytes
    import io
    buf = io.BytesIO()
    canvas.save(buf, format="PNG")
    return buf.getvalue()


if __name__ == "__main__":
    main()
