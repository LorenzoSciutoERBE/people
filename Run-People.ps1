[CmdletBinding()]
param(
    [switch]$Check,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$originalPath = $env:PATH
$windowsAppsDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
$commandExitCode = 1

Push-Location $PSScriptRoot
try {
    # Flutter prefers the Store pwsh alias even when Windows cannot launch it.
    # Exclude that alias directory for this invocation and its child processes.
    $env:PATH = ($originalPath -split ';' | Where-Object {
        $_.TrimEnd('\') -ine $windowsAppsDirectory.TrimEnd('\')
    }) -join ';'
    $flutterCommand = (Get-Command flutter.bat -CommandType Application -ErrorAction Stop |
        Select-Object -First 1).Source
    if ($Check) {
        & $flutterCommand --version
    } else {
        & $flutterCommand run -d windows @FlutterArguments
    }
    $commandExitCode = $LASTEXITCODE
} finally {
    $env:PATH = $originalPath
    Pop-Location
}
exit $commandExitCode
