# AGENTS.md

Conventions for AI coding agents and human contributors. See
[CONTRIBUTING.md](CONTRIBUTING.md) for how to get started and the
[README](README.md) for testing, releasing and translations in detail.

Time Cop Fork is a fork of [Time Cop](https://github.com/hamaluik/timecop):
a Flutter app (Dart package `timecop`), released for **Android only**. The
`ios/`, `macos/` and `linux/` folders are still the original's (see [#13](https://github.com/twohardthings/timecopfork/issues/13)).

## Toolchain and checks

- Flutter stable (3.50 at the time of writing), Dart ≥ 3.13.
- Android: Gradle 9.5, AGP 9.3, Kotlin 2.4, Java 17, `compileSdk` 37,
  `minSdk` 24 (Flutter's default). Flutter refuses older Gradle, AGP or
  Kotlin versions.
- Before every PR:
  - `flutter analyze` must report no issues;
  - `flutter test` must pass.
- To check Android, build a release: `flutter build apk --release`. Debug
  builds don't shrink resources and can hide release-only bugs (see [#5](https://github.com/twohardthings/timecopfork/issues/5)).

## Tests

- `test/unit/`: blocs, models, CSV export, database.
- `test/screens/`: start the whole app with `pumpApp`
  (`test/helpers/pump_app.dart`) and in-memory fakes
  (`test/helpers/fakes.dart`). Cover new screens and settings here.
- `test/goldens/`: reference images. After an intended visual change, run
  `flutter test --update-goldens --tags golden` and review the images.
- `test/screenshots/`: store and README screenshots, only with
  `SCREENSHOTS=1 flutter test test/screenshots`.

## Code conventions

- Import `package:material_ui/material_ui.dart` and
  `package:cupertino_ui/cupertino_ui.dart`, **never**
  `package:flutter/material.dart` or `cupertino.dart` (deprecated since
  Flutter 3.47).
- Packages built on the legacy Material library can fail at runtime ("No
  MaterialLocalizations / No Material widget found") even when they compile.
  Prefer `material_ui`-based releases, and cover new screens with a screen
  test.
- Font Awesome 11: `FaIcon(FontAwesomeIcons.x)`, and
  `FontAwesomeIcons.x.data` where a raw `IconData` is needed.
- State management with Bloc. Data goes through `DataProvider` and settings
  through `SettingsProvider`; tests use the in-memory fakes.

## Localization

- Strings live in `l10n/*.flt` ([Project Fluent](https://projectfluent.org/)),
  one file per language.
- Add every new key to **all** `l10n/*.flt` files in the same PR (machine
  translations are fine; say so in the PR for native-speaker review), and
  expose it in `lib/data_providers/l10n/l10n_provider.dart` and
  `fluent_l10n_provider.dart`. Some older keys are still missing in some
  languages ([#25](https://github.com/twohardthings/timecopfork/issues/25)).
- `appName` is "Time Cop Fork", kept or translated per language ([#12](https://github.com/twohardthings/timecopfork/issues/12)).
  `test/unit/app_name_test.dart` pins each one, so change both together.

## Android resources and icon

- Resources looked up by name from Dart, like `ic_notification_icon`, must
  be listed in `android/app/src/main/res/raw/keep.xml`, or release builds
  strip them.
- App icon sources:
  - `icon.svg`, rendered to `icon.png`;
  - `icon_android_fg.png`, the adaptive icon's foreground;
  - `icon.no-bg.color.svg`, for the About screen and README.

  After changing them, regenerate with `dart run flutter_launcher_icons`. Keep
  the `<monochrome>` layer in
  `android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml`, because the
  generator drops it.

## Versioning and releases

- `pubspec.yaml` `version: X.Y.Z+N`: a semantic version plus an Android
  version code that must increase with every release. The fork started at
  `1.0.0+1`.
- Record user-facing changes under `[Unreleased]` in `CHANGELOG.md` (Keep a
  Changelog format).
- A release PR does three things:
  - raises the version;
  - turns `[Unreleased]` into a dated section (CI uses it as the release
    notes);
  - adds `fastlane/metadata/android/en-US/changelogs/<N>.txt`, the store's
    "What's new" (under 500 characters).
- **Agents never push tags or start release runs.** The maintainer
  publishes the release: either a manual run of the Dart workflow with
  "Publish a release" ticked, or a pushed `v*` tag.

## Distribution: don't break it

These are what users and other repositories rely on:

- The application ID is `io.github.twohardthings.timecopfork`. Android
  treats a new ID as a different app.
- The signing key. CI stops a release whose certificate doesn't match the
  SHA-256 fingerprint in the README, and Obtainium and the F-Droid repo
  refuse updates signed with another key.
- The release assets are named `timecopfork-<version>-<abi>.apk`, one per
  ABI (arm64-v8a, armeabi-v7a, x86_64).
  [twohardthings/fdroid](https://github.com/twohardthings/fdroid) picks them
  up by that name.
- `fastlane/metadata/android/` is the store listing (titles, descriptions,
  changelogs, screenshots, feature graphics). The F-Droid repo reads it at
  the release tag.

## Workflow

- One topic per PR.
- CI runs analyze and tests on PRs. On `master` it also builds the
  per-ABI release APKs (a workflow artifact).
- A release run additionally:
  - checks the signing certificate (a mismatch stops the release);
  - scans the APKs with VirusTotal;
  - publishes the GitHub Release;
  - triggers the F-Droid repo.

  The VirusTotal scan and the F-Droid trigger are best-effort. Without
  `VIRUSTOTAL_API_KEY` or `FDROID_DISPATCH_TOKEN`, or if they fail, the
  release is still published; the run shows a warning, the release notes
  have no VirusTotal table, and the F-Droid repo picks the release up with
  its daily run.
- CodeRabbit and Codex review every PR. Fix findings that hold up, minor ones
  included, in the same PR, then reply on each thread and resolve it. Reply
  instead of changing code when a finding is wrong.
- Keep the original copyright notices (Apache-2.0). Don't reuse the
  original's name or logo as they are.
