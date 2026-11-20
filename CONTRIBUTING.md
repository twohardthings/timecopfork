Bug reports and pull requests are welcome! Time Cop Fork aims to stay small and simple, like the original [Time Cop](https://github.com/hamaluik/timecop), so please open an issue first for larger features.

The app is written in [Dart](https://dart.dev/) with [Flutter](https://flutter.dev/) and uses the [Bloc](https://bloclibrary.dev/) pattern. The fork is released for **Android only** for now ([#13](https://github.com/twohardthings/timecopfork/issues/13)).

## Getting started

1. [Install Flutter](https://docs.flutter.dev/get-started/install) (latest stable) and the Android SDK.
2. Clone this repository and run `flutter pub get`.
3. Run the app on a device or emulator with `flutter run`.

New to Flutter? Start with [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab) and the [cookbook](https://docs.flutter.dev/cookbook).

## Before you open a pull request

- `flutter analyze` reports no issues.
- `flutter test` passes. If a screen's look changed on purpose, update the golden images (see "Testing" in the [README](README.md#testing)).
- New strings are in every `l10n/*.flt` file.
- User-facing changes are listed under `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md).
- Each pull request covers one topic.

The project's conventions (toolchain versions, imports, translations, Android resources, releases, and what must not change for existing users) are in [AGENTS.md](AGENTS.md). It is written for AI coding agents, but applies to everyone.
