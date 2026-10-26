#!/usr/bin/env python3
"""Inspect an exported .app, including nested certificate consistency.

Run after Xcode distribution export (expand a Mac .pkg or unzip an IPA first).
This never signs, uploads, changes trust, or changes the source app. A valid
codesign --deep result alone does not catch ITMS-90284 on resource bundles.
"""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import tempfile


def command(*args):
    result = subprocess.run(args, capture_output=True)
    if result.returncode:
        raise ValueError(result.stderr.decode(errors="replace").strip())
    return result.stdout


def info(bundle):
    for relative in ("Contents/Info.plist", "Info.plist", "Resources/Info.plist"):
        path = bundle / relative
        if path.is_file():
            return plistlib.loads(path.read_bytes())
    return {}


def leaf_certificate(target, temporary, index):
    prefix = temporary / str(index)
    result = subprocess.run(
        ["codesign", "-d", f"--extract-certificates={prefix}", str(target)],
        capture_output=True,
    )
    leaf = Path(str(prefix) + "0")
    return leaf.read_bytes() if result.returncode == 0 and leaf.exists() else None


def inspect(app):
    metadata = info(app)
    mac = (app / "Contents").is_dir()
    profile_path = app / ("Contents/embedded.provisionprofile" if mac else "embedded.mobileprovision")
    profile = plistlib.loads(command("security", "cms", "-D", "-i", str(profile_path)))
    options = plistlib.loads((Path(__file__).resolve().parents[1] / "release/apple/ExportOptions.plist").read_bytes())
    team = options["teamID"]
    bundle_id = "app.jws.tallybowl"
    errors = []
    if metadata.get("CFBundleIdentifier") != bundle_id or profile.get("TeamIdentifier") != [team]:
        errors.append("Unexpected app identifier or profile team")
    identifier_key = "com.apple.application-identifier" if mac else "application-identifier"
    if profile.get("Entitlements", {}).get(identifier_key) != f"{team}.{bundle_id}":
        errors.append("Profile must have the explicit TestFlight application identifier")
    if profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices"):
        errors.append("Profile is for device/developer distribution, not App Store distribution")
    if profile.get("Entitlements", {}).get("get-task-allow"):
        errors.append("Provisioning profile permits debugging")
    if profile["ExpirationDate"] <= datetime.now(timezone.utc).replace(tzinfo=None):
        errors.append("Provisioning profile has expired")
    command("codesign", "--verify", "--deep", "--strict", str(app))
    entitlements = plistlib.loads(command("codesign", "-d", "--entitlements", ":-", "--xml", str(app)))
    if entitlements.get(identifier_key) != f"{team}.{bundle_id}":
        errors.append("Signed application identifier does not match the expected app")
    if entitlements.get("com.apple.developer.team-identifier") != team:
        errors.append("Signed team identifier does not match the profile")
    for key in ("get-task-allow", "com.apple.security.get-task-allow", "com.apple.security.cs.allow-jit", "com.apple.security.cs.disable-library-validation"):
        if entitlements.get(key):
            errors.append(f"Forbidden distribution entitlement: {key}")
    if mac and entitlements.get("com.apple.security.app-sandbox") is not True:
        errors.append("Mac app sandbox is missing")
    if not mac and entitlements.get("beta-reports-active") is not True:
        errors.append("iPad TestFlight entitlement is missing")

    # Resource-only bundles may be unsigned. Any existing signature, including
    # on such a bundle, must use the app/profile's distribution certificate.
    suffixes = {".app", ".framework", ".bundle", ".xpc", ".appex", ".dylib"}
    targets = [app] + sorted(p for p in app.rglob("*") if p.suffix in suffixes and not p.is_symlink())
    signed = 0
    unsigned_resources = 0
    with tempfile.TemporaryDirectory(prefix="tallybowl-cert-check-") as directory:
        temporary = Path(directory)
        root_leaf = leaf_certificate(app, temporary, 0)
        if root_leaf is None or root_leaf not in profile.get("DeveloperCertificates", []):
            errors.append("App certificate is absent from its provisioning profile")
        for index, target in enumerate(targets, 1):
            leaf = leaf_certificate(target, temporary, index)
            executable = target.suffix == ".dylib" or bool(info(target).get("CFBundleExecutable"))
            relative = "." if target == app else str(target.relative_to(app))
            if leaf is None:
                if executable or target.suffix != ".bundle" or (target / "Contents/_CodeSignature").exists() or (target / "_CodeSignature").exists():
                    errors.append(f"Missing distribution certificate: {relative}")
                else:
                    unsigned_resources += 1
                continue
            signed += 1
            if leaf != root_leaf:
                errors.append(f"Certificate differs from app/profile (ITMS-90284): {relative}")
    return {
        "app": str(app),
        "version": metadata.get("CFBundleShortVersionString"),
        "build": metadata.get("CFBundleVersion"),
        "team": team,
        "profile_certificate_sha256": hashlib.sha256(root_leaf).hexdigest() if root_leaf else None,
        "signed_bundles_checked": signed,
        "unsigned_resource_bundles": unsigned_resources,
        "errors": errors,
        "passed": not errors,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        report = inspect(args.app.resolve())
    except (ValueError, OSError, plistlib.InvalidFileException, KeyError) as error:
        report = {"passed": False, "errors": [str(error)]}
    encoded = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded)
    print(encoded, end="")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
