#!/usr/bin/env python3
"""Train an isolated prototype candidate and measure held-out glyphs (Pillow).

No downloads, production writes, score-based labels, or threshold tuning. Input
is a private JSON catalog of licensed fonts and/or human-labeled foreground masks.
"""
import argparse
from collections import Counter
from copy import deepcopy
import hashlib
import io
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

CHARACTERS = '0123456789X/'
SIZE = (24, 32)
ROOT = Path(__file__).resolve().parents[2]


def normalize(image):
    image = image.convert('L')
    box = image.point(lambda p: 255 if p > 127 else 0).getbbox()
    if box is None:
        raise ValueError('Empty foreground mask')
    return ''.join('1' if p > 127 else '0' for p in
                   image.crop(box).resize(SIZE, Image.Resampling.BILINEAR).get_flattened_data())


def render(source, weight, character):
    font = ImageFont.truetype(source['path'], 80)
    try:
        axes = font.get_variation_axes()
    except OSError:
        axes = []
    if axes:
        font.set_variation_by_axes([weight if a['name'] == b'Weight' else a['default'] for a in axes])
    image = Image.new('L', (160, 160))
    ImageDraw.Draw(image).text((15, 0), character, font=font, fill=255)
    box = image.getbbox()
    if box is None:
        raise ValueError('Font lacks a requested character')
    return image.crop(box)


def samples(source):
    if source['kind'] == 'font':
        return [(c, render(source, weight, c))
                for weight in source.get('weights', [400, 600, 700])
                for c in source.get('characters', CHARACTERS)]
    if source['kind'] == 'mask' and source['label'] in CHARACTERS and len(source['label']) == 1:
        with Image.open(source['path']) as image:
            return [(source['label'], image.convert('L'))]
    raise ValueError('Expected licensed font or labeled foreground mask')


def degraded(image):
    """Deterministic scale, blur, compression and slant; all inherit source split."""
    yield image
    for height, blur, quality, shear in [
        (16, 0, 90, 0), (24, .4, 75, 0), (40, .7, 65, .08),
        (24, .4, 75, -.08), (64, .4, 90, .06),
    ]:
        scaled = image.resize((max(3, round(image.width * height / image.height)), height), Image.Resampling.BILINEAR)
        padded = Image.new('L', (scaled.width + 12, scaled.height + 8))
        padded.paste(scaled, (6, 4))
        padded = padded.transform(padded.size, Image.Transform.AFFINE,
                                  (1, shear, -shear * height / 2, 0, 1, 0), Image.Resampling.BILINEAR)
        padded = padded.filter(ImageFilter.GaussianBlur(blur))
        buffer = io.BytesIO()
        padded.save(buffer, 'JPEG', quality=quality)
        buffer.seek(0)
        with Image.open(buffer) as decoded:
            yield decoded.convert('L')


def classify(mask, templates):
    value = int(mask, 2)
    scores = {}
    for label, template in templates:
        union = (value | template).bit_count()
        score = (value & template).bit_count() / union if union else 0
        scores[label] = max(scores.get(label, 0), score)
    ranked = sorted(scores.items(), key=lambda x: (-x[1], x[0]))
    if ranked[0][1] >= .68 and ranked[0][1] - ranked[1][1] >= .06:
        return ranked[0][0]
    return None


def train(catalog, baseline):
    groups, hashes, families = {}, {}, {}
    for source in catalog['sources']:
        split = source['split']
        if split not in {'train', 'validation', 'test'}:
            raise ValueError('Sources need train, validation or test split')
        actual = hashlib.sha256(Path(source['path']).read_bytes()).hexdigest()
        if source['sha256'] != actual:
            raise ValueError('Source hash changed')
        for mapping, key in [(groups, source['group']), (hashes, actual),
                             (families, source['family'])]:
            if key in mapping and mapping[key] != split:
                raise ValueError('Source, capture group or font/layout family leaks across splits')
            mapping[key] = split
        if source['kind'] == 'font' and (not source.get('license') or not source.get('source')):
            raise ValueError('Fonts need license and source provenance')
    if set(groups.values()) != {'train', 'validation', 'test'}:
        raise ValueError('All three splits are required')
    candidate = deepcopy(baseline)
    variants = candidate['variants']
    seen = {(v['text'], v['mask']) for v in variants}
    for source in catalog['sources']:
        if source['split'] != 'train':
            continue
        for label, image in samples(source):
            # Small stroke-weight changes at source resolution, not fake extra
            # observations of a photo. No validation/test sample enters the bank.
            for style in [image, image.filter(ImageFilter.MinFilter(3)), image.filter(ImageFilter.MaxFilter(3))]:
                mask = normalize(style)
                if (label, mask) not in seen:
                    variants.append({'text': label, 'mask': mask})
                    seen.add((label, mask))
    if len(variants) > 512:
        raise ValueError('Candidate exceeds bounded prototype budget (512)')
    candidate['experiment'] = {
        'method': 'supervised-prototype-expansion-v1',
        'baselineSha256': hashlib.sha256(json.dumps(baseline, sort_keys=True).encode()).hexdigest(),
        'trainingSources': [s for s in catalog['sources'] if s['split'] == 'train'],
    }
    banks = {name: [(v['text'], int(v['mask'], 2)) for v in doc['variants']]
             for name, doc in [('baseline', baseline), ('candidate', candidate)]}
    metrics = {}
    for split in ['validation', 'test']:
        metrics[split] = {}
        observed = [(label, normalize(augmented)) for source in catalog['sources']
                    if source['split'] == split for label, image in samples(source)
                    for augmented in degraded(image)]
        for name, templates in banks.items():
            counts = Counter(correct=0, rejected=0, wrong=0)
            confusions = Counter()
            for label, mask in observed:
                prediction = classify(mask, templates)
                counts['correct' if prediction == label else 'rejected' if prediction is None else 'wrong'] += 1
                if prediction is not None and prediction != label:
                    confusions[f'{label}->{prediction}'] += 1
            metrics[split][name] = dict(samples=len(observed), **counts, confusions=dict(confusions))
        regressions = sum(classify(mask, banks['baseline']) == label and
                          classify(mask, banks['candidate']) != label for label, mask in observed)
        metrics[split]['lostCorrectGlyphs'] = regressions
    return candidate, metrics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('catalog', type=Path)
    parser.add_argument('--baseline', type=Path, default=ROOT / 'assets/recognition/glyphs.json')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    private = (ROOT / 'build/recognition-lab').resolve()
    if any(not p.resolve().is_relative_to(private) for p in [args.output, args.report]):
        raise ValueError('Experimental outputs must stay inside ignored build/recognition-lab')
    if any(p.exists() for p in [args.output, args.report]):
        raise ValueError('Choose fresh output paths; experiments are immutable')
    catalog = json.loads(args.catalog.read_text())
    baseline = json.loads(args.baseline.read_text())
    candidate, metrics = train(catalog, baseline)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(candidate, separators=(',', ':')) + '\n')
    glyph_safe = all(m['candidate']['wrong'] == 0 and m['lostCorrectGlyphs'] == 0
                     for m in metrics.values())
    args.report.write_text(json.dumps({'catalogSha256': hashlib.sha256(args.catalog.read_bytes()).hexdigest(),
                                      'baselineTemplates': len(baseline['variants']),
                                      'candidateTemplates': len(candidate['variants']),
                                      'glyphGatePassed': glyph_safe, 'metrics': metrics}, indent=2))
    print(args.report.read_text())


if __name__ == '__main__':
    main()
