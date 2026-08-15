# Glances MVP — build and run

A working Glances client for Android, talking to your existing Django API. Not a mockup: real login, real profile, real GPS proximity, real likes, real matching, real chat with the expiry timer.

## What works

| Feature | Endpoint |
|---|---|
| Register / log in with email | `POST /api/users/register/`, `POST /api/users/login/` |
| Session survives app restart | JWT in `shared_preferences` |
| Onboarding: gender, DOB (18+), preferences | `POST /api/users/profile/`, `/api/users/setting/` |
| Photo upload with the server's face check | `POST /api/users/images/` |
| GPS position pushed every 45 s | `POST /api/users/geo-data/` |
| Discovery of people you crossed paths with | `GET /api/users/filtered-list/?filter=geo` |
| Simple mode + two-up "choose one profile" | — |
| Like, pass, undo, swipe left/right | `POST /api/likes/`, `DELETE /api/likes/{id}/unlike/` |
| Mutual like → "It's a match!" → chat opens | server creates the room automatically |
| Chat, live over WebSocket, REST fallback | `/api/chats/…`, `ws/chat/{id}` |
| The 10-minute expiry window + extend | `POST /api/chats/extend-time/` |
| Likes-and-messages inbox | `GET /api/likes/`, `GET /api/chats/` |
| Settings: invisibility, preferences, distance | `PATCH /api/users/setting/{id}/` |
| Block, report, delete account | `POST /api/users/{id}/ban/`, `/api/reports/{id}/`, `DELETE /api/users/delete/user/` |

## What's deliberately not here

- **Bluetooth proximity.** Discovery runs on GPS (`filter=geo`), which is what works cross-platform today. BLE is the separate spike.
- **Facebook / Google / Apple sign-in.** They need app credentials and console setup. Email works now.
- **Glances Plus, SMS verification, the 12-screen tutorial.** Designed in Figma, not built anywhere.
- **Push notifications.** Your FCM setup is on the dead legacy API.

## Build it

**1. Create the Flutter scaffold** (generates the android/ios folders, Gradle files, icons):

```powershell
cd C:\Users\edile\develop
flutter create --platforms=android --org io.glances glances_app
```

**2. Copy this bundle over the top.** Replace `lib/` entirely, and replace `pubspec.yaml` and `android/app/src/main/AndroidManifest.xml` with the ones here.

**3. Point it at your server.** Open `lib/config.dart` and set `baseUrl`:

- Android emulator → local Django: `http://10.0.2.2:8000`
- Real phone → Django on your PC: `http://192.168.x.x:8000` (run `ipconfig`, take your wifi adapter's IPv4)
- Production: `https://glances.work`

A real phone cannot reach `localhost` — that means the phone. And start Django with `python manage.py runserver 0.0.0.0:8000` so it accepts connections from outside the PC.

**4. Build:**

```powershell
cd glances_app
flutter pub get
flutter run                     # live, with hot reload — best for development
flutter build apk --release     # produces the installable APK
```

The APK lands at `build\app\outputs\flutter-apk\app-release.apk`. Copy it to a phone and open it (allow "install from unknown sources"). It's signed with a debug key, which is fine for testing and **not** acceptable for Play — release signing comes later, with your existing keystore.

## Testing it properly

You need **two accounts on two phones**, physically near each other — that's the whole product.

1. Register on both. Complete onboarding on both, with a real face photo (the server rejects photos with no detectable face).
2. Make the two accounts compatible: if A is a man seeking women, B must be a woman seeking men, and both must fall inside each other's age range. Mismatched preferences produce an empty feed and it looks like a bug.
3. Keep both phones in the same room. Both push GPS every 45 seconds.
4. Open the app on both — each should now see the other.
5. Like from both sides → "It's a match!" → the chat room opens.
6. Send a message from A. Note that the countdown does **not** start yet. Reply from B — now the 10-minute window begins.

`Config.devMode` is `true`, which appends `?mode=dev` and shortens the server's encounter window from 10 minutes to 2. That makes testing far less tedious. Set it to `false` for realistic behaviour.

## When it doesn't work

**Empty discovery feed** — the most common outcome, and usually not a bug. In order of likelihood:

1. Preferences don't match (gender/age) — see step 2 above.
2. No recent GPS on the server. Settings → "Update my location now" on both phones.
3. Distance too small. Default is 100 m; raise it in Settings.
4. The other account has no photo, no profile, or no settings row.
5. More than 10 minutes (2 in dev mode) since the other phone last reported a position.

**`400 {"error": "..."}` on the discovery call** — the server's `user_validate_profile` / `user_validate_setting` rejecting an incomplete account. Finish onboarding.

**"Sorry, face not found"** — the server's OpenCV check. Use a clear, front-facing, well-lit photo.

**Connection refused / timeout** — `baseUrl` is wrong, Django isn't bound to `0.0.0.0`, or Windows Firewall is blocking port 8000. Test from the phone's browser first: open `http://<your-ip>:8000/api/swagger/`. If that doesn't load, the app can't reach it either.

**Chat messages don't arrive live** — the WebSocket isn't connecting. Messages still send and appear over REST; reopening the chat shows them. Worth knowing: the current server has *no* WebSocket authentication (see the security patches), so once you apply those, the token this app already sends becomes required.

## Known rough edges

- Location is foreground-only. Close the app and you stop being discoverable. That's the proximity engine milestone.
- No pagination anywhere — the API doesn't paginate either.
- Photos are single-upload; the multi-photo carousel from the Figma isn't wired up.
- The design is *close* to the Figma, not pixel-exact. The token values are right; the layout is approximate. Milestone 2 is where that gets tightened.

Send me any error you hit — the full text, including the stack trace.
