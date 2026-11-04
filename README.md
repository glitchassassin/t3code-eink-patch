# T3 Code e-ink patch

Android light-mode code and diff styling for a Boox NoteAir5C: black
monospace text, heavier base weight, bold names, bold italic comments,
italic literals, and stronger diff colors.

## How to use

Install Vite Plus (`vp`), the Node version required by T3 Code's
`package.json`, JDK 17, and the Android SDK. Set `JAVA_HOME` and
`ANDROID_HOME` to their installation directories, then run:

```sh
./release.sh
```

The script clones [T3 Code](https://github.com/pingdotgg/t3code) into
`t3code/` if needed, discards tracked changes and untracked files in that
checkout, fetches the latest stable version tag, installs its locked
dependencies, applies the patches, regenerates highlighting, runs focused
tests, and builds an APK at `releases/t3code-vX.Y.Z-eink.apk`.

The APK is a self-contained **T3 Code Preview** release build signed with
the local debug key. OTA updates are disabled to preserve the patches.
Install the APK on your device separately.

Each run removes previous patches and other local source edits in `t3code/`.
Ignored files, including dependencies and local environment settings, are
preserved. Patched sources remain afterward for inspection. Patch conflicts
stop the build and require updating the patches for the new release.

Both `t3code/` and `releases/` are ignored by this repository. The nested
clone keeps its own Git history and upstream remote.
