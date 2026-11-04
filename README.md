# T3 Code e-ink patch

Personal Android light-mode code and diff styling for a Boox NoteAir5C.
Black monospace text with a medium base weight, bold function and variable
names, bold italic comments, italic literals, and stronger diff colors.

Based on [T3 Code](https://github.com/pingdotgg/t3code) commit
`8ab024f31a6d285015c4fb84e52a0183f614e237`.

## Apply

Install T3 Code dependencies first, then run this from the T3 Code checkout:

```sh
bash ~/repos/t3code-eink-patch/apply.sh
```

Use a fresh, unpatched checkout. The helper checks and applies the patches,
regenerates the highlighting table against the installed tokenizer, and runs
focused tests. It does not build or install an APK.

- `01-android-fonts.patch`: independent monospace and bold italic corrections.
- `02-eink-styling.patch`: personal palette and rendering changes.
- `apply.sh`: application, regeneration, and verification.

## Updating

Review application conflicts when moving to a newer T3 Code version. The
helper does not force application. If the second patch fails its application
check, the helper reverses the first patch before exiting. A later generation
or test failure leaves the patches applied for inspection.

Keep palette values and token rules in the patched
`apps/mobile/src/lib/eInkCodeTheme.ts`. Keep the generated highlighting table
in the build, but regenerate it rather than including it in these patches.
Review token categories and tests when the tokenizer changes.

If upstream fixes the Android fonts, review whether patch 01 is still needed
and adjust the helper and patch 02 accordingly. Preserve the separation between
font fixes and personal styling when exporting updated patches.

## Verification

The initial patches were checked against clean copies of the base files.
Fourteen highlighting and generator tests, mobile typecheck, focused lint, and
the Android release build passed. The preview APK was installed on the Boox.
