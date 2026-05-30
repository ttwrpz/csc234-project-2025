#!/usr/bin/env bash
# Launch the Flutter web build in Chrome on a PINNED port (5173).
#
# WebAuthn's expectedOrigin check is exact-match against functions/.env's
# WEBAUTHN_STAGING_ORIGINS, so a stable origin is a hard requirement for
# the "Use security key" flow to verify. Without pinning,
# `flutter run -d chrome` chooses a random port and the ceremony fails
# with verification_failed on the finish leg.
#
# Usage:
#   ./scripts/run_web.sh            # defaults to 5173
#   ./scripts/run_web.sh 3000       # any other port that is in the .env list

set -euo pipefail

PORT="${1:-5173}"
HOSTNAME_ARG="${2:-localhost}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}/apps/mobile"

echo "flutter run -d chrome --web-hostname=${HOSTNAME_ARG} --web-port=${PORT}"
exec flutter run -d chrome --web-hostname="${HOSTNAME_ARG}" --web-port="${PORT}"
