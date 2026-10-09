# MMHS School App

## API target selection

Release builds require an explicit backend target. Set `API_ENV` to `staging`
or `production`; the app maps those names to the staging and existing
production backend URLs in `lib/config/api_config.dart`. A release build with
an unset or unknown target fails rather than silently selecting a backend.

Build a staging APK for installation testing:

```sh
flutter build apk --release --dart-define=API_ENV=staging
```

Build a production Android App Bundle only after confirming the release
signing configuration and production service setup:

```sh
flutter build appbundle --release --dart-define=API_ENV=production
```

The `API_BASE_URL` define remains available for non-release local development.
Do not put credentials or other secrets in a client build. Client API URLs are
not secrets. Staging builds are test artifacts; never distribute one as a
production release.

## Local development

Install Flutter dependencies with `flutter pub get`, then run `flutter test`
and `flutter analyze`. The Android release signing configuration is local and
must not be committed.
