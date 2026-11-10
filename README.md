# T3 Code e-ink patch

Android light-mode code and diff styling for a Boox NoteAir5C: black
monospace text, heavier base weight, bold names, bold italic comments,
italic literals, and stronger diff colors.

## How to use

Install Vite Plus (`vp`), the Node version required by T3 Code's
`package.json`, JDK 17, and the Android SDK. Set `JAVA_HOME` and
`ANDROID_HOME` to their installation directories, then run:

```sh
./precheck.sh          # fetch and prepare the highest stable tag
./precheck.sh v0.1.8   # or prepare an exact stable tag
# Inspect upstream changes and patch-check results; repair patches if needed.
# Select the Node version reported by precheck, then build:
./release.sh v0.1.8
```

`precheck.sh` clones [T3 Code](https://github.com/pingdotgg/t3code) into
`t3code/` if needed, fetches tags, backs up local source changes under
`releases/precheck-backup-*`, removes previous source edits, and checks out
the selected tag. It checks Node, Vite Plus (`vp`), a full JDK, and the Android SDK,
then checks both patches without applying them. A patch conflict returns a nonzero status
and leaves the selected source ready for inspection and patch repair.
Precheck needs Git and tar to prepare and back up source. It reports missing
or incompatible build tools without installing dependencies or building Android.
`check-tools.sh` can repeat the tool checks without resetting source. It checks
SDK platform/build-tools directories; Gradle resolves exact SDK, NDK, and CMake
versions during the build. Expo is installed by `vp install`, and Gradle uses
the project wrapper; neither requires a global installation.

`release.sh` builds the prepared checkout. It verifies the requested tag,
installs locked dependencies, applies the patches, regenerates highlighting,
runs focused tests, and builds `releases/t3code-vX.Y.Z-eink.apk`. It does
not fetch, reset, clean, or switch source versions. The version argument
is optional and defaults to the checked-out tag. Build retries recognize
patches already applied by a previous attempt.

The APK is a self-contained **T3 Code Preview** release build signed with
the local debug key. OTA updates are disabled to preserve the patches.
Install the APK on your device separately.

Only precheck removes previous patches and other local source edits in
`t3code/`, after saving tracked changes and untracked source files.
Ignored files, including dependencies and local environment settings, are
preserved. Patched sources remain after a build for inspection. Save any
source repairs back into the patch files before preparing the checkout again.

Both `t3code/` and `releases/` are ignored by this repository. The nested
clone keeps its own Git history and upstream remote.

The daily scheduled build selects the highest upstream `vX.Y.Z` tag and
passes it explicitly to `precheck.sh`, reviews and repairs the patches,
then runs `release.sh` for that same tag. GitHub release publication and its
artifacts are not required; the APK is built locally from the tagged source.
