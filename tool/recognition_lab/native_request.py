#!/usr/bin/env python3
"""Exact-request native OCR cache, used only by the development Flutter evaluator."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = 'app.jws.tallybowl'
REMOTE = 'cache/recognition-lab'


def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, capture_output=True, timeout=90, **kwargs).stdout


def sha(data):
    return hashlib.sha256(data).hexdigest()


def fingerprint(engine, adb=None, probe=None):
    files = ([ROOT / 'apple/ScoreTextRecognition.swift', Path(probe)] if engine == 'apple' else
             list((ROOT / 'android/app/src/main/kotlin/app/jws/tallybowl').glob('*.kt')) +
             [ROOT / 'android/app/build.gradle.kts', ROOT / 'android/app/src/androidTest/kotlin/app/jws/tallybowl/RecognitionLabTest.kt'])
    runtime = platform.mac_ver()[0] if engine == 'apple' else run(adb + ['shell', 'getprop', 'ro.build.fingerprint']).decode().strip()
    return sha(json.dumps({'runtime': runtime, 'sources': {str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else p.name: sha(p.read_bytes()) for p in sorted(files)}} , sort_keys=True).encode())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine', choices=['apple', 'android'], required=True)
    parser.add_argument('--cache', type=Path, required=True)
    parser.add_argument('--probe', default=str(ROOT / 'build/recognition-lab/vision-probe'))
    parser.add_argument('--serial', default='emulator-5554')
    parser.add_argument('--fingerprint', action='store_true')
    parser.add_argument('request', nargs='?', type=Path)
    parser.add_argument('output', nargs='?', type=Path)
    args = parser.parse_args()
    adb = None
    if args.engine == 'android':
        if not args.serial.startswith('emulator-'):
            raise ValueError('Only an explicitly selected emulator is supported')
        adb = [os.environ.get('ANDROID_ADB', str(Path.home() / 'Library/Android/sdk/platform-tools/adb')), '-s', args.serial]
        if run(adb + ['shell', 'getprop', 'ro.kernel.qemu']).strip() != b'1':
            raise ValueError('Emulator required')
    version = fingerprint(args.engine, adb, args.probe)
    if args.fingerprint:
        print(version)
        return
    request = json.loads(args.request.read_text())
    photo = Path(request['path']).read_bytes()
    if sha(photo) != request['sha256']:
        raise ValueError('Original photo hash changed')
    key = sha(json.dumps({'engine': args.engine, 'native': version, 'photo': request['sha256'],
                          'args': request['args']}, sort_keys=True, separators=(',', ':')).encode())
    args.cache.mkdir(parents=True, exist_ok=True)
    cached = args.cache / f'{key}.json'
    if not cached.exists():
        temporary = cached.with_suffix('.tmp')
        if args.engine == 'apple':
            run([args.probe, args.request, temporary])
        else:
            run(adb + ['shell', 'run-as', PACKAGE, 'cat', f'{REMOTE}/ready'])
            device_photo = f'{REMOTE}/{request["sha256"]}.photo'
            exists = subprocess.run(adb + ['shell', 'run-as', PACKAGE, 'test', '-f', device_photo], capture_output=True, timeout=10)
            if exists.returncode:
                run(adb + ['push', request['path'], '/data/local/tmp/tallybowl-lab.photo'])
                run(adb + ['shell', 'chmod', '644', '/data/local/tmp/tallybowl-lab.photo'])
                run(adb + ['shell', 'run-as', PACKAGE, 'cp', '/data/local/tmp/tallybowl-lab.photo', device_photo])
                run(adb + ['shell', 'rm', '/data/local/tmp/tallybowl-lab.photo'])
            request['id'] = str(uuid.uuid4())
            # No shell interpolation of private paths or user text.
            transfer = args.request.with_suffix('.transfer.json')
            transfer.write_text(json.dumps(request))
            run(adb + ['push', transfer, '/data/local/tmp/tallybowl-lab.request'])
            run(adb + ['shell', 'chmod', '644', '/data/local/tmp/tallybowl-lab.request'])
            run(adb + ['shell', 'run-as', PACKAGE, 'cp', '/data/local/tmp/tallybowl-lab.request', f'{REMOTE}/request.tmp'])
            run(adb + ['shell', 'run-as', PACKAGE, 'mv', f'{REMOTE}/request.tmp', f'{REMOTE}/request.json'])
            run(adb + ['shell', 'rm', '/data/local/tmp/tallybowl-lab.request'])
            transfer.unlink()
            for _ in range(600):
                response = subprocess.run(adb + ['exec-out', 'run-as', PACKAGE, 'cat', f'{REMOTE}/response.json'], capture_output=True, timeout=10)
                try:
                    value = json.loads(response.stdout)
                except (ValueError, UnicodeDecodeError):
                    value = {}
                if value.get('id') == request['id']:
                    if 'error' in value:
                        raise RuntimeError(value['error'])
                    temporary.write_text(json.dumps(value['output']))
                    break
                time.sleep(.1)
            else:
                raise TimeoutError('Native worker did not reply')
        if not isinstance(json.loads(temporary.read_text()), list):
            raise ValueError('Invalid native output')
        temporary.replace(cached)
    args.output.write_bytes(cached.read_bytes())


if __name__ == '__main__':
    main()
