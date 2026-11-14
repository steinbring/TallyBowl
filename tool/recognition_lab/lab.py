#!/usr/bin/env python3
"""Private, offline corpus validation and a strict paired release gate (stdlib only)."""
import argparse
import hashlib
import json
from pathlib import Path

SPLITS = {'train', 'validation', 'test', 'regression'}
STATUSES = {'complete', 'incomplete', 'conflict', 'unsupported', 'unidentified'}


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def validate(document):
    """Split BEFORE cropping/augmentation; all rows of a photo stay together."""
    if document.get('schema') != 1 or not document.get('cases'):
        raise ValueError('Expected schema 1 and a nonempty cases list')
    ids, photos, groups, families = set(), {}, {}, {}
    for case in document['cases']:
        case_id = case['id']
        if not isinstance(case_id, str) or not case_id.replace('-', '').isalnum() or case_id in ids:
            raise ValueError('Case IDs must be unique opaque alphanumeric IDs')
        ids.add(case_id)
        split = case['split']
        if split not in SPLITS or case['status'] not in STATUSES:
            raise ValueError(f'{case_id}: invalid split/status')
        for key in ['group', 'family', 'path', 'sha256']:
            if not case.get(key):
                raise ValueError(f'{case_id}: missing {key}')
        for mapping, key in [(photos, case['sha256']), (groups, case['group'])]:
            if key in mapping and mapping[key] != split:
                raise ValueError(f'{case_id}: photo/capture group leaks across splits')
            mapping[key] = split
        families.setdefault(case['family'], set()).add(split)
        if digest(case['path']) != case['sha256']:
            raise ValueError(f'{case_id}: original photo hash changed')
        if not case.get('profile', {}).get('name'):
            raise ValueError(f'{case_id}: missing local profile')
        if case['status'] == 'complete':
            if len(case.get('frames', [])) != 10 or len(case.get('cumulative', [])) != 10:
                raise ValueError(f'{case_id}: complete gold needs ten frames/checkpoints')
    for family in document.get('heldOutFamilies', []):
        if family not in families or families[family] != {'test'}:
            raise ValueError('Held-out layout families must occur only in test')
    return document


def gate(baseline, candidate, allow_pipeline_change=False):
    """A paired gate, never an aggregate accuracy tradeoff. Missing cases fail."""
    keys = ['schema', 'manifestSha256', 'engine', 'nativeFingerprint']
    if not allow_pipeline_change:
        keys.append('pipelineSha256')
    for key in keys:
        if baseline[key] != candidate[key]:
            raise ValueError(f'Unpaired reports: {key} differs')
    for report in [baseline, candidate]:
        if not report.get('complete') or report.get('expectedCases') != len(report['cases']):
            raise ValueError('Incomplete evaluation report')
        if any(r.get('error') for r in report['cases']):
            raise ValueError('Native/evaluation errors must be resolved before comparison')
    old = {r['id']: r for r in baseline['cases']}
    new = {r['id']: r for r in candidate['cases']}
    if len(old) != len(baseline['cases']) or len(new) != len(candidate['cases']) or old.keys() != new.keys():
        raise ValueError('Duplicate or missing cases')
    regressions, wrong, failures, gains = [], [], [], []
    for case_id, before in old.items():
        after = new[case_id]
        if before['status'] != after['status'] or before['split'] != after['split']:
            raise ValueError('Case labels changed')
        if before['exact'] and not after['exact']:
            regressions.append(case_id)
        if after['wrongAutomatic']:
            wrong.append(case_id)
        if after.get('error') or after['calls'] > 4:
            failures.append(case_id)
        if after['exact'] and not before['exact']:
            gains.append(case_id)
    safe = not (regressions or wrong or failures)
    return {'engine': candidate['engine'], 'safe': safe,
            'promotable': safe and bool(gains), 'gains': gains,
            'regressions': regressions, 'wrongAutomatic': wrong, 'failures': failures}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    check = sub.add_parser('validate')
    check.add_argument('manifest', type=Path)
    compare = sub.add_parser('gate')
    compare.add_argument('--allow-pipeline-change', action='store_true',
                         help='Explicitly compare an intentional Dart layout/segmentation change')
    compare.add_argument('reports', type=Path, nargs=4,
                         metavar='REPORT', help='Apple baseline, candidate; Android baseline, candidate')
    args = parser.parse_args()
    if args.command == 'validate':
        doc = validate(json.loads(args.manifest.read_text()))
        print(json.dumps({'valid': True, 'cases': len(doc['cases']),
                          'photos': len({c['sha256'] for c in doc['cases']})}))
    else:
        reports = [json.loads(p.read_text()) for p in args.reports]
        engines = [gate(reports[0], reports[1], args.allow_pipeline_change),
                   gate(reports[2], reports[3], args.allow_pipeline_change)]
        if {r['engine'] for r in engines} != {'apple', 'android'}:
            raise ValueError('Both engine pairs are required')
        if reports[0]['manifestSha256'] != reports[2]['manifestSha256']:
            raise ValueError('Both engines must evaluate the same corpus')
        promotable = all(r['safe'] for r in engines) and any(r['gains'] for r in engines)
        result = {'photoGatePassed': promotable, 'engines': engines,
                  'note': 'Also require held-out glyph safety and fresh layout-family tests before release.'}
        print(json.dumps(result, indent=2))
        raise SystemExit(0 if promotable else 1)


if __name__ == '__main__':
    main()
