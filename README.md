# People

People is a Windows desktop recruiting application. It opens on the hiring pipeline and includes GitHub talent search, saved profiles, candidate records, interview feedback, and offer tracking.

The Material 3 navigation separates **Candidates**, **GitHub search**, **Favorites**, and **Hired people**; **Settings** is available at the bottom of the sidebar. GitHub search supports repository languages, location, repository counts, and follower filters. Search results can be saved as favorites or added directly to the hiring pipeline.

Candidate records and resumes are stored locally in an AES-GCM encrypted vault. The vault key is held by Windows secure storage (DPAPI). PDF, PNG, and JPEG resumes up to 15 MB are supported. Text-based PDFs are read locally; scanned PDFs and images use Windows OCR with installed language packs. Candidate records do not leave the computer. The hiring pipeline is CV review → introductory interview → technical interview → Germany interview → offer → hired or rejected. CV review records initial notes without an approval decision. Each interview tracks its date, time, interviewer, internal decision, and candidate communication. Positive feedback advances a candidate after it has been communicated; negative feedback enables rejection after communication. The offer stage handles preparation and proposal, and hiring requires an accepted offer. Board cards and the candidate list show pending communication even when evaluation scores are hidden. The candidate list can filter pending candidate communication. Existing version 1 vaults are migrated once, returning candidates to CV review while retaining profiles and resumes.

Recruiting sources and hiring-stage names/order are configurable in Settings. The initial source list includes Grafton, Poli, GitHub, and Other.

**Hired people** contains everyone in a stage with a hired outcome. Open a person to view recruiting history and add or edit ongoing reviews with a date, reviewer, discussion notes, and follow-up goals. Reviews and meeting plans remain in the encrypted vault; older vaults load without modification.

Moving a candidate to a hired stage opens a hiring-date form and proposes 1-hour follow-ups at 15:00 after 1, 3, 6, and 12 calendar months. Month-end anniversaries use the last valid day of the target month. Confirm hiring with a single action and optionally select calendar export; canceling the file chooser keeps the hiring and meeting plan saved. Adjust meeting dates/times, mark completed meetings, and export a calendar file either while hiring or later from the person's history. Changing the hiring date regenerates the proposed dates and preserves completion flags.

The app shows reminders for incomplete meetings that are overdue or due within the next seven days, updating while the app is open. Calendar files follow [RFC 5545](https://www.rfc-editor.org/rfc/rfc5545), include tentative appointments with 1-day and 15-minute alarms, and use local wall-clock times. Import the `.ics` file into your calendar to schedule the meetings; exporting does not book meetings or send invitations. Closed-app reminders depend on the imported calendar's notification settings. Event IDs remain stable across exports, but calendar import tools may require replacing an earlier import to avoid duplicates.

## Local configuration

Copy `env.example.json` to `env.json`, then set `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` from your GitHub OAuth App. Keep `env.json` private; it is excluded from Git. The OAuth client secret is embedded in a desktop build and is not protected from extraction. Do not distribute a build containing your personal credentials.

## Testing

Run all checks from PowerShell (Flutter/Dart must be on `PATH`):

```powershell
.\Test-People.ps1
```

The script restores the locked dependencies, generates localizations, checks formatting without modifying files, runs static analysis, runs unit/widget tests with coverage, and runs the Windows integration suite in one test application. It stops on failure and returns a nonzero exit code. It resolves paths from its own directory, so it can be launched from any working directory.

Use `.\Test-People.ps1 -Suite Fast` for formatting, analysis, and unit/widget tests, or `.\Test-People.ps1 -Suite Integration` for Windows integration tests only. Add `-SkipPubGet` when dependencies are already restored. Reports are saved under `build/test-results/<timestamp>/`: `run.log`, `summary.json`, and machine-readable JSON test reports. Fast runs also write `coverage/lcov.info`. These outputs are ignored by Git. Windows integration tests require Visual Studio C++ desktop tools and installed Windows OCR language packs.

GitHub Actions runs both suites on pushes, pull requests, and manual dispatches using Windows runners and Flutter 3.47.8. The integration job provisions English/Italian OCR capabilities and fails explicitly if they cannot be installed. Reports and coverage are uploaded as workflow artifacts even when tests fail. No OAuth secrets or personal data are needed. The workflow is defined in `.github/workflows/tests.yml`; its first hosted run happens after these files are pushed to GitHub.

Tests can also be invoked directly with `flutter test` and `flutter test integration_test -d windows`. Windows integration tests share the single entrypoint `integration_test/people_test.dart`, with separate groups for candidate workflows and native OCR. This avoids the Flutter startup failure when launching a second Windows test application in the same invocation. Run only OCR with `flutter test integration_test -d windows --name "Resume OCR"`, or only candidate workflows with `--name "Candidate workflows"`. Add new integration scenarios to the grouped suites rather than creating additional test entrypoints.

Integration tests use Flutter's official `integration_test` package, `IntegrationTestWidgetsFlutterBinding`, and `WidgetTester` interactions with stable English keys or UI text. They launch a separate Windows test application, use an encrypted temporary vault and an in-memory test key, and do not access the user's vault, OAuth credentials, or GitHub. Test files are removed afterward.

After significant changes, add or update regression tests and run the affected integration workflows autonomously. Keep unit and widget tests for fast edge-case coverage. The integration suite verifies long-feedback editing and persistence, one feedback per stage, unsaved-change protection, blocked pipeline transitions, and feedback editing in small desktop windows.

The OCR integration tests exercise the real Windows OCR channel using a generated resume image and scanned PDF, plus a three-page digital PDF that must be read without OCR. They require a supported Windows OCR language pack. Extracted line breaks and contact details are checked without uploading documents or using personal resumes.

For scanned resumes, Windows OCR automatically compares available English and Italian engines and falls back to the Windows preferred language if neither is available. Install OCR language packs under **Settings > Time & language > Language & region** if needed. Digital PDFs with usable embedded text do not require an OCR language pack.

## Start the Windows application

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

## Windows release packages

See [Windows release instructions](packaging/windows/README.md) for the version-tag workflow, installer, portable ZIP, checksums, local builds, and draft GitHub Releases.
