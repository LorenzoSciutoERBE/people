[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$toolRoot = Join-Path $workspace 'build/release-tools'
$null = New-Item -ItemType Directory -Path $toolRoot -Force
$download = Join-Path $toolRoot 'innosetup-6.7.4.exe'
Invoke-WebRequest -Uri 'https://github.com/jrsoftware/issrc/releases/download/is-6_7_4/innosetup-6.7.4.exe' -OutFile $download
$expectedHash = 'a549929319f9120716677c685535ca4671e4b937b5fdc87e2585f32d8eb30e8c'
if ((Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedHash) {
    throw 'Inno Setup compiler download checksum mismatch.'
}
$signature = Get-AuthenticodeSignature -LiteralPath $download
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Pyrsys B.V.') {
    throw 'Inno Setup compiler download signature verification failed.'
}
$destination = Join-Path $toolRoot 'inno'
$setup = Start-Process -FilePath $download -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CURRENTUSER', '/NOICONS', "/DIR=`"$destination`"") -WindowStyle Hidden -Wait -PassThru
if ($setup.ExitCode -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $destination 'ISCC.exe'))) {
    throw 'Inno Setup compiler installation failed.'
}
Write-Host "Installer compiler is ready: $destination"
