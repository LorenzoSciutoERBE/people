# Windows releases

Push to `master` to run the single **Windows CI** workflow. It increments the patch version, then runs formatting, analysis, unit/widget tests, and Windows integration tests once before building the x64 distributions. It creates a **draft** GitHub Release with:

- `People-<version>-windows-x64-setup.exe`: per-user installer with Start menu integration, an optional desktop shortcut, upgrades using a stable application ID, and uninstall support.
- `People-<version>-windows-x64-portable.zip`: extract the entire archive and launch `People/people.exe`; keep its DLLs and data directory together.
- `SHA256SUMS.txt`: SHA-256 hashes for both downloads.

Manual workflow runs are also supported. Runs on `master` create a draft release; manual runs on other refs only upload workflow artifacts. Pull requests, pushes to other branches, and tag pushes do not trigger CI. Review the draft and publish it when ready. Existing releases are never overwritten. The packaging check validates hashes, extracts the ZIP, silently installs into an isolated directory, compares every installed file with the portable bundle, and uninstalls it.

## Automatic versioning

Each run increments the third version component: `1.0.0` becomes `1.0.1`, then `1.0.2`. On `master`, the version job checks out the latest branch tip, updates `pubspec.yaml` and the README version badge, and pushes a bot commit before testing. The internal Flutter build suffix is reset to `+1`; public package names, installer versions, and release tags use the three-part version, such as `v1.0.1`.

The version commit uses the workflow's `GITHUB_TOKEN` and includes `[skip ci]`, preventing a second automatic pipeline. Only the version and publish jobs have repository write permissions. Branch rules must allow the bot to push the version commit. A concurrent external push causes the version push to fail safely instead of overwriting changes; rerun the workflow if this happens.

All runs share one concurrency group, so only one pipeline executes at a time; GitHub may replace an older pending run with a newer one. The Windows build checks out the exact version commit, and the draft release targets that commit. Version numbers are reserved before validation, so failed runs can leave gaps. Rerunning increments the patch again. Manual runs outside `master` increment only their temporary checkout and never push version changes or publish a release.

Both packages contain the complete Flutter Release directory and the app-local Visual C++ runtime from the installed Visual Studio toolchain. They require Windows 10 version 1809 or later. Windows OCR features require the appropriate Windows OCR language capabilities on the destination machine.

The portable distribution does not require installation. Candidate data, preferences, and secure credentials continue to use the Windows user profile; they do not travel with the ZIP. Release builds use the repository's default configuration and do not embed local `env.json`, credentials, vaults, or user data. GitHub discovery requires an appropriately configured OAuth deployment.

Packages are unsigned until a code-signing certificate and signing process are configured. The workflow does not publish a public release automatically.

For a local build, install the Flutter version used in CI, Visual Studio C++ desktop tools, and Inno Setup 6.7.4, then run from PowerShell 7:

```powershell
./Test-People.ps1
./Build-WindowsRelease.ps1 -Version 1.0.0 -BuildNumber 1
./packaging/windows/Test-WindowsPackages.ps1 -Version 1.0.0
```

Use a clean checkout for each package build; packaging refuses an existing version output directory. Outputs stay under the ignored `build/` directory.

Run `./packaging/windows/Test-ReleaseVersion.ps1` to validate automatic patch increments, repeated runs, README badge updates, line ending preservation, and rejection of invalid or overflowing Windows versions. The tests use isolated temporary files and do not change the repository version.

CI installs the pinned Inno Setup compiler under `build/release-tools`, verifying both its SHA-256 digest and Authenticode publisher. To use the same compiler locally, run `./packaging/windows/Install-InnoSetup.ps1` and pass `-InnoSetupCompiler ./build/release-tools/inno/ISCC.exe` to the build script.
