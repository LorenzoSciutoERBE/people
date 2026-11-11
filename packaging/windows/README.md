# Windows releases

Update `version` in `pubspec.yaml`, commit the changes, and push a matching tag such as `v1.0.0`. The Release Windows workflow runs formatting, analysis, unit/widget tests, and Windows integration tests before building the x64 distributions. It creates a **draft** GitHub Release with:

- `People-<version>-windows-x64-setup.exe`: per-user installer with Start menu integration, an optional desktop shortcut, upgrades using a stable application ID, and uninstall support.
- `People-<version>-windows-x64-portable.zip`: extract the entire archive and launch `People/people.exe`; keep its DLLs and data directory together.
- `SHA256SUMS.txt`: SHA-256 hashes for both downloads.

Manual workflow runs upload the same artifacts without creating a GitHub Release. Review the draft and publish it when ready. Existing releases are never overwritten. The packaging check validates hashes, extracts the ZIP, silently installs into an isolated directory, compares every installed file with the portable bundle, and uninstalls it.

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

CI installs the pinned Inno Setup compiler under `build/release-tools`, verifying both its SHA-256 digest and Authenticode publisher. To use the same compiler locally, run `./packaging/windows/Install-InnoSetup.ps1` and pass `-InnoSetupCompiler ./build/release-tools/inno/ISCC.exe` to the build script.
