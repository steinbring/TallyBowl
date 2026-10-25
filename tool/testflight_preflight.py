#!/usr/bin/env python3
"""Read-only source/archive checks; never signs, uploads, or declares Apple approval."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = "app.jws.tallybowl"


def plist(path):
    with path.open("rb") as stream:
        return plistlib.load(stream)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, action="append", default=[], help="Inspect an xcarchive; repeat for both targets")
    parser.add_argument("--check-urls", action="store_true", help="Require HTTPS privacy and support URLs to respond (does not verify their content)")
    parser.add_argument("--output", type=Path, help="Optionally write the scoped result as JSON")
    args = parser.parse_args()
    checks = []
    observations = []

    def check(label, action):
        try:
            result = action()
            if result is False:
                raise ValueError("condition not met")
            checks.append({"check": label, "passed": True})
        except Exception as error:
            checks.append({"check": label, "passed": False, "detail": str(error)})

    version_match = re.search(r"^version: (\d+\.\d+\.\d+)\+(\d+)\s*$", (ROOT / "pubspec.yaml").read_text(), re.M)
    if version_match is None:
        parser.exit(1, "Missing numeric pubspec version/build\n")
    version, build = version_match.groups()
    for platform in ("ios", "macos"):
        def manifest_check(platform=platform):
            manifest = plist(ROOT / platform / "Runner/PrivacyInfo.xcprivacy")
            assert manifest["NSPrivacyTracking"] is False
            types = manifest["NSPrivacyAccessedAPITypes"]
            timestamp = next(t for t in types if t["NSPrivacyAccessedAPIType"] == "NSPrivacyAccessedAPICategoryFileTimestamp")
            assert set(timestamp["NSPrivacyAccessedAPITypeReasons"]) == {"C617.1", "3B52.1"}
            project = (ROOT / platform / "Runner.xcodeproj/project.pbxproj").read_text()
            assert "7B7B0020AABBCCDD00112233 /* PrivacyInfo.xcprivacy in Resources */," in project
        check(f"{platform}: app privacy manifest and Resources reference", manifest_check)
    check("generated in-app/Markdown documents agree", lambda: subprocess.run(
        [sys.executable, str(ROOT / "tool/render_documents.py"), "--check"],
        capture_output=True, text=True, check=True))
    check("iPad-only device family", lambda: 'TARGETED_DEVICE_FAMILY = 2;' in (ROOT / "ios/Runner.xcodeproj/project.pbxproj").read_text())
    check("native Mac category", lambda: plist(ROOT / "macos/Runner/Info.plist")["LSApplicationCategoryType"] == "public.app-category.sports")

    def entitlements_check():
        entitlements = plist(ROOT / "macos/Runner/Release.entitlements")
        assert entitlements["com.apple.security.app-sandbox"] is True
        for key in ("com.apple.security.get-task-allow", "com.apple.security.cs.allow-jit", "com.apple.security.cs.disable-library-validation"):
            assert not entitlements.get(key, False), key
        config = (ROOT / "macos/Runner/Configs/Release.xcconfig").read_text()
        assert "ENABLE_HARDENED_RUNTIME = YES" in config
        assert "CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO" in config
    check("Mac release retains strict sandbox/runtime policy", entitlements_check)

    def export_check():
        export = plist(ROOT / "release/apple/ExportOptions.plist")
        assert export["method"] == "app-store-connect"
        assert export["destination"] == "export"
        assert export["manageAppVersionAndBuildNumber"] is False
    check("export template cannot upload by itself", export_check)
    launch = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for name in ("LaunchImage.png", "LaunchImage@2x.png", "LaunchImage@3x.png"):
        check(f"custom launch artwork: {name}", lambda name=name: (launch / name).stat().st_size > 1000)

    for archive_arg in args.archive:
        archive = archive_arg.resolve()
        def archive_check(archive=archive):
            assert archive.suffix == ".xcarchive", "Expected an xcarchive directory"
            apps = list((archive / "Products/Applications").glob("*.app"))
            assert len(apps) == 1, "Expected one top-level app"
            app = apps[0]
            is_mac = (app / "Contents/Info.plist").exists()
            resources = app / "Contents/Resources" if is_mac else app
            info = plist(app / "Contents/Info.plist" if is_mac else app / "Info.plist")
            assert info["CFBundleIdentifier"] == BUNDLE
            assert info["CFBundleShortVersionString"] == version
            assert str(info["CFBundleVersion"]) == build
            platform = "macos" if is_mac else "ios"
            assert plist(resources / "PrivacyInfo.xcprivacy") == plist(ROOT / platform / "Runner/PrivacyInfo.xcprivacy"), "Built app-owned manifest differs from source"
            for document in ("privacy", "guide"):
                copies = [path for path in app.rglob(f"{document}.json") if str(path).endswith(f"assets/documents/{document}.json")]
                assert len(copies) == 1, f"Missing/duplicate bundled {document} document"
                assert copies[0].read_bytes() == (ROOT / f"assets/documents/{document}.json").read_bytes(), f"Stale bundled {document} document"
            assert not (resources / "TallyBowlBuild.json").exists(), "Owner-only package cannot be used"
            assert list((archive / "dSYMs").glob("*.dSYM")), "Missing archive symbols"
            if is_mac:
                binary = app / "Contents/MacOS" / info["CFBundleExecutable"]
                arches = subprocess.check_output(["lipo", "-archs", str(binary)], text=True).split()
                assert {"arm64", "x86_64"}.issubset(arches), arches
                assert info["LSApplicationCategoryType"] == "public.app-category.sports"
            else:
                assert info["UIDeviceFamily"] == [2]
                assert info["MinimumOSVersion"] == "15.0"
            signature = subprocess.run(["codesign", "-dv", "--verbose=4", str(app)], capture_output=True, text=True)
            observations.append({"archive": str(archive), "platform": "macOS" if is_mac else "iPadOS",
                "signature_diagnostic": signature.stderr.strip(), "distribution_validation": "NOT VERIFIED; Organizer validation/export and Apple processing required"})
        check(f"archive contents: {archive}", archive_check)

    if args.check_urls:
        for page in ("privacy", "support"):
            url = f"https://tallybowl.jws.app/{page}"
            def url_check(url=url):
                request = urllib.request.Request(url, headers={"User-Agent": "TallyBowl-release-preflight"})
                with urllib.request.urlopen(request, timeout=15) as response:
                    assert response.status == 200, response.status
                    assert response.geturl().startswith("https://")
                    assert "text/html" in response.headers.get("Content-Type", ""), "Expected a human-readable web page"
            check(f"public URL responds: {url}", url_check)

    report = {
        "checked_at": datetime.now(timezone.utc).isoformat(), "candidate": f"{version}+{build}",
        "scope": "LOCAL CHECKS ONLY. Not TestFlight approval, an upload, or a guarantee of distribution signing.",
        "checks": checks, "archive_observations": observations,
        "manual_gates": ["Approved public contact and live policy/support content", "Developer account/app records/agreements", "Export-compliance and store privacy answers", "Correctly signed production archives; Organizer validation and Apple processing", "Physical TestFlight installation and device acceptance; see docs/TESTFLIGHT.md"],
    }
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(report["scope"])
    for result in checks:
        print(("PASS " if result["passed"] else "FAIL ") + result["check"] + (": " + result["detail"] if "detail" in result else ""))
    print("Manual gates remain; read docs/TESTFLIGHT.md.")
    return 0 if all(result["passed"] for result in checks) else 1


if __name__ == "__main__":
    sys.exit(main())
