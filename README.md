<h1 align="center">
  Time Cop Fork
  <br>
  <a href="https://github.com/twohardthings/timecopfork"><img alt="icon" width="128" height="128" src="icon.no-bg.color.svg"></a>
</h1>
<div align="center">
  A time tracking app that respects your privacy and gets the job done without getting too fancy.
</div>
<br />
<div align="center">
  <img alt="License" src="https://img.shields.io/github/license/twohardthings/timecopfork?style=flat-square">
</div>

## About this fork

_Time Cop Fork_ is a fork of [Time Cop](https://github.com/hamaluik/timecop) by Kenton Hamaluik. The original's last release was 1.8.1 (November 2022), and it no longer builds with current versions of Flutter and Android. This fork keeps the app working and maintains it from here.

Compared to the original, the fork:

* builds with the current stable Flutter and Android toolchain, with updated dependencies
* has its own Android application ID (`io.github.twohardthings.timecopfork`) and name ("Time Cop Fork"), so it installs **alongside** the original app instead of replacing it. Data is not shared: export the database in the original app and import it in the fork to move your entries over
* uses its own version numbers, starting again at 1.0.0
* requires Android 7.0 (API 24) or newer
* supports **Android only** for now. The iOS, macOS and Linux project files are still the original's; they are not built, tested or released by this fork

All changes are listed in the [changelog](CHANGELOG.md). Credit for the app itself goes to Kenton Hamaluik and the [original contributors](CONTRIBUTORS.md).

## Download

The fork is Android-only and not available in any app store yet. Download the APK from the [latest release](https://github.com/twohardthings/timecopfork/releases/latest) (under **Assets**) and install it on your device. There is one APK per processor type:

- `timecopfork-<version>-arm64-v8a.apk`: nearly all phones and tablets from the last years. Take this one if unsure.
- `timecopfork-<version>-armeabi-v7a.apk`: older 32-bit devices.
- `timecopfork-<version>-x86_64.apk`: emulators and some Chromebooks.

If Android says the app isn't compatible, try the next one. Android asks you to allow installing apps from your browser or file manager the first time. To update, install the newer release's APK over the old one; your data is kept.

Development builds: every change on `master` also produces the APKs, attached to the [Dart workflow](https://github.com/twohardthings/timecopfork/actions/workflows/dart.yml?query=branch%3Amaster) run under **Artifacts** (you need to be signed in to GitHub).

## Motivation

_From the original author:_

I'd rather not do time-tracking at all, but since its a necessity for my work, it's either use an app or keep track of things manually (which I'm terrible at). There are many time tracking apps on the app stores (and I have tried several of them), but each of them has at least one pain point that eventually drives me off—some cost more money than I think they should, others have (what I consider) poorly designed interfaces, some are way too complicated, some don't export data easily, most require an internet connection, I have privacy concerns with a large number of them, etc, etc.

Time tracking in and of itself is rather straightforward (hence all the apps on the app stores), so I figured “why not use this as an opportunity to practice mobile development and learn some new things?”. This app is the result of that question—its a tool that I use every day for work, but also a sample project to work off of and share with others.

## Features

* Offline-only, mobile-first
* For Android (the fork; see [Download](#download)). The original Time Cop is also available for Android ([Google Play](https://play.google.com/store/apps/details?id=ca.hamaluik.timecop), [F-Droid](https://f-droid.org/packages/ca.hamaluik.timecop/)), [iOS](https://apps.apple.com/us/app/time-cop/id1500711020), and [Linux](https://flathub.org/apps/details/ca.hamaluik.Timecop)
* Fully private—there is no tracking / spying / advertising / etc
* Keep track of tasks with multiple parallel timers that can be started with the tap of a button
* Associate timers with projects to group your work (or don't)
* Start, stop, edit, and delete timers whenever with no fuss
* Export data as a `.csv` file, filtered by timespans and projects
* Export the app's database for full access to all of its data
* Automatic light mode / dark mode based on your device settings
* Localized in several languages (thanks to [Google Translate](https://cloud.google.com/translate)): English, Arabic, German, Spanish, French, Hindi, Japanese, Korean, Portuguese, Russian, Chinese (Simplified), Chinese (Traditional), as well as Italian, Czech, Norwegian, and Indonesian (via contributors)
* Open source ([licensed under Apache-2.0](LICENSE))—fork away!

## Screenshots

<div align="center">
    <img alt="Screenshot" src="screenshots/ios/dark/en/iPhone Xs Max-Portrait-dashboard.jpg" height="480"> <img alt="Screenshot" src="screenshots/ios/dark/en/iPhone Xs Max-Portrait-editor.jpg" height="480"> <img alt="Screenshot" src="screenshots/ios/dark/en/iPhone Xs Max-Portrait-projects.jpg" height="480"> <img alt="Screenshot" src="screenshots/ios/dark/en/iPhone Xs Max-Portrait-export.jpg" height="480"> <img alt="Screenshot" src="screenshots/ios/dark/en/iPhone Xs Max-Portrait-about.jpg" height="480">
</div>

These screenshots are from the original Time Cop. More (including dark-mode and localization demonstrations) are available in the [screenshots/](screenshots/) folder.

## Contributing

Bug reports and pull requests for the fork are welcome in [this repository](https://github.com/twohardthings/timecopfork/issues). In the spirit of the original, the app should stay relatively small and simple. If that's not for you, there's [plenty](https://toggl.com/) of [other](https://clockify.me/) [options](https://www.workpuls.com/) [out](https://www.manictime.com/) [there](https://trackabi.com/).

The app is created pretty much entirely in [Dart](https://dart.dev/) using [Flutter](https://flutter.dev/), and I tried to make heavy use of the [Bloc](https://bloclibrary.dev/#/) pattern.

Here are a few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view its [online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

After [installing and setting up Flutter](https://docs.flutter.dev/get-started/install) (ideally its latest stable version) and downloading the Time Cop code, you should be able to simply [build and run](https://docs.flutter.dev/get-started/test-drive#run-the-app) this Flutter project, at least for mobile platforms. For more information, see the `CONTRIBUTING.md` file.

### Testing

```bash
flutter test
```

runs everything in [`test/`](test/), and CI runs it for every pull request and on `master`:

- **Unit tests** ([`test/unit/`](test/unit/)): the blocs, the models, the CSV export and the database, which runs against a real in-memory SQLite database.
- **Screen tests** ([`test/screens/`](test/screens/)): start the whole app with in-memory data and use each screen the way a user would (start and stop timers, edit, filter, export, change settings).
- **Golden tests** ([`test/goldens/`](test/goldens/)): render each screen and compare it with a reference image in `test/goldens/images/` (light, dark and Spanish). They fail when a screen looks different from its image.

After an intended change of the look, update the images and review them like code:

```bash
flutter test --update-goldens --tags golden
```

The images are generated on Linux with the latest stable Flutter, the same as CI. Text can be drawn slightly differently on other systems or Flutter versions, so there use `flutter test --exclude-tags golden` if the golden tests fail without a visible reason. When a golden test fails in CI, the run has a `golden-failures-…` artifact with the expected, actual and difference images.

New tests should start the app with `pumpApp` from [`test/helpers/pump_app.dart`](test/helpers/pump_app.dart). The run's summary page in GitHub Actions shows the line coverage.

### Releasing

1. Raise `version:` in `pubspec.yaml` (e.g. `1.1.0+2`; the number after `+` is the Android version code and must increase with every release).
2. In `CHANGELOG.md`, move the `[Unreleased]` entries to a new `## [1.1.0] - <date>` section, and merge to `master`.
3. Either run the [Dart workflow](https://github.com/twohardthings/timecopfork/actions/workflows/dart.yml) manually on `master` with **Publish a release** ticked, or push a tag `v1.1.0`. CI builds the signed APK, creates the tag (for a manual run) and publishes the GitHub Release with the changelog section as release notes.

### Localizations

Translations are handled using [Project Fluent](https://projectfluent.org/) and live in the [`l10n/`](l10n/) folder, one `.flt` file per language. If you notice an incorrect string or want to add a language, please open a pull request. (The original project's Weblate translates the original app, not this fork.)

All translations except English, Italian, Czech, Norwegian, and Indonesian were originally auto-translated by [Google Translate](https://cloud.google.com/translate) using the original author's [Translate Tool](https://github.com/hamaluik/translatetool).

## Todo

A list of “user stories” (and I use that term very loosely) guiding the development of this app is available in [design/user-stories.md](design/user-stories.md); any unchecked boxes are outstanding items on the todo list!
