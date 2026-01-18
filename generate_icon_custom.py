#!/usr/bin/env python3
"""Generate app icon on any theme using Nano Banana Pro"""

import os
import sys
import base64
import subprocess
import shutil
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image, ImageDraw

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY_PAID"))


def create_squircle_mask(size, radius_ratio=0.223):
    """Creates a standard macOS squircle mask."""
    w, h = size
    radius = int(min(w, h) * radius_ratio)

    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), size], radius=radius, fill=255)
    return mask


def generate_icon_sizes(source_path, output_dir):
    """Generates all required icon sizes from the source image."""
    output_dir = Path(output_dir)
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)

    img = Image.open(source_path).convert("RGBA")

    sizes = [16, 32, 128, 256, 512]

    for size in sizes:
        resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
        mask = create_squircle_mask((size, size))

        final_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        final_img.paste(resized_img, (0, 0), mask=mask)
        final_img.save(output_dir / f"icon_{size}x{size}.png")

        size_2x = size * 2
        resized_img_2x = img.resize((size_2x, size_2x), Image.Resampling.LANCZOS)
        mask_2x = create_squircle_mask((size_2x, size_2x))

        final_img_2x = Image.new('RGBA', (size_2x, size_2x), (0, 0, 0, 0))
        final_img_2x.paste(resized_img_2x, (0, 0), mask=mask_2x)
        final_img_2x.save(output_dir / f"icon_{size}x{size}@2x.png")

    print(f"Generated iconset at {output_dir}")


def generate_icns(iconset_path, output_path):
    """Runs iconutil to generate the .icns file."""
    try:
        subprocess.run(
            ["iconutil", "-c", "icns", str(iconset_path), "-o", str(output_path)],
            check=True,
            capture_output=True
        )
        print(f"Successfully compiled .icns to {output_path}")
    except subprocess.CalledProcessError as e:
        print(f"Error running iconutil: {e.stderr.decode()}")
    except FileNotFoundError:
        print("Warning: 'iconutil' not found. Are you on macOS? Skipping .icns generation.")


def build_prompt(theme: str, style: str = "modern") -> str:
    """Build the generation prompt for the given theme."""

    style_hints = {
        "modern": "Clean, modern, professional vector-like graphic with subtle gradients.",
        "flat": "Flat design, bold colors, no gradients or shadows.",
        "skeuomorphic": "Realistic 3D appearance with textures, shadows, and depth.",
        "minimal": "Ultra-minimalist, single color on white, simple geometric shapes.",
        "playful": "Bright colors, rounded shapes, friendly and approachable style.",
    }

    style_desc = style_hints.get(style, style_hints["modern"])

    return f"""Create a raw app icon texture for: "{theme}".

CRITICAL INSTRUCTION: Generate a FULL BLEED SQUARE image.
- DO NOT render a rounded icon shape inside a background.
- DO NOT add drop shadows or 3D borders around the edges.
- The image must look like a flat square texture that fills the ENTIRE canvas 100%.

Design requirements:
- A central symbol or illustration representing the theme "{theme}".
- Use harmonious, professional color palette appropriate for the theme.
- Background: Solid or subtle gradient that extends to all 4 corners.
- Style: {style_desc}
"""


def generate_icon(theme: str, output_name: str = "custom_icon", style: str = "modern"):
    """Generate an icon for the given theme."""

    prompt = build_prompt(theme, style)

    config = types.GenerateContentConfig(
        response_modalities=['TEXT', 'IMAGE'],
        image_config=types.ImageConfig(
            aspect_ratio="1:1",
        ),
    )

    print(f"Generating icon for theme: '{theme}' (style: {style})...")
    response = client.models.generate_content(
        model="nano-banana-pro-preview",
        contents=[prompt],
        config=config,
    )

    for part in response.candidates[0].content.parts:
        if part.inline_data is not None:
            raw_data = part.inline_data.data
            image_data = raw_data if isinstance(raw_data, bytes) else base64.b64decode(raw_data)

            base_path = Path(__file__).parent
            raw_output_path = base_path / f"{output_name}_generated.png"
            with open(raw_output_path, 'wb') as f:
                f.write(image_data)
            print(f"Raw icon saved: {raw_output_path}")

            iconset_path = base_path / f"{output_name}.iconset"
            icns_path = base_path / f"{output_name}.icns"

            generate_icon_sizes(raw_output_path, iconset_path)
            generate_icns(iconset_path, icns_path)

            return

    print("No image generated.")


def main():
    if len(sys.argv) > 1:
        theme = sys.argv[1]
        output_name = sys.argv[2] if len(sys.argv) > 2 else "custom_icon"
        style = sys.argv[3] if len(sys.argv) > 3 else "modern"
    else:
        print("Icon Generator")
        print("-" * 40)
        theme = input("Theme (e.g., 'Music Player', 'Weather App'): ").strip()
        if not theme:
            print("Theme is required.")
            sys.exit(1)

        output_name = input("Output name [custom_icon]: ").strip() or "custom_icon"

        print("\nAvailable styles: modern, flat, skeuomorphic, minimal, playful")
        style = input("Style [modern]: ").strip() or "modern"

    generate_icon(theme, output_name, style)


if __name__ == "__main__":
    main()
