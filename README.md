# sacred_compass

sacred compass mobile application

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Run the Supabase development screen

Install the Flutter SDK, then copy `config.example.json` to `config.json` if
you do not already have it. Fill in the HTTPS project URL and the client
publishable key for `sacred-compass-dev`. Keep `config.json` local and use only
the publishable key. The app reads these values at build time and needs an
internet connection to load places.

On Android, enable USB debugging, connect and unlock the phone, and accept the
debugging prompt. From the Flutter project root, run:

```powershell
flutter pub get
flutter devices
flutter run -d <device-id> --dart-define-from-file=config.json
```

Replace `<device-id>` with the ID shown by `flutter devices`. On iOS, run the
same Flutter commands from a Mac with Xcode and a configured iOS device.

Run local checks without live credentials:

```powershell
flutter analyze
flutter test
```

The temporary screen should show **[DEMO] Kaya Giriama** and exclude the Kaya
Jibana and Kaya Kambe drafts. The app filters by publication status, so verify
Row Level Security separately with an anonymous request that omits that filter.
Run this from the project root in PowerShell:

```powershell
$config = Get-Content config.json -Raw | ConvertFrom-Json
$rows = Invoke-RestMethod -Uri ($config.SUPABASE_URL.TrimEnd('/') + '/rest/v1/places?select=slug,name,status') -Headers @{
  apikey = $config.SUPABASE_PUBLISHABLE_KEY
  'Accept-Profile' = 'public'
}
$rows | Select-Object slug, name, status
```

Expect the Giriama record with status `published`. Any returned draft or other
non-published record is an RLS verification failure.
