[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "people-version-tests-$([Guid]::NewGuid())"
$null = New-Item -ItemType Directory -Path $testRoot
try {
    $pubspecPath = Join-Path $testRoot 'pubspec.yaml'
    $readmePath = Join-Path $testRoot 'README.md'
    foreach ($newline in @("`n", "`r`n")) {
        [IO.File]::WriteAllText($pubspecPath, "name: people${newline}version: 1.2.3+9${newline}")
        [IO.File]::WriteAllText($readmePath, '[![Version](https://img.shields.io/badge/version-1.2.3-2ea44f)](pubspec.yaml)')
        $version = & "$PSScriptRoot/Update-ReleaseVersion.ps1" -Workspace $testRoot
        if ($version -ne '1.2.4') { throw 'Patch version was not incremented.' }
        if ([IO.File]::ReadAllText($pubspecPath) -cne "name: people${newline}version: 1.2.4+1${newline}") {
            throw 'The build number or original line endings were not preserved correctly.'
        }
        if (-not [IO.File]::ReadAllText($readmePath).Contains('badge/version-1.2.4-')) {
            throw 'The README badge was not updated.'
        }
        $next = & "$PSScriptRoot/Update-ReleaseVersion.ps1" -Workspace $testRoot
        if ($next -ne '1.2.5') { throw 'Repeated runs must increment the stored patch version.' }
    }
    foreach ($invalid in @('version: invalid', 'version: 1.2.65535+1', 'version: 65536.2.3+1')) {
        [IO.File]::WriteAllText($pubspecPath, $invalid)
        $rejected = $false
        try {
            $null = & "$PSScriptRoot/Update-ReleaseVersion.ps1" -Workspace $testRoot
        } catch [System.Management.Automation.RuntimeException] {
            $rejected = $true
        }
        if (-not $rejected) { throw "Invalid version was accepted: $invalid" }
        if ([IO.File]::ReadAllText($pubspecPath) -cne $invalid) { throw 'Rejected input must not change.' }
    }
    Write-Output 'Release version regression checks passed.'
} finally {
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Test cleanup must stay inside the temporary directory.'
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
