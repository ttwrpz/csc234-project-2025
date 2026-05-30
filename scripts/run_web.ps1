# Launch the Flutter web build in Chrome on a PINNED port (5173).
#
# WebAuthn's expectedOrigin check is exact-match against
# functions/.env's WEBAUTHN_STAGING_ORIGINS, so a stable origin is a
# hard requirement for the "Use security key" flow to verify. Without
# pinning, `flutter run -d chrome` chooses a random port and the
# ceremony fails with verification_failed on the finish leg.
#
# Usage:
#   ./scripts/run_web.ps1              # defaults to 5173
#   ./scripts/run_web.ps1 -Port 3000   # any other port that is in the .env list

[CmdletBinding()]
param(
    [int]$Port = 5173,
    [string]$Hostname = 'localhost'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location (Join-Path $repoRoot 'apps/mobile')
try {
    Write-Host "flutter run -d chrome --web-hostname=$Hostname --web-port=$Port" -ForegroundColor Cyan
    & flutter run -d chrome --web-hostname=$Hostname --web-port=$Port
    if ($LASTEXITCODE -ne 0) { throw "flutter run failed (exit $LASTEXITCODE)" }
} finally {
    Pop-Location
}
