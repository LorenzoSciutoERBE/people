# Development

Run commands from the repository root using PowerShell 7.

## Prerequisites

- Windows x64 with Visual Studio C++ desktop tools.
- Flutter 3.47.8, matching CI, and its bundled Dart SDK. The package requires Dart `^3.13.5`.
- Windows OCR language capabilities for English and Italian to run the full integration suite.

## Setup

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
Copy-Item env.example.json env.json
```

## GitHub configuration

Copy `env.example.json` to `env.json`, then set `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` from your GitHub OAuth App. Keep `env.json` private; it is excluded from Git. The OAuth client secret is embedded in a desktop build and is not protected from extraction. Do not distribute a build containing your personal credentials.

Pass that configuration when running GitHub search locally:

```powershell
flutter run -d windows --dart-define-from-file=env.json
```

## Running the app

Use `flutter run -d windows` to launch the Windows application. If Flutter reports access denied while determining the engine version, check that `pwsh.exe` resolves to a working PowerShell installation. After updating the user PATH, restart the terminal application so it inherits the new environment. As an optional temporary fallback, `.\Run-People.ps1` excludes the Microsoft Store execution-alias directory from PATH only while Flutter runs and restores the terminal environment afterward. It does not modify the Flutter SDK or persistent system settings. Pass extra Flutter options after the script name, or use `.\Run-People.ps1 -Check` to verify Flutter startup without launching the app.

Run `Start-People.ps1` from PowerShell. It builds the release executable with the local configuration, then starts it:

```powershell
.\Start-People.ps1
```

Use `-NoBuild` to start an existing release build without rebuilding it or requiring the local OAuth configuration file:

```powershell
.\Start-People.ps1 -NoBuild
```

If Windows blocks the local script, unblock this file in its Properties dialog, or run the script for the current invocation with:

```powershell
powershell -ExecutionPolicy Bypass -File .\Start-People.ps1
```

The application icon is embedded in the Windows executable. To pin People to the taskbar, launch the application, right-click its taskbar icon, and choose **Pin to taskbar**.

## Project structure

Features live under `lib/features/<feature>/{data,domain,presentation}`. Shared widgets and theme code live under `lib/shared`; cross-cutting infrastructure lives under `lib/core`. English and Italian UI translations live under `lib/l10n`. Read [the engineering guardrails](../AGENTS.md) before contributing and run [the validation suite](testing.md) before submitting changes.
