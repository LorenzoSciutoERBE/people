[CmdletBinding()]
param(
    [ValidateSet('All', 'Fast', 'Integration')]
    [string]$Suite = 'All',
    [switch]$SkipPubGet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Suite -ne 'Fast' -and [Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Windows integration tests require Windows, Visual Studio C++ desktop tools, and Windows OCR language packs. Use -Suite Fast on other platforms.'
}

$flutterCommand = (Get-Command flutter -ErrorAction Stop).Source
$dartCommand = (Get-Command dart -ErrorAction Stop).Source
$runId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$resultsDirectory = Join-Path $PSScriptRoot "build/test-results/$runId"
$null = New-Item -ItemType Directory -Path $resultsDirectory -Force
$checks = [System.Collections.Generic.List[object]]::new()
$passed = $false

function Invoke-Check {
    param(
        [string]$Name,
        [string]$Tool,
        [string[]]$ToolArguments
    )

    Write-Host "Running $Name..."
    $timer = [Diagnostics.Stopwatch]::StartNew()
    & $Tool @ToolArguments
    $commandExitCode = $LASTEXITCODE
    $timer.Stop()
    $checks.Add([pscustomobject]@{
        name = $Name
        exitCode = $commandExitCode
        durationSeconds = [Math]::Round($timer.Elapsed.TotalSeconds, 2)
    })
    if ($commandExitCode -ne 0) {
        throw "$Name failed with exit code $commandExitCode. Results: $resultsDirectory"
    }
}

Push-Location $PSScriptRoot
$null = Start-Transcript -Path (Join-Path $resultsDirectory 'run.log')
try {
    if (-not $SkipPubGet) {
        Invoke-Check -Name 'Dependency restore' -Tool $flutterCommand -ToolArguments @('pub', 'get', '--enforce-lockfile')
    }
    Invoke-Check -Name 'Localization generation' -Tool $flutterCommand -ToolArguments @('gen-l10n')

    if ($Suite -in @('All', 'Fast')) {
        Invoke-Check -Name 'Formatting' -Tool $dartCommand -ToolArguments @(
            'format', '--output=none', '--set-exit-if-changed', 'lib', 'test', 'integration_test'
        )
        Invoke-Check -Name 'Static analysis' -Tool $flutterCommand -ToolArguments @('analyze', '--no-pub', '--fatal-infos')
        Invoke-Check -Name 'Unit and widget tests' -Tool $flutterCommand -ToolArguments @(
            'test', '--no-pub', '--coverage', '--reporter', 'expanded',
            '--file-reporter', "json:$(Join-Path $resultsDirectory 'unit-widget.json')", 'test'
        )
    }

    if ($Suite -in @('All', 'Integration')) {
        $reportPath = Join-Path $resultsDirectory 'integration.json'
        Invoke-Check -Name 'Windows integration tests' -Tool $flutterCommand -ToolArguments @(
            'test', '--no-pub', 'integration_test', '-d', 'windows', '--reporter', 'expanded',
            '--file-reporter', "json:$reportPath"
        )
    }
    $passed = $true
    Write-Host "All requested checks passed. Results: $resultsDirectory"
}
finally {
    [pscustomobject]@{
        suite = $Suite
        passed = $passed
        checks = @($checks.ToArray())
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $resultsDirectory 'summary.json') -Encoding UTF8
    $null = Stop-Transcript
    Pop-Location
}
