# Getting Glances onto your phone

Two routes. **Route B needs nothing installed** — GitHub builds the APK for you.

---

## Route B — cloud build (recommended)

Your repo is already made: **github.com/Edilee686/Glances2**.

### 1. Upload the app files
- Open the repo → **Add file → Upload files**.
- Unzip the download. Open the `flutter_app` folder and drag **everything inside it** into the browser — `lib`, `android`, `assets`, `pubspec.yaml`, all of it. **Not the `flutter_app` folder itself** — its contents must sit at the top level of the repo.
- Ignore the `.github` folder if you can't see it (it's hidden). Step 2 handles it.
- **Commit changes.**

### 2. Add the build workflow
Hidden folders are painful to drag, so create this one by hand:

- **Add file → Create new file**
- In the filename box type exactly: `.github/workflows/build-apk.yml`
  (typing the slashes creates the folders automatically)
- Paste the contents of `.github/workflows/build-apk.yml` from the download. If you can't open it, it's also printed at the bottom of this file.
- **Commit changes.** The build starts immediately.

### 3. Wait for the build
- Click the **Actions** tab. A run called **Build APK** starts on its own.
- Takes about 5–8 minutes the first time. Green check = done.
- If it didn't start, click **Build APK** in the left sidebar → **Run workflow**.

### 4. Get the APK
- Click the finished run → scroll to **Artifacts** → download **glances-apk**.
- That's a zip containing `app-release.apk`.

### 5. Install it
- Easiest: on your phone, open GitHub in Chrome, sign in, go to the run, download the artifact there. Unzip with your Files app, tap the APK.
- Android will ask to allow installs from that app — allow it, then **Install**.
- Or: download on your computer and email/AirDrop/Drive the APK to yourself.

Every future push to `main` rebuilds automatically, so this is a one-time setup.

---

## Route A — build on your computer

1. Install the Flutter SDK: https://docs.flutter.dev/get-started/install
2. Install Android Studio → **More Actions → SDK Manager → SDK Tools** → check **Android SDK Command-line Tools**.
3. `flutter doctor --android-licenses` (accept all), then `flutter doctor` — Android section must be green.
4. On your phone: Settings → About → tap **Build number** 7× → back → enable **USB debugging**. Plug in, tap Allow.
5. From this folder:
   ```bash
   flutter pub get
   flutter run --release
   ```
   Builds and launches on the phone directly.

For a shareable file instead: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.

Smaller download: `flutter build apk --split-per-abi` → use `app-arm64-v8a-release.apk`.

---

## Notes on this MVP
- **Signing:** release builds use the debug key, so this works with no keystore setup. Fine for sideloading and testing; make a real keystore before any Play Store upload.
- **Package id:** `com.glances.app` — change in `android/app/build.gradle` and the `MainActivity.kt` folder path if needed.
- **First launch needs wifi** — Manrope and DM Mono download once via `google_fonts`, then cache. To go fully offline, drop the TTFs into `assets/google_fonts/` and add that folder to `pubspec.yaml`.
- **Permissions:** internet + fine/coarse location are declared, but the app doesn't request location at runtime yet. That comes with the real backend.
- **The app now really works, locally.** `lib/services/local_api.dart` is a functioning backend that runs on the phone: likes, passes, matches, blocks, chat threads and activity all persist across restarts via `shared_preferences`. Whether a like is mutual is decided per person and never changes its mind. Unanswered likes turn into matches after ~30 seconds, and chat partners reply on their own after a second or two.
- **People are still fictional.** The six profiles come from `lib/data/mock_people.dart` and distances are fixed numbers, not GPS. When the server exists, implement `GlancesApi` over HTTP and swap it into `main.dart` — no screen needs to change.
- **No photos yet.** Profiles fall back to a coloured monogram. Give `Person.photoUrl` real URLs and they load.
- **Reset:** Log out or Delete account in the menu wipes the local store, so you can run the whole flow from scratch.
- **iOS:** run `flutter create --platforms=ios .` here to generate the Xcode project, then build on a Mac.

## If a build fails
- Locally: `flutter clean && flutter pub get`, retry.
- JDK mismatch is the usual cause — Flutter wants JDK 17: `flutter config --jdk-dir "<path to JDK 17>"`.
- In Actions: open the failed step and read the last ~20 lines. Send them to me and I'll fix it.

---

## Appendix — build-apk.yml

Paste this into `.github/workflows/build-apk.yml` if you can't open the file from the zip:

```yaml
name: Build APK

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  apk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - run: flutter --version
      - run: flutter pub get

      - name: Build release APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: glances-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          if-no-files-found: error
```
