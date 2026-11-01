#!/usr/bin/env python3
"""Generate offline OCR glyph templates from Roboto-family fonts (Pillow required).

Usage: python3 tool/generate_score_glyphs.py Roboto-variable.ttf [RobotoSlab-variable.ttf]
The source font is development-only; no network/font download occurs in the app.
"""
import hashlib
import json
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

source = Path(sys.argv[1])
variants = []


def render(path, characters, weights):
    font = ImageFont.truetype(str(path), 80)
    axes = font.get_variation_axes()
    for weight in weights:
        values = [a['default'] for a in axes]
        values[next(i for i, a in enumerate(axes) if a['name'] == b'Weight')] = weight
        font.set_variation_by_axes(values)
        for char in characters:
            image = Image.new('L', (140, 140))
            ImageDraw.Draw(image).text((10, 0), char, font=font, fill=255)
            image = image.crop(image.getbbox()).resize((24, 32), Image.Resampling.BILINEAR)
            variants.append({'text': char, 'mask': ''.join('1' if p > 127 else '0' for p in image.getdata())})


render(source, '0123456789X/', [400, 500, 600, 700, 800, 900])
document = {
    'font': 'Roboto', 'license': 'OFL-1.1',
    'source': 'https://github.com/google/fonts/tree/main/ofl/roboto',
    'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
    'width': 24, 'height': 32, 'variants': variants,
}
if len(sys.argv) > 2:
    slab = Path(sys.argv[2])
    # Monitor fonts often give 1 a wide foot. Keep all other digit templates
    # unchanged; the new variant must satisfy the same classification margin.
    weights = [400, 500, 600, 700, 800, 900]
    render(slab, '1', weights)
    document['additionalFonts'] = [{
        'font': 'Roboto Slab', 'characters': '1', 'weights': weights,
        'license': 'Apache-2.0',
        'copyright': 'Copyright 2018 The Roboto Slab Project Authors',
        'modifications': 'Rendered numeral 1 as 24x32 binary masks at the listed weights.',
        'source': 'https://github.com/googlefonts/robotoslab/tree/67af3ce9c4ca574419e1295b6165a2eeee112e6e',
        'sha256': hashlib.sha256(slab.read_bytes()).hexdigest(),
    }]
Path('assets/recognition/glyphs.json').write_text(json.dumps(document, separators=(',', ':')) + '\n')
