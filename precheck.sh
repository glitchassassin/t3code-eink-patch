#!/usr/bin/env bash
set -euo pipefail

patch_dir=$(cd -- "$(dirname -- "$0")" && pwd)
repo_dir="$patch_dir/t3code"
output_dir="$patch_dir/releases"
for tool in git tar; do
  command -v "$tool" >/dev/null || { echo "Required tool missing: $tool" >&2; exit 1; }
done

if [[ ! -e "$repo_dir" && ! -L "$repo_dir" ]]; then
  git clone https://github.com/pingdotgg/t3code.git "$repo_dir"
fi
if [[ -L "$repo_dir" || ! -d "$repo_dir/.git" ]]; then
  echo "Expected a separate Git clone at $repo_dir." >&2
  exit 1
fi
git -C "$repo_dir" fetch origin --tags
tag=${1:-}
if [[ -z "$tag" ]]; then
  tag=$(git -C "$repo_dir" tag --list 'v*' --sort=-version:refname |
    sed -n '/^v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$/ { p; q; }')
fi
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Expected stable version vX.Y.Z." >&2; exit 1; }
commit=$(git -C "$repo_dir" rev-parse --verify "refs/tags/$tag^{commit}")

# Preserve source edits before removing old patches. Ignored dependencies,
# environment files, and build caches remain in place.
mkdir -p "$output_dir"
backup_dir=$(mktemp -d "$output_dir/precheck-backup-XXXXXXXX")
git -C "$repo_dir" rev-parse HEAD > "$backup_dir/source-commit"
git -C "$repo_dir" diff --binary HEAD > "$backup_dir/source.patch"
git -C "$repo_dir" ls-files --others --exclude-standard -z > "$backup_dir/untracked-files"
if [[ -s "$backup_dir/untracked-files" ]]; then
  tar -C "$repo_dir" --null -T "$backup_dir/untracked-files" -cf "$backup_dir/untracked.tar"
fi
key="$repo_dir/apps/mobile/android/app/debug.keystore"
if [[ -f "$key" ]]; then
  cp -p "$key" "$backup_dir/debug.keystore"
fi
echo "Source backup: $backup_dir"
git -C "$repo_dir" reset --hard HEAD
git -C "$repo_dir" clean -fd
git -C "$repo_dir" switch --detach "$tag"
if [[ -f "$backup_dir/debug.keystore" ]]; then
  mkdir -p "$(dirname -- "$key")"
  cp -p "$backup_dir/debug.keystore" "$key"
fi

echo "Prepared $tag ($commit)"
echo "Required Node version (package.json engines):"
git -C "$repo_dir" show HEAD:package.json | sed -n '/"engines"[[:space:]]*:/,/}/p'
echo "Checking patches; conflicts must be repaired before release.sh."
status=0
if ! bash "$patch_dir/check-tools.sh"; then
  status=1
fi
for patch in "$patch_dir/01-android-fonts.patch" "$patch_dir/02-eink-styling.patch"; do
  if ! git -C "$repo_dir" apply --check "$patch"; then
    status=1
  fi
done
exit "$status"
