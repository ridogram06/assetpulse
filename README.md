# AssetPulse — Setup Guide

## Prerequisites
- Flutter SDK (3.x) → https://docs.flutter.dev/get-started/install/windows
- Android Studio → https://developer.android.com/studio
- A Supabase project → https://supabase.com (free)
- A Firebase project → https://console.firebase.google.com (free)

---

## Step 1 — Flutter Setup (if not installed)
```powershell
# Download Flutter SDK
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.29.3-stable.zip" -OutFile "D:\flutter_sdk.zip"
Expand-Archive "D:\flutter_sdk.zip" -DestinationPath "D:\"

# Add D:\flutter\bin to your PATH (System Environment Variables)
# Then verify:
flutter doctor
```

---

## Step 2 — Android Studio
```powershell
winget install Google.AndroidStudio
```
After install:
1. Open Android Studio → SDK Manager → install Android SDK 34
2. Accept all licenses: `flutter doctor --android-licenses`

---

## Step 3 — Create Flutter Project Shell
```powershell
cd D:\
flutter create assetpulse --org com.assetpulse --platforms android
```
Then **replace** the generated `lib/` and `pubspec.yaml` with the files in this repo.

---

## Step 4 — Supabase Setup
1. Create a project at https://supabase.com
2. Go to **SQL Editor** → run `supabase/migrations/001_initial_schema.sql`
3. Go to **Settings → API** and copy:
   - Project URL
   - anon/public key

---

## Step 5 — Firebase Setup
1. Create project at https://console.firebase.google.com
2. Add Android app: package name = `com.assetpulse`
3. Download `google-services.json` → place in `android/app/`
4. Enable **Cloud Messaging** in Firebase Console

---

## Step 6 — Configure Keys
Edit `lib/main.dart` and replace:
```dart
url: 'YOUR_SUPABASE_URL',       // from Step 4
anonKey: 'YOUR_SUPABASE_ANON_KEY',  // from Step 4
```

Or use `--dart-define` at build time:
```powershell
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

## Step 7 — Add Fonts & Assets
Download and place in `assets/fonts/`:
- `HindSiliguri-Regular.ttf` & `HindSiliguri-Bold.ttf` → https://fonts.google.com/specimen/Hind+Siliguri
- `JetBrainsMono-Regular.ttf` & `JetBrainsMono-Bold.ttf` → https://www.jetbrains.com/lp/mono/

Create empty `assets/animations/` and `assets/images/` folders.

---

## Step 8 — Generate Drift Code
```powershell
cd D:\assetpulse
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## Step 9 — Deploy Edge Function
```bash
supabase functions deploy send-notification --project-ref YOUR_PROJECT_REF
supabase secrets set RESEND_API_KEY=re_xxxx --project-ref YOUR_PROJECT_REF
```

---

## Step 10 — Run
```powershell
flutter run
```

---

## Step 11 — UptimeRobot (Keep Supabase Alive)
1. Go to https://uptimerobot.com (free)
2. Add HTTP monitor:
   - URL: `https://YOUR_PROJECT_REF.supabase.co/rest/v1/`
   - Header: `apikey: YOUR_ANON_KEY`
   - Interval: every 4 days

---

## Project Structure
```
D:\assetpulse\
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/           (constants, theme, router, providers, services)
│   ├── data/           (models, local DB/DAOs, remote repos)
│   ├── domain/         (entities, use cases)
│   └── presentation/   (screens, widgets, providers)
├── supabase/
│   ├── migrations/001_initial_schema.sql
│   └── functions/send-notification/index.ts
└── pubspec.yaml
```

## Total Cost: $0.00
