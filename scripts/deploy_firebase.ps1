# Redeploys every Firebase surface (Firestore rules, Storage rules,
# Cloud Functions, web hosting) against the chosen project id.
#
# Usage:
#   ./scripts/deploy_firebase.ps1 -ProjectId csc234-user-centric-mobile-app
#   ./scripts/deploy_firebase.ps1 -ProjectId my-staging-project -Only functions
#   ./scripts/deploy_firebase.ps1 -ProjectId my-staging-project -SkipWebBuild
#
# Requires:
#   - firebase-tools CLI (`npm i -g firebase-tools`) authenticated via
#     `firebase login`.
#   - Flutter SDK on PATH (only when web hosting is in the deploy set).

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    # Comma-separated subset to deploy. Defaults to "all" which expands
    # to firestore,storage,functions,hosting.
    [string]$Only = 'all',

    # Skip the `flutter build web` step. Useful when iterating on rules
    # or functions and you don't want to rebuild the web bundle.
    [switch]$SkipWebBuild
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location $repoRoot
try {
    Write-Host "Deploying to $ProjectId ($Only)" -ForegroundColor Cyan

    # `all` mirrors what firebase.json actually declares - firestore +
    # storage rules, the Remote Config template, and functions.
    # Hosting is opt-in because the project doesn't ship a hosting
    # block today; passing `-Only hosting` lights it up once one is
    # added.
    $targets = if ($Only -eq 'all') {
        @('firestore', 'storage', 'remoteconfig', 'functions')
    } else {
        $Only.Split(',') | ForEach-Object { $_.Trim() }
    }

    # Ensure functions node_modules are in sync with pnpm-lock.yaml
    # before TypeScript build runs in the firebase predeploy step.
    # Otherwise stale or absent transitive deps (@simplewebauthn/server,
    # etc.) fail tsc with "Cannot find module" - exactly the error that
    # blocked v1.6 deploys.
    if ($targets -contains 'functions') {
        Write-Host "→ pnpm install (functions)" -ForegroundColor DarkCyan
        Push-Location (Join-Path $repoRoot 'functions')
        try {
            & pnpm install
            if ($LASTEXITCODE -ne 0) { throw "pnpm install (functions) failed" }
        } finally {
            Pop-Location
        }
    }

    # Build web bundle for hosting, unless explicitly skipped.
    if (($targets -contains 'hosting') -and (-not $SkipWebBuild)) {
        Write-Host "→ flutter build web" -ForegroundColor DarkCyan
        Push-Location (Join-Path $repoRoot 'apps/mobile')
        try {
            & flutter build web --release
            if ($LASTEXITCODE -ne 0) { throw "flutter build web failed" }
        } finally {
            Pop-Location
        }
    }

    foreach ($t in $targets) {
        Write-Host "→ firebase deploy --only $t --project $ProjectId" -ForegroundColor DarkCyan
        & firebase deploy --only $t --project $ProjectId
        if ($LASTEXITCODE -ne 0) { throw "firebase deploy --only $t failed" }
    }

    Write-Host "Done." -ForegroundColor Green
} finally {
    Pop-Location
}
