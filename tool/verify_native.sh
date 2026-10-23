#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"

# The Dart analyzer cannot analyze Kotlin or Swift, regardless of exclusions.
# These builds type-check both Apple bridges and Android's Kotlin code; Android
# Lint checks the manifest, native source and resources in addition to compiling.
flutter build apk --debug
(
  cd android
  ./gradlew :app:lintDebug
)
flutter build macos --release
flutter build ios --simulator --debug --no-codesign
