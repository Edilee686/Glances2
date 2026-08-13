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

## What this build is

Rebuilt against the Figma flow, with a real database and real accounts.

### Design
Every screen is transcribed from the 1080x1920 Figma frames. Numbers are not
estimated: `lib/theme.dart` holds the palette straight from the file (cyan
`#3CBEEE`, orange `#F37C11`, grey `#5D5D5D`, Mukta type) and `fx(context, n)`
converts a Figma pixel to a logical pixel, so an 880x120 pill button stays
proportionally an 880x120 pill button on any handset. The curved sheet, the
610px overlapping circles, the 200x70 toggle and the heart are all rebuilt from
the source geometry.

### The core screen
`sight_screen.dart` is the vertical carousel: circles overlap by about 40
percent, scroll under your thumb, and the focused person is scaled up and
painted on top with the heart button on their edge. A transparent `PageView`
owns the gesture; the visible stack is drawn separately so paint order can put
the focused circle in front. Range is 5-20 m, adjustable in the menu.

### Database
`lib/services/db.dart` is SQLite (`sqflite`) with six tables - `accounts`,
`profiles`, `likes`, `matches`, `messages`, `settings` - foreign keys on,
indexed message threads. Every list in the app is a query. Nothing is held only
in memory, so likes, matches, chats and profile edits survive a restart and a
reinstall of the app's process.

### Accounts
`lib/services/auth.dart` registers and signs in real accounts stored in the
`accounts` table, with the session in shared preferences.

- **Phone:** enter a number, the app generates a six digit code and asks for it.
  There is no SMS gateway in a device-only build, so the code is shown on the
  verify screen. Replace the body of `Auth.requestCode` with your provider's
  send call and the rest of the flow is unchanged.
- **Google / Facebook:** these mint a stable per-device identity and create or
  reuse the matching account. Wiring real OAuth means swapping the identifier
  in `Auth.signInWith` for the token subject you get back - the account,
  profile and session handling already work.

Sign out returns you to the join screen with the account intact. Delete account
removes it and everything attached to it.

### Photos
Camera and photo library both work through `image_picker`. Picked files are
copied into the app's documents directory and the path is stored on the
profile, so photos survive app restarts. Profiles with no photo fall back to
the flat grey disc from the Figma frames.

### Still fictional
The eight people you can see are rows seeded into `profiles` on first run
(`GlancesDb._seed`), and their distances are fixed numbers rather than GPS.
Whether a like is returned is decided per person and never changes its mind;
unanswered likes get answered after about 25 seconds and matches write to you
on their own. Replace the seed and the `_likesBack` heuristic when a server
exists.

## Notes
- **Signing:** release builds use the debug key so this works with no keystore
  setup. Make a real keystore before any Play Store upload.
- **Package id:** `com.glances.app`.
- **First launch needs wifi** - Mukta downloads once via `google_fonts`, then
  caches.
- **iOS:** run `flutter create --platforms=ios .` here, then build on a Mac.

## If a build fails
- Locally: `flutter clean && flutter pub get`, retry.
- JDK mismatch is the usual cause - Flutter wants JDK 17:
  `flutter config --jdk-dir "<path to JDK 17>"`.
- In Actions: open the failed step and read the last ~20 lines.

---

## Appendix - build-apk.yml

```yaml
name: Build APK

on:
  push:
    branches: [main]
  workflow_dispatch:

defaults:
  run:
    working-directory: flutter_app

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
          path: flutter_app/build/app/outputs/flutter-apk/app-release.apk
          if-no-files-found: error
```
