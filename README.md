# Project MAD

Flutter coursework project with weekly releases.

## Week 1 scope completed

- Set up the Flutter project structure for Android, iOS, web, Linux, macOS, and Windows.
- Created the app entry point in `lib/main.dart`.
- Built a simple two-screen app in `lib/app.dart`.
- Added navigation from the first screen to the second screen and back.
- Added a widget test in `test/widget_test.dart` that verifies the basic screen flow.

## Week 2 scope completed

- Added a simple `BottomNavigationBar` with three sections.
- Added basic three-screen navigation from splash to second to third screen.
- Added Dart examples for recursive functions, enhanced enums, inheritance, and `async/await`.
- Organized widgets into different files inside `lib/screens/`.
- Moved the Dart example logic into `lib/data/dart_examples.dart`.

## Current app behavior

The app starts on a home screen inside a bottom navigation layout. The home screen includes a button that opens the second screen, the second screen shows simple Dart examples and a button to open the third screen, and the third screen returns to the home route. The bottom navigation also includes a Dart examples section and a files section showing the separated widget structure.

## Run the project

```bash
flutter pub get
flutter run
```

## Run tests

```bash
flutter test
```
