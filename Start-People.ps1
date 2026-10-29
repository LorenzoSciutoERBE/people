param(
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$configurationPath = Join-Path $projectRoot 'env.json'
$applicationPath = Join-Path $projectRoot 'build\windows\x64\runner\Release\people.exe'

Push-Location $projectRoot
try {
    if ($NoBuild) {
        if (-not (Test-Path -LiteralPath $applicationPath -PathType Leaf)) {
            throw "No release executable was found at $applicationPath. Run Start-People.ps1 without -NoBuild to build it."
        }
    }
    else {
        if (-not (Test-Path -LiteralPath $configurationPath -PathType Leaf)) {
            throw "Missing local configuration: $configurationPath. Copy env.example.json to env.json and set your GitHub OAuth credentials."
        }

        & flutter build windows --release "--dart-define-from-file=$configurationPath"
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter Windows build failed with exit code $LASTEXITCODE."
        }
    }

    if (-not (Test-Path -LiteralPath $applicationPath -PathType Leaf)) {
        throw "People executable was not found at $applicationPath."
    }

    Start-Process -FilePath $applicationPath -WorkingDirectory (Split-Path $applicationPath)
}
finally {
    Pop-Location
}
