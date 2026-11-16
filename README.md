# People

[![Dart SDK](https://img.shields.io/badge/Dart-%5E3.13.5-0175C2?logo=dart&logoColor=white)](pubspec.yaml)
[![C++](https://img.shields.io/badge/C%2B%2B-17-00599C?logo=cplusplus&logoColor=white)](windows/CMakeLists.txt)
[![PowerShell](https://img.shields.io/badge/PowerShell-7-5391FE)](docs/development.md)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.8-02569B?logo=flutter&logoColor=white)](.github/workflows/tests.yml)
[![Version](https://img.shields.io/badge/version-1.0.0-2ea44f)](pubspec.yaml)
[![Platform](https://img.shields.io/badge/platform-Windows_x64-0078D4)](docs/releases.md)
[![Tests](https://github.com/LorenzoSciutoERBE/people/actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/LorenzoSciutoERBE/people/actions/workflows/tests.yml)
[![Windows release](https://github.com/LorenzoSciutoERBE/people/actions/workflows/release-windows.yml/badge.svg?branch=master)](https://github.com/LorenzoSciutoERBE/people/actions/workflows/release-windows.yml)

A Windows desktop app for managing recruitment, from discovering talent to following up with new hires. Built with Flutter, with English and Italian interfaces.

## Features

- **Hiring pipeline:** manage candidates, resumes, interview feedback, offers, and communication status.
- **GitHub talent search:** find developers by language, location, repositories, and followers; save favorites or add candidates to your pipeline.
- **Resume import:** read PDF, PNG, and JPEG files, including scanned documents through Windows OCR.
- **Employee follow-ups:** record reviews, track meeting reminders, and export calendar appointments.
- **Customizable workflow:** configure recruiting sources and hiring stages.
- **Local storage:** keep candidate records and resumes in an encrypted vault on your computer.

## Download and install

Check [GitHub Releases](https://github.com/LorenzoSciutoERBE/people/releases) for published Windows x64 packages:

| Package | How to use it |
| --- | --- |
| `People-<version>-windows-x64-setup.exe` | Run the per-user installer. Includes shortcuts and an uninstaller. |
| `People-<version>-windows-x64-portable.zip` | Extract the whole archive and launch `People/people.exe`. |
| `SHA256SUMS.txt` | Verify the SHA-256 hashes of the downloaded packages. |

Requires Windows 10 version 1809 or later. Packages are currently unsigned. The portable package stores application data in your Windows user profile; that data does not travel with the ZIP. Scanned resume import requires Windows OCR language capabilities.

CI creates draft releases for review; drafts are not public downloads until published. Workflow artifacts are also available from successful [Windows release runs](https://github.com/LorenzoSciutoERBE/people/actions/workflows/release-windows.yml), subject to GitHub access permissions and artifact retention.

## Privacy and GitHub access

Candidate records and resumes are stored locally in an AES-GCM encrypted vault, with the key held by Windows secure storage (DPAPI). Resume parsing runs on your computer. GitHub search connects to GitHub and requires a configured OAuth deployment; the default release packages do not embed local OAuth credentials.

## Run from source

Install Flutter and Visual Studio C++ desktop tools, then run from the repository root:

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter run -d windows
```

For GitHub OAuth configuration, release builds, and troubleshooting, see [development setup](docs/development.md).

## Documentation

- [User guide](docs/user-guide.md): recruiting stages, interviews, reviews, reminders, and calendar exports.
- [Development setup](docs/development.md): prerequisites, configuration, project structure, and local startup.
- [Testing](docs/testing.md): validation commands, integration tests, OCR requirements, and reports.
- [Windows releases](docs/releases.md): CI triggers, packaging, verification, and publishing.

## Contributing

Read the [engineering guardrails](AGENTS.md), keep UI strings localized, and include regression coverage for behavior changes. Run the [validation suite](docs/testing.md) before submitting a pull request. Automatic CI runs on pushes to `master`; manual workflow runs are also supported.
