#!/usr/bin/env bash
set -euo pipefail

patch_dir=$(cd -- "$(dirname -- "$0")" && pwd)
repo_dir="$patch_dir/t3code"
output_dir="$patch_dir/releases"
trap 'echo "Release failed at line $LINENO. Local changes were left for inspection." >&2' ERR

for tool in git node vp java; do
  command -v "$tool" >/dev/null || { echo "Required tool missing: $tool" >&2; exit 1; }
done
if [[ -z "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" ]]; then
  echo "Set ANDROID_HOME to your Android SDK directory." >&2
  exit 1
fi

if [[ ! -e "$repo_dir" && ! -L "$repo_dir" ]]; then
  git clone https://github.com/pingdotgg/t3code.git "$repo_dir"
fi
if [[ -L "$repo_dir" || ! -d "$repo_dir/.git" ]]; then
  echo "Expected a separate Git clone at $repo_dir." >&2
  exit 1
fi
git -C "$repo_dir" fetch origin --tags
latest_tag=$(git -C "$repo_dir" tag --list 'v*' --sort=-version:refname |
  sed -n '/^v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$/ { p; q; }')
[[ -n "$latest_tag" ]] || { echo "No stable version tags found." >&2; exit 1; }
echo "Discarding tracked changes and untracked files in $repo_dir"
git -C "$repo_dir" reset --hard HEAD
git -C "$repo_dir" clean -fd
git -C "$repo_dir" switch --detach "$latest_tag"
cd "$repo_dir"
node --input-type=module -e '
  import { readFileSync } from "node:fs";
  const required = JSON.parse(readFileSync("package.json", "utf8")).engines.node;
  if (process.versions.node !== required) {
    console.error(`Use Node ${required} for this release (current: ${process.versions.node}).`);
    process.exit(1);
  }
'
echo "Building T3 Code $latest_tag with e-ink patches"
vp install --frozen-lockfile

export PATH="$repo_dir/apps/mobile/node_modules/.bin:$repo_dir/node_modules/.bin:$PATH"
git apply --check "$patch_dir/01-android-fonts.patch"
git apply "$patch_dir/01-android-fonts.patch"
if ! git apply --check "$patch_dir/02-eink-styling.patch"; then
  git apply -R "$patch_dir/01-android-fonts.patch"
  exit 1
fi
git apply "$patch_dir/02-eink-styling.patch"
cd apps/mobile
node scripts/generate-highlights.mts --styles-only
vp test run src/lib/highlights.test.ts scripts/generate-highlights.test.ts

export APP_VARIANT=preview
export T3CODE_MOBILE_UPDATES_ENABLED=0
export EXPO_NO_GIT_STATUS=1
expo prebuild --clean --platform android --no-install
cd android
./gradlew :app:assembleRelease

apk="$repo_dir/apps/mobile/android/app/build/outputs/apk/release/app-release.apk"
[[ -f "$apk" ]] || { echo "Expected APK not found: $apk" >&2; exit 1; }
mkdir -p "$output_dir"
output="$output_dir/t3code-${latest_tag}-eink.apk"
cp "$apk" "$output"
echo "APK: $output"
