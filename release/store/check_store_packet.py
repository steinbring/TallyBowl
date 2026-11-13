#!/usr/bin/env python3
"""Validate the prepared public metadata/artwork; optionally hash signed packages."""
import argparse,base64,hashlib,json,struct
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--artifacts',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parent
metadata=json.loads((root/'en-US.json').read_text());text=metadata['localizations']['en-US']
for key,limit in {'title':30,'subtitle':30,'shortDescription':80,'promotionalText':170,'description':4000,'appleDescription':4000,'keywords':100}.items():
 if key in text:
  assert 0<len(text[key])<=limit,(key,len(text[key]),limit)
for key in ['supportUrl','marketingUrl','privacyPolicyUrl']:
 assert text[key].startswith('https://'),key
manifest=json.loads((root/'assets-manifest.json').read_text());assert len(manifest['assets'])==9
for item in manifest['assets']:
 data=(root/'assets'/item['file']).read_bytes();assert data[:8]==b'\x89PNG\r\n\x1a\n'
 width,height,depth,color=struct.unpack('>IIBB',data[16:26])
 assert (width,height)==(item['width'],item['height']),item['file']
 assert color==2 and depth==8 and item['alpha'] is False,item['file']
 assert len(data)==item['bytes'],item['file']
provenance=json.loads((root/'asset-provenance.json').read_text())
# Certificate fingerprints are public; private signing files must never enter this packet.
for file in root.rglob('*'):
 if file.is_file():
  assert file.suffix.lower() not in ['.p12','.pfx','.jks','.keystore','.mobileprovision'],file
  if file.suffix.lower()=='.pem':
   content=file.read_text();assert 'PRIVATE KEY' not in content,file
   der=base64.b64decode(''.join(line for line in content.splitlines() if not line.startswith('---')))
   assert len(der)>500,file
verification=json.loads((root/'package-verification.json').read_text())
if a.artifacts:
 for artifact in verification['artifacts']:
  data=(a.artifacts/artifact['fileName']).read_bytes()
  assert len(data)==artifact['bytes'],artifact['fileName']
  assert hashlib.sha256(data).hexdigest()==artifact['sha256'],artifact['fileName']
print(metadata['appName']+': metadata limits, 9 opaque PNG dimensions, public-only certificates and package records passed'+('; signed package hashes matched' if a.artifacts else ''))
