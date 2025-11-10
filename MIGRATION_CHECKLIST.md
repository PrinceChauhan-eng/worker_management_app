# Supabase Migration Checklist

## Step-by-step execution plan

### ✅ 1) Create a safe migration branch
```bash
git checkout -b feat/supabase-migration
```

### ✅ 2) Prep pubspec
- ✅ Remove:
  - sqflite
  - sqflite_common_ffi
  - sqflite_common_ffi_web
  - path_provider
- ✅ Add:
  - supabase_flutter: ^2.5.6
- ✅ Run:
  ```bash
  flutter clean && flutter pub get
  ```

### ✅ 3) Paste the AI Qoder prompt
- ✅ Delete DatabaseHelper and all SQLite logic
- ✅ Add the multi-file services (users/attendance/advance/salary/login/notifications + auth) using snake_case
- ✅ Update models to output snake_case maps (or keep the MapCase helper if you prefer)
- ✅ Replace all DB calls in providers/UI with Supabase services
- ✅ Keep all screens/UX unchanged

### ✅ 4) App initialization
In main.dart (before runApp):
```dart
await Supabase.initialize(
  url: 'https://<your-project-ref>.supabase.co',
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

Build with:
```bash
flutter build web --release \
  --dart-define=SUPABASE_ANON_KEY=<your_anon_key>
```

(Keep the key out of source control. Do not hardcode.)

### ⬜ 5) Supabase project setup (once)
In Supabase SQL Editor run the table + policy SQL we prepared (users, attendance, advance, salary, login_status, login_history, notifications + dev policies).

In Auth → URL Configuration, add:
```
https://princechauhan-eng.github.io
https://princechauhan-eng.github.io/*
```

(Optional) Create a default admin row in users.

### ⬜ 6) Replace references
Search & replace across project:
- DatabaseHelper(). → the matching Supabase service (UsersService(), AttendanceService(), etc.)
- Remove all calls to openDatabase, rawQuery, getVersion, onUpgrade, etc.

### ⬜ 7) Smoke tests (local)
Run:
```bash
flutter run -d chrome
```

Verify:
- Signup/login via Supabase Auth
- CRUD for users, attendance, advances, salary
- Login status upsert (same worker+date)
- Notifications list, mark as read

### ⬜ 8) Build & deploy to GitHub Pages
```bash
flutter clean
flutter build web --release \
  --dart-define=SUPABASE_ANON_KEY=<your_anon_key>
```

Commit the new build/web/ to your username.github.io repo root (or your Pages branch) so URL stays:
https://princechauhan-eng.github.io/

### ⬜ 9) Cross-device checks
On desktop + Android + iPhone (normal + incognito):
- App loads (no white screen)
- Auth redirects back properly
- CRUD operations reflect in Supabase Table Editor live
- Refresh doesn't break routes

## Acceptance checklist (copy for your PR)

- [x] All SQLite packages removed
- [x] No DatabaseHelper or openDatabase anywhere
- [x] Supabase services in lib/services/* wired
- [x] Models map to snake_case
- [ ] Auth via Supabase (email/password or OTP)
- [ ] RLS enabled with dev-open policies (to be tightened later)
- [ ] Web build deployed; works on mobile + desktop browsers
- [ ] No secrets committed; anon key provided via --dart-define

## Commit message template
```
feat: migrate to Supabase (remove sqflite, add services, auth, and snake_case models)

- Removed sqflite/ffi_web and DatabaseHelper
- Added Supabase services (users/attendance/advance/salary/login/notifications)
- Switched to Supabase Auth (email/password)
- Updated models to snake_case + mappers
- Configured auth redirects for GitHub Pages
- Deployed web build using --dart-define SUPABASE_ANON_KEY
```

## If something fails

- [ ] Auth redirect loop: check Auth → Redirect URLs (must include your Pages URL exactly)
- [ ] 403/401: RLS policies missing → apply the dev "allow all" policies temporarily
- [ ] CORS: Supabase handles it—usually mis-typed project URL; recheck url in Supabase.initialize
- [ ] White screen: clear browser cache/service worker, ensure main.dart.js and flutter_bootstrap.js are fresh