#!/usr/bin/env bash
set -euo pipefail
patch_dir=$(cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(git rev-parse --show-toplevel)
cd "$repo_dir"
export PATH="$repo_dir/node_modules/.bin:$PATH"
command -v vp >/dev/null || { echo "Install repository dependencies first (vp i)." >&2; exit 1; }
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
