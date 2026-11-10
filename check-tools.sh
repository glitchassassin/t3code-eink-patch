#!/usr/bin/env bash
set -euo pipefail

patch_dir=$(cd -- "$(dirname -- "$0")" && pwd)
repo_dir="$patch_dir/t3code"
status=0
for tool in git node vp tar; do
  if ! command -v "$tool" >/dev/null; then
    echo "Required tool missing: $tool" >&2
    status=1
  fi
done

if command -v node >/dev/null && [[ -f "$repo_dir/package.json" ]]; then
  if ! node --input-type=module - "$repo_dir/package.json" <<'JS'
import { readFileSync } from 'node:fs';
const pkg = JSON.parse(readFileSync(process.argv[2], 'utf8'));
console.log(`Required Node: ${pkg.engines.node}; package manager: ${pkg.packageManager}`);
if (process.versions.node !== pkg.engines.node) {
  console.error(`Use Node ${pkg.engines.node} (current: ${process.versions.node}).`);
  process.exitCode = 1;
}
JS
  then
    status=1
  fi
fi
if command -v vp >/dev/null; then
  if ! vp --version; then
    echo "Vite Plus could not run." >&2
    status=1
  fi
fi

# Match Gradle's JAVA_HOME preference, rather than checking a different Java
# on PATH. javac distinguishes a full JDK from a runtime-only installation.
java_bin=java
javac_bin=javac
if [[ -n "${JAVA_HOME:-}" ]]; then
  java_bin="$JAVA_HOME/bin/java"
  javac_bin="$JAVA_HOME/bin/javac"
fi
if ! "$java_bin" -version; then
  echo "Set JAVA_HOME to a usable JDK (17 or newer, compatible with the tagged Gradle wrapper)." >&2
  status=1
fi
if javac_version=$("$javac_bin" -version 2>&1); then
  echo "$javac_version"
  major=$(printf '%s\n' "$javac_version" | sed -nE 's/^javac ([0-9]+).*/\1/p')
  if [[ -z "$major" || "$major" -lt 17 ]]; then
    echo "JDK 17 or newer is required." >&2
    status=1
  fi
else
  echo "A full JDK with javac is required: $javac_version" >&2
  status=1
fi

sdk_dir=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
if [[ -z "$sdk_dir" || ! -d "$sdk_dir" ]]; then
  echo "Set ANDROID_HOME (or ANDROID_SDK_ROOT) to an existing Android SDK." >&2
  status=1
else
  echo "Android SDK: $sdk_dir"
  for component in platforms build-tools; do
    if [[ ! -d "$sdk_dir/$component" ]]; then
      echo "Android SDK is missing $component; install it with Android Studio or sdkmanager." >&2
      status=1
    fi
  done
fi
exit "$status"
