# Refuges Info Mobile agent guidelines

## Project

Refuges Info Mobile is a community-built, unofficial Flutter application using public data from [Refuges.info](https://www.refuges.info/).

- Flutter: 3.47.0
- Dart: 3.13.0
- Platforms: iOS and Android
- Initial target: iOS
- Bundle organization: `dev.jorisgallot`

Do not present the application as official or reuse the Refuges.info logo without explicit permission. The historical `www.refuges.info` repository may be inspected as a reference but must never be modified as part of this project.

## Commands

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build ios --simulator
```

Do not start a development server, publish the application, commit, or push unless explicitly requested.

## Architecture

Keep the application simple, feature-first, and maintainable.

```text
lib/
├── app/                    # Application-level configuration
├── features/
│   └── <feature>/
│       ├── data/           # API models, services, repositories
│       ├── domain/         # Domain models and optional use cases
│       └── presentation/   # Views, widgets, and view models
└── main.dart
```

Only add layers when a feature needs them. Keep widgets focused on presentation, external access in services, and data coordination in repositories. Avoid unnecessary abstractions, code generation, state-management packages, and dependencies.

Follow current documented Dart and Flutter patterns. Consult the installed project skills and current package documentation when relevant.

## API and data

API documentation: <https://www.refuges.info/api/doc/>

The API is public, read-only, and requires no authentication. Inspect real endpoint responses before defining Dart models. Do not infer schemas solely from documentation or the historical codebase.

Important endpoints include:

- `GET /api/bbox`
- `GET /api/massif`
- `GET /api/point`
- `GET /api/commentaires`
- `GET /api/contributions`
- `GET /api/polygones`

Model loading, error, empty, and offline states explicitly where applicable. Add unit tests for models, parsing, API services, and repositories.

## Maps and offline support

Do not add a mapping solution before comparing current options, licensing, attribution requirements, Android and iOS support, and offline capabilities.

Verify tile-provider terms before implementing offline downloads. Never use standard OpenStreetMap tile servers for bulk downloading.

## Licensing and attribution

- Application source code: MIT
- Refuges.info data: CC BY-SA 2.0

Display Refuges.info attribution and the data license clearly wherever data is presented. Preserve attribution in offline views and derived datasets.

## Quality

- Keep iOS and Android compatibility.
- Use `dart format` and satisfy `flutter analyze`.
- Add focused unit or widget tests with each behavior change.
- Prefer immutable models and exhaustive typed mappings for finite values.
- Keep comments rare and explain only non-obvious decisions.
- Do not integrate Flutter Web as a replacement for the public website.
