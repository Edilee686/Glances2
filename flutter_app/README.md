# Glances (Flutter)

Cross-platform rebuild of the Glances dating app, matching the approved v2 design.

## Run

```bash
flutter create . --platforms=ios,android   # generates ios/ and android/ folders
flutter pub get
flutter run
```

The `flutter create .` step is only needed once: this package ships the Dart
source and assets, not the generated platform folders.

## Structure

    lib/
      main.dart            app entry, routes, global state scope
      theme.dart           colours, type scale, shared decorations
      routes.dart          route names + table
      state/app_state.dart single ChangeNotifier holding session state
      models/              plain data classes
      services/            API seam - swap MockApi for your backend
      widgets/             reusable pieces (buttons, wave, photo circle, sliders)
      screens/             one file per screen

## Backend

Everything the UI needs goes through `services/api.dart`. `MockApi` returns
in-memory data so the app runs with no server. Implement `GlancesApi` against
your endpoints and swap it in `main.dart` - no screen code changes.

## Known parity notes

- Photos are placeholders; wire `Person.photoUrl` to your CDN.
- Location, push notifications and purchases are stubbed behind the API seam.
- Text scales with the OS setting; layouts were checked to 1.3x.
