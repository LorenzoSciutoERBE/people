[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath 'HKCU:/Software/Microsoft/Windows/CurrentVersion/Uninstall/{6372CB4E-CA8D-4906-92B0-821E3365F071}_is1') {
    throw 'Package verification requires an isolated Windows account without an installed People application.'
}
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$releaseRoot = Join-Path $workspace "build/releases/$Version"
$testRoot = Join-Path $workspace "build/package-tests/$([Guid]::NewGuid())"
$portableRoot = Join-Path $testRoot 'portable'
$installedRoot = Join-Path $testRoot 'installed'
$null = New-Item -ItemType Directory -Path $testRoot -Force

foreach ($line in Get-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt')) {
    if ($line -notmatch '^([a-f0-9]{64})  (People-[a-zA-Z0-9.\-]+)$') { throw 'Invalid checksum manifest.' }
    $expected = $Matches[1]
    $artifact = Join-Path $releaseRoot $Matches[2]
    if ((Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
        throw "Checksum mismatch: $artifact"
    }
}

Expand-Archive -LiteralPath (Join-Path $releaseRoot "People-$Version-windows-x64-portable.zip") -DestinationPath $portableRoot
$installer = Join-Path $releaseRoot "People-$Version-windows-x64-setup.exe"
$setup = Start-Process -FilePath $installer -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', "/DIR=`"$installedRoot`"", "/LOG=`"$testRoot/install.log`"") -WindowStyle Hidden -Wait -PassThru
if ($setup.ExitCode -ne 0) { throw "Installer failed: $($setup.ExitCode)" }

$bundle = Join-Path $portableRoot 'People'
$files = @(Get-ChildItem -LiteralPath $bundle -File -Recurse)
if ($files.Count -lt 5) { throw 'Portable package is incomplete.' }
foreach ($file in $files) {
    $relative = [IO.Path]::GetRelativePath($bundle, $file.FullName)
    $installedFile = Join-Path $installedRoot $relative
    if (-not (Test-Path -LiteralPath $installedFile)) { throw "Installer omitted $relative" }
    if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $installedFile).Hash) {
        throw "Installed file differs from the portable distribution: $relative"
    }
}

$uninstall = Start-Process -FilePath (Join-Path $installedRoot 'unins000.exe') -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -WindowStyle Hidden -Wait -PassThru
if ($uninstall.ExitCode -ne 0) { throw "Uninstall failed: $($uninstall.ExitCode)" }
if (Test-Path -LiteralPath (Join-Path $installedRoot 'people.exe')) { throw 'Uninstall left the application executable behind.' }
Write-Host 'Checksums, portable extraction, installation, file parity, and uninstall passed.'
