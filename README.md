# Project MAD

Project MAD is a Flutter application for coastal monitoring and community participation. The app allows users to create an account, sign in, browse beaches on a live map, submit beach issue reports, publish or join cleanup events, receive alerts, and track their activity from a personal profile.

## Overview

The app is structured around a simple authenticated flow:

- `main.dart` initializes Firebase
- `app.dart` starts the app and shows either the login flow or the main app shell
- `main_screen.dart` provides bottom navigation for the core screens
- feature screens read and write app data through service classes

The current navigation includes these sections:

- Login / registration
- Map
- Reports
- Events
- Alerts
- Profile

## Features

### Authentication

- Email and password sign in
- New account registration
- Firebase authentication state listener
- Automatic redirect to the main app after successful login

### Map

- Beach list loaded from Firestore
- Map rendering with `flutter_map`
- OpenStreetMap tile usage
- Risk-level filtering for beaches
- Tap a beach item or marker to view more details

### Reports

- Submit environmental or safety reports for a selected beach
- Choose a category and severity level
- Add a description
- Store report coordinates from the selected beach record
- Write report data to Firestore
- Award user points after submission
- Create a user notification after submission
- Show a recent reports feed in the UI

### Events

- Publish cleanup events
- Join existing cleanup events
- Track participants and event capacity
- Award points for publishing or joining
- Create related notifications

### Alerts

- Load notifications for the signed-in user
- Display read/unread state
- Show notification title, message, and type

### Profile

- Display user name and role
- Show user points
- Show submitted reports
- Show joined events
- Allow logout

## Architecture

The project now uses a basic service-layer structure so screens do not need to contain all Firestore write logic directly.

### App flow

- `lib/main.dart`: Firebase bootstrap
- `lib/app.dart`: app theme and auth gate
- `lib/main_screen.dart`: bottom navigation shell

### Models

The `lib/models/` directory contains app data models used to parse Firestore documents into typed objects:

- `beach.dart`
- `report.dart`
- `event.dart`
- `app_notification.dart`

### Services

The `lib/services/` directory contains reusable data-access and auth logic:

- `auth_service.dart`
- `beach_api_service.dart`
- `report_api_service.dart`
- `event_api_service.dart`
- `notification_api_service.dart`

This makes the code easier to maintain and gives the project a cleaner place to expand toward a more formal API/repository pattern later.

## Project Structure

```text
lib/
  app.dart
  main.dart
  main_screen.dart
  firebase_options.dart
  models/
    app_notification.dart
    beach.dart
    event.dart
    report.dart
  services/
    auth_service.dart
    beach_api_service.dart
    event_api_service.dart
    notification_api_service.dart
    report_api_service.dart
  screens/
    alerts_screen.dart
    events_screen.dart
    login_screen.dart
    map_screen.dart
    profile_screen.dart
    reports_screen.dart
```

## Tech Stack

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- `flutter_map`
- `latlong2`

Additional packages already included in the project:

- `sqflite`
- `shared_preferences`
- `geolocator`
- `path_provider`
- `fluttertoast`

## Firestore Data

The current app behavior expects Firestore data organized around collections like:

- `users`
- `beaches`
- `reports`
- `events`
- `notifications`

### Example responsibilities

- `users`: profile data, role, points, badges
- `beaches`: map data, municipality, coordinates, risk level, cleanliness
- `reports`: user-submitted issue reports
- `events`: cleanup event records and participants
- `notifications`: app alerts for user actions

## Getting Started

### Prerequisites

- Flutter SDK installed
- Dart SDK compatible with the Flutter version in use
- A Firebase project configured for the app
- Platform Firebase config files present in the project

### Firebase setup

At minimum, the app currently depends on:

- Firebase Core
- Firebase Authentication
- Cloud Firestore

You should also make sure:

- Email/password sign-in is enabled in Firebase Authentication
- Firestore is enabled in the Firebase project
- the required collections exist or can be created by the app

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Run on a specific device

```bash
flutter devices
flutter run -d <device-id>
```

### Run tests

```bash
flutter test
```

### Static analysis

```bash
flutter analyze
```

## Current API / Backend Approach

This project does not use a separate custom backend server yet. Instead, it uses Firebase directly as the backend layer.

Current external integrations include:

- Firebase Authentication for login and registration
- Cloud Firestore for app data
- OpenStreetMap tiles for map display

The new `services/` layer is intended to make a later move to a custom REST or GraphQL backend easier if needed.

## Notes

- The map screen depends on beach records having valid latitude and longitude values
- The reports flow currently includes a photo flag, but there is no connected image upload pipeline yet
- The app includes some additional local-storage related files and dependencies that are not part of the main beach-reporting flow

## Screenshots

Place screenshots in `docs/screenshots/` using the filenames below, or update the paths if you prefer different names.

### Login

![Login screen](docs/screenshots/login-screen.png)

### Map

![Map screen](docs/screenshots/map-screen.png)

### Reports

![Reports screen](docs/screenshots/reports-screen.png)

### Events

![Events screen](docs/screenshots/events-screen.png)

### Alerts

![Alerts screen](docs/screenshots/alerts-screen.png)

### Profile

![Profile screen](docs/screenshots/profile-screen.png)
