#!/usr/bin/env bash
set -euo pipefail

patch_dir=$(cd -- "$(dirname -- "$0")" && pwd)
repo_dir="$patch_dir/t3code"
output_dir="$patch_dir/releases"
trap 'echo "Release failed at line $LINENO. Local changes were left for inspection." >&2' ERR

bash "$patch_dir/check-tools.sh"

if [[ -L "$repo_dir" || ! -d "$repo_dir/.git" ]]; then
  echo "Run ./precheck.sh first to prepare the source checkout." >&2
  exit 1
fi
latest_tag=${1:-}
if [[ -z "$latest_tag" ]]; then
  latest_tag=$(git -C "$repo_dir" tag --points-at HEAD --list 'v*' --sort=-version:refname |
    sed -n '/^v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$/ { p; q; }')
fi
[[ "$latest_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Expected stable version vX.Y.Z." >&2; exit 1; }
source_commit=$(git -C "$repo_dir" rev-parse --verify "refs/tags/$latest_tag^{commit}")
if [[ "$(git -C "$repo_dir" rev-parse HEAD)" != "$source_commit" ]]; then
  echo "Checkout is not at $latest_tag. Run ./precheck.sh $latest_tag first." >&2
  exit 1
fi
cd "$repo_dir"
echo "Building T3 Code $latest_tag with e-ink patches"
vp install --frozen-lockfile

export PATH="$repo_dir/apps/mobile/node_modules/.bin:$repo_dir/node_modules/.bin:$PATH"
# Check the entire patch set before changing any source. A retry can reuse
# patches already applied by an earlier build attempt.
patches=("$patch_dir/01-android-fonts.patch" "$patch_dir/02-eink-styling.patch")
for patch in "${patches[@]}"; do
  if git apply --reverse --check "$patch" 2>/dev/null; then
    continue
  fi
  git apply --check "$patch"
done
for patch in "${patches[@]}"; do
  if ! git apply --reverse --check "$patch" 2>/dev/null; then
    git apply "$patch"
  fi
done
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
