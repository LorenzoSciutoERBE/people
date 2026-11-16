# Testing

Run all checks from the repository root using PowerShell 7, with Flutter and Dart on `PATH`:

```powershell
.\Test-People.ps1
```

The script restores the locked dependencies, generates localizations, checks formatting without modifying files, runs static analysis, runs unit/widget tests with coverage, and runs the Windows integration suite in one test application. It stops on failure and returns a nonzero exit code. It resolves paths from its own directory, so it can be launched from any working directory.

Use `.\Test-People.ps1 -Suite Fast` for formatting, analysis, and unit/widget tests, or `.\Test-People.ps1 -Suite Integration` for Windows integration tests only. Add `-SkipPubGet` when dependencies are already restored. Reports are saved under `build/test-results/<timestamp>/`: `run.log`, `summary.json`, and machine-readable JSON test reports. Fast runs also write `coverage/lcov.info`. These outputs are ignored by Git. Windows integration tests require Visual Studio C++ desktop tools and installed Windows OCR language packs.

The single **Windows CI** pipeline runs both suites once on pushes to `master` and manual dispatches using a Windows runner and Flutter 3.47.8, then builds and verifies the installer and portable ZIP after tests pass. It provisions English/Italian OCR capabilities and fails explicitly if they cannot be installed. Reports and coverage are uploaded as workflow artifacts even when tests fail. No OAuth secrets or personal data are needed. The workflow is defined in `.github/workflows/release-windows.yml`. See [Windows releases](releases.md) for automatic patch versioning and serialization of pipeline runs.

Tests can also be invoked directly with `flutter test` and `flutter test integration_test -d windows`. Windows integration tests share the single entrypoint `integration_test/people_test.dart`, with separate groups for candidate workflows and native OCR. This avoids the Flutter startup failure when launching a second Windows test application in the same invocation. Run only OCR with `flutter test integration_test -d windows --name "Resume OCR"`, or only candidate workflows with `--name "Candidate workflows"`. Add new integration scenarios to the grouped suites rather than creating additional test entrypoints.

Integration tests use Flutter's official `integration_test` package, `IntegrationTestWidgetsFlutterBinding`, and `WidgetTester` interactions with stable English keys or UI text. They launch a separate Windows test application, use an encrypted temporary vault and an in-memory test key, and do not access the user's vault, OAuth credentials, or GitHub. Test files are removed afterward.

After significant changes, add or update regression tests and run the affected integration workflows autonomously. Keep unit and widget tests for fast edge-case coverage. The integration suite verifies long-feedback editing and persistence, one feedback per stage, unsaved-change protection, blocked pipeline transitions, and feedback editing in small desktop windows.

The OCR integration tests exercise the real Windows OCR channel using a generated resume image and scanned PDF, plus a three-page digital PDF that must be read without OCR. They require a supported Windows OCR language pack. Extracted line breaks and contact details are checked without uploading documents or using personal resumes.

For scanned resumes, Windows OCR automatically compares available English and Italian engines and falls back to the Windows preferred language if neither is available. Install OCR language packs under **Settings > Time & language > Language & region** if needed. Digital PDFs with usable embedded text do not require an OCR language pack.
