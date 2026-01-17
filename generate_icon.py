#!/usr/bin/env python3
"""Generate app icon for Worktree Manager using Nano Banana Pro"""

import os
import base64
import subprocess
import shutil
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image, ImageDraw, ImageOps

client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY_PAID"))

def create_squircle_mask(size, radius_ratio=0.223):
    """Creates a standard macOS squircle mask."""
    # macOS icon shape is a superellipse, but a rounded rect with 
    # specific radius is a very close approximation for this purpose.
    # Radius is approx 22.3% of the side length.
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
    
    # Base sizes for macOS icons
    sizes = [16, 32, 128, 256, 512]
    
    for size in sizes:
        # Normal resolution (@1x)
        # We process each size individually to ensure clean edges
        resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
        mask = create_squircle_mask((size, size))
        
        final_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        final_img.paste(resized_img, (0, 0), mask=mask)
        
        final_img.save(output_dir / f"icon_{size}x{size}.png")
        
        # Retina resolution (@2x)
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

def generate_icon():
    prompt = """Create a raw app icon texture for a 'Git Worktree Manager'.
    
    CRITICAL INSTRUCTION: Generate a FULL BLEED SQUARE image. 
    - DO NOT render a rounded icon shape inside a background.
    - DO NOT add drop shadows or 3D borders around the edges.
    - The image must look like a flat square texture that fills the ENTIRE canvas 100%.
    
    Design:
    - A central abstract tree symbol (git branches/nodes style).
    - Colors: Deep Teal (#0D9488) to Purple (#8B5CF6) gradient.
    - Background: Solid white or very light gray gradient. The background must extend to all 4 corners.
    - Style: Clean, modern, professional vector-like graphic.
    """

    config = types.GenerateContentConfig(
        response_modalities=['TEXT', 'IMAGE'],
        image_config=types.ImageConfig(
            aspect_ratio="1:1",
        ),
    )

    print("Generating base icon image...")
    response = client.models.generate_content(
        model="nano-banana-pro-preview",
        contents=[prompt],
        config=config,
    )

    for part in response.candidates[0].content.parts:
        if part.inline_data is not None:
            raw_data = part.inline_data.data
            image_data = raw_data if isinstance(raw_data, bytes) else base64.b64decode(raw_data)

            # Save raw generated image
            raw_output_path = Path(__file__).parent / "icon_generated.png"
            with open(raw_output_path, 'wb') as f:
                f.write(image_data)
            print(f"Raw icon saved: {raw_output_path}")
            
            # Process into iconset and icns
            iconset_path = Path(__file__).parent / "AppIcon.iconset"
            icns_path = Path(__file__).parent / "AppIcon.icns"
            
            generate_icon_sizes(raw_output_path, iconset_path)
            generate_icns(iconset_path, icns_path)
            
            return

    print("No image generated.")

if __name__ == "__main__":
    generate_icon()
