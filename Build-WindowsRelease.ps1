[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,
    [ValidateRange(1, 65535)]
    [int]$BuildNumber = 1,
    [string]$InnoSetupCompiler = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'Windows release packaging requires Windows.' }
if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne [Runtime.InteropServices.Architecture]::X64) { throw 'This release pipeline requires an x64 Windows build host.' }
if (-not (Test-Path -LiteralPath $InnoSetupCompiler)) { throw 'Install Inno Setup 6 or supply -InnoSetupCompiler.' }
$packageVersion = (Select-String -LiteralPath "$PSScriptRoot/pubspec.yaml" -Pattern '^version: (\d+\.\d+\.\d+)\+\d+$').Matches.Groups[1].Value
if ($Version -ne $packageVersion) { throw "Release version $Version must match pubspec.yaml version $packageVersion." }

$releaseRoot = Join-Path $PSScriptRoot "build/releases/$Version"
if ((Test-Path -LiteralPath $releaseRoot) -and @(Get-ChildItem -LiteralPath $releaseRoot -Recurse -File).Count -gt 0) { throw "Release output already exists: $releaseRoot. Use a clean checkout to avoid stale artifacts." }
$bundle = Join-Path $releaseRoot 'People'
$null = New-Item -ItemType Directory -Path $bundle -Force
Push-Location $PSScriptRoot
try {
    & flutter build windows --release --build-name $Version --build-number $BuildNumber
    if ($LASTEXITCODE -ne 0) { throw 'Flutter Windows release build failed.' }
    $buildDirectory = Join-Path $PSScriptRoot 'build/windows/x64/runner/Release'
    Copy-Item -Path "$buildDirectory/*" -Destination $bundle -Recurse

    # App-local CRT deployment keeps both distributions usable without an administrator install.
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    $visualStudio = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -ne 0 -or -not $visualStudio) { throw 'Visual Studio C++ desktop tools were not found.' }
    $redistVersion = (Get-Content -LiteralPath "$visualStudio/VC/Auxiliary/Build/Microsoft.VCRedistVersion.default.txt" -Raw).Trim()
    $crt = Get-ChildItem -Path "$visualStudio/VC/Redist/MSVC/$redistVersion/x64/Microsoft.VC*.CRT" -Directory | Select-Object -First 1
    if (-not $crt) { throw 'The redistributable x64 C++ runtime was not found.' }
    Copy-Item -Path "$($crt.FullName)/*.dll" -Destination $bundle
    foreach ($required in @('people.exe', 'flutter_windows.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll', 'data/flutter_assets')) {
        if (-not (Test-Path -LiteralPath (Join-Path $bundle $required))) { throw "Missing release component: $required" }
    }
    $portable = Join-Path $releaseRoot "People-$Version-windows-x64-portable.zip"
    Compress-Archive -LiteralPath $bundle -DestinationPath $portable -CompressionLevel Optimal
    & $InnoSetupCompiler "/DAppVersion=$Version" "/DBundleDirectory=$bundle" "/DReleaseDirectory=$releaseRoot" "$PSScriptRoot/packaging/windows/people.iss"
    if ($LASTEXITCODE -ne 0) { throw 'Windows installer compilation failed.' }
    $installer = Join-Path $releaseRoot "People-$Version-windows-x64-setup.exe"
    if (-not (Test-Path -LiteralPath $installer)) { throw 'The installer was not created.' }
    $checksums = foreach ($artifact in @($installer, $portable)) {
        $hash = Get-FileHash -LiteralPath $artifact -Algorithm SHA256
        "$($hash.Hash.ToLowerInvariant())  $([IO.Path]::GetFileName($artifact))"
    }
    $checksums | Set-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt') -Encoding utf8NoBOM
    Write-Host "Windows release artifacts are ready: $releaseRoot"
}
finally { Pop-Location }
