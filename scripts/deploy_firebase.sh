#!/usr/bin/env bash
# Redeploys every Firebase surface (Firestore rules, Storage rules,
# Cloud Functions, web hosting) against the chosen project id.
#
# Usage:
#   ./scripts/deploy_firebase.sh <project-id>
#   ./scripts/deploy_firebase.sh <project-id> --only functions
#   ./scripts/deploy_firebase.sh <project-id> --skip-web-build
#
# Requires:
#   - firebase-tools CLI (`npm i -g firebase-tools`) authenticated via
#     `firebase login`.
#   - Flutter SDK on PATH (only when web hosting is in the deploy set).

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <project-id> [--only firestore,storage,functions,hosting] [--skip-web-build]" >&2
  exit 1
fi

PROJECT_ID="$1"; shift
ONLY="all"
SKIP_WEB_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only) ONLY="$2"; shift 2 ;;
    --skip-web-build) SKIP_WEB_BUILD=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "Deploying to $PROJECT_ID ($ONLY)"

# "all" matches what firebase.json actually declares — firestore +
# storage rules and functions. Hosting is opt-in because the project
# doesn't ship a hosting block today; pass `--only hosting` once one is
# added.
if [[ "$ONLY" == "all" ]]; then
  TARGETS=("firestore" "storage" "functions")
else
  IFS=',' read -r -a TARGETS <<< "$ONLY"
fi

contains_hosting=0
contains_functions=0
for t in "${TARGETS[@]}"; do
  if [[ "$t" == "hosting" ]]; then contains_hosting=1; fi
  if [[ "$t" == "functions" ]]; then contains_functions=1; fi
done

# Sync functions deps before the firebase predeploy build runs — the
# v1.6 deploy failed because @simplewebauthn/server was declared in
# package.json but missing from node_modules (pnpm install was never
# run after the dep was added).
if [[ "$contains_functions" -eq 1 ]]; then
  echo "→ pnpm install (functions)"
  (cd functions && pnpm install)
fi

if [[ "$contains_hosting" -eq 1 && "$SKIP_WEB_BUILD" -eq 0 ]]; then
  echo "→ flutter build web"
  (cd apps/mobile && flutter build web --release)
fi

for t in "${TARGETS[@]}"; do
  echo "→ firebase deploy --only $t --project $PROJECT_ID"
  firebase deploy --only "$t" --project "$PROJECT_ID"
done

echo "Done."
