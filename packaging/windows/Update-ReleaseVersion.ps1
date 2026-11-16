[CmdletBinding()]
param(
    [string]$Workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$pubspecPath = Join-Path $Workspace 'pubspec.yaml'
$pubspec = [IO.File]::ReadAllText($pubspecPath)
$pattern = '(?m)^version: (\d+)\.(\d+)\.(\d+)\+\d+(?=\r?$)'
$match = [regex]::Match($pubspec, $pattern)
if (-not $match.Success) { throw 'pubspec.yaml must contain a three-part version and build number.' }
$major = [int]$match.Groups[1].Value
$minor = [int]$match.Groups[2].Value
$patch = [int]$match.Groups[3].Value + 1
if ($major -gt 65535 -or $minor -gt 65535 -or $patch -gt 65535) {
    throw 'Windows version components must not exceed 65535.'
}
$version = "$major.$minor.$patch"
$updated = [regex]::Replace($pubspec, $pattern, "version: $version+1")
$readmePath = Join-Path $Workspace 'README.md'
$readme = [IO.File]::ReadAllText($readmePath)
$readme = [regex]::Replace($readme, 'badge/version-\d+\.\d+\.\d+-', "badge/version-$version-")
[IO.File]::WriteAllText($pubspecPath, $updated)
[IO.File]::WriteAllText($readmePath, $readme)
Write-Output $version
