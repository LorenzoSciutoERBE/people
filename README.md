# People

People is a Windows desktop recruiting application. It opens on the hiring pipeline and includes GitHub talent search, saved profiles, candidate records, interview feedback, and offer tracking.

The Material 3 navigation separates **Candidates**, **GitHub search**, and **Favorites**; **Settings** is available from the top bar. GitHub search supports repository languages, location, repository counts, and follower filters. Search results can be saved as favorites or added directly to the hiring pipeline.

Candidate records and resumes are stored locally in an AES-GCM encrypted vault. The vault key is held by Windows secure storage (DPAPI). PDF, PNG, and JPEG resumes up to 15 MB are supported. Text-based PDFs are read locally; scanned PDFs and images use Windows OCR with installed language packs. Candidate records do not leave the computer. Pipeline transitions require explicit feedback: positive feedback advances a candidate, negative feedback can reject them, and hiring requires an accepted offer.

Recruiting sources and hiring-stage names/order are configurable in Settings. The initial source list includes Grafton, Poli, GitHub, and Other.

## Local configuration

Copy `env.example.json` to `env.json`, then set `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` from your GitHub OAuth App. Keep `env.json` private; it is excluded from Git. The OAuth client secret is embedded in a desktop build and is not protected from extraction. Do not distribute a build containing your personal credentials.

## Start the Windows application

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
