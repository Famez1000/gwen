# Gwyn

A new Flutter project.

## Local Firebase setup

Firebase client configuration is intentionally not stored in Git. Before
running the app locally:

1. Install and sign in to the Firebase and FlutterFire CLIs.
2. Run `flutterfire configure` for the `mijnfb-c0a3b` Firebase project.
3. Confirm that `lib/firebase_options.dart` and
   `android/app/google-services.json` were generated locally.

Keep both generated files untracked. Restrict Android Firebase API keys to the
app package and signing certificate, and restrict iOS keys to the app bundle
identifier in Google Cloud Console.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
