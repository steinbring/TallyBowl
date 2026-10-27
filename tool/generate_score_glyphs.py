#!/usr/bin/env python3
"""Generate offline OCR glyph templates from OFL Roboto (Pillow required).

Usage: python3 tool/generate_score_glyphs.py /path/to/Roboto-variable.ttf
The source font is development-only; no network/font download occurs in the app.
"""
import hashlib
import json
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

source = Path(sys.argv[1])
font = ImageFont.truetype(str(source), 80)
axes = font.get_variation_axes()
variants = []
for weight in [400, 500, 600, 700, 800, 900]:
    values = [a['default'] for a in axes]
    values[next(i for i, a in enumerate(axes) if a['name'] == b'Weight')] = weight
    font.set_variation_by_axes(values)
    for char in '0123456789X/':
        image = Image.new('L', (140, 140))
        ImageDraw.Draw(image).text((10, 0), char, font=font, fill=255)
        image = image.crop(image.getbbox()).resize((24, 32), Image.Resampling.BILINEAR)
        variants.append({'text': char, 'mask': ''.join('1' if p > 127 else '0' for p in image.getdata())})
Path('assets/recognition/glyphs.json').write_text(json.dumps({
    'font': 'Roboto', 'license': 'OFL-1.1',
    'source': 'https://github.com/google/fonts/tree/main/ofl/roboto',
    'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
    'width': 24, 'height': 32, 'variants': variants,
}, separators=(',', ':')) + '\n')
