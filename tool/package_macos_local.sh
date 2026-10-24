#!/bin/sh
# Owner-test packaging only. Never use this for notarized/store distribution.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"
source_app='build/macos/Build/Products/Release/TallyBowl!.app'
if [ ! -d "$source_app" ]; then
  echo 'Build first: flutter build macos --release' >&2
  exit 1
fi
signature=$(codesign -dvv "$source_app" 2>&1)
case "$signature" in
  *'Signature=adhoc'*) ;;
  *) echo 'Refusing to re-sign a distribution/development identity. This tool is for ad hoc owner builds only.' >&2; exit 1 ;;
esac
case "$signature" in
  *'TeamIdentifier=not set'*) ;;
  *) echo 'Refusing to change a team-signed app.' >&2; exit 1 ;;
esac
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$source_app/Contents/Info.plist")
mkdir -p build/releases
stage_dir=$(mktemp -d "$repo_dir/build/releases/macos-local.XXXXXX")
trap 'rm -rf "$stage_dir"' EXIT HUP INT TERM
local_app="$stage_dir/TallyBowl!.app"
local_entitlements="$stage_dir/Local.entitlements"
ditto "$source_app" "$local_app"
cp macos/Runner/Release.entitlements "$local_entitlements"
# Ad hoc signatures have no Team ID. Hardened library validation rejects the
# embedded ad hoc Flutter frameworks even when all signatures are valid. Relax
# only this check in the local copy, retaining runtime/sandbox protections and
# omitting get-task-allow/JIT. The production entitlements are never changed.
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.cs.disable-library-validation bool true' "$local_entitlements"
codesign --force --sign - --options runtime --entitlements "$local_entitlements" "$local_app"
codesign --verify --deep --strict "$local_app"
archive="build/releases/TallyBowl-$version-macos.zip"
ditto -c -k --sequesterRsrc --keepParent "$local_app" "$archive"
echo "Packaged local ad hoc build: $archive"
