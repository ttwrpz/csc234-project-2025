#!/usr/bin/env bash
# Evidence package builder for the May 30 final submission.
# S5 plan §10 — assembles docs/submission/ from the canonical sources
# already living in the repo + a few generated artifacts (CI run logs,
# coverage summary, golden PNG copies). Idempotent: blows away
# docs/submission/ each run so a Day-4 dry-run does not leak stale
# evidence into the Day-5 final bundle.
#
# Usage:
#   tool/package_evidence.sh                  # build + leave the dir in place
#   tool/package_evidence.sh --zip            # also produce docs/submission.zip
#   tool/package_evidence.sh --skip-ci        # skip `gh run view` calls (offline-friendly)
#
# Exit codes:
#   0  — success
#   1  — missing required source (e.g. an audit doc the bundle depends on)
#   2  — `gh` CLI unavailable when CI run capture was requested
#
# Requires: bash 4+, the `gh` CLI authenticated (unless --skip-ci),
# `zip` if --zip is passed. Runs from the repo root.

set -euo pipefail

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

WANT_ZIP=0
SKIP_CI=0
for arg in "$@"; do
  case "$arg" in
    --zip) WANT_ZIP=1 ;;
    --skip-ci) SKIP_CI=1 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2 ; exit 1 ;;
  esac
done

# Resolve repo root from script location so the script can be invoked
# from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

OUT="$REPO_ROOT/docs/submission"
EV="$OUT/evidence"

echo "→ Cleaning $OUT/"
rm -rf "$OUT"
mkdir -p "$EV"
mkdir -p "$EV/ci-runs" "$EV/coverage" "$EV/crashlytics" "$EV/goldens" \
         "$EV/qa" "$EV/security" "$EV/transcripts" "$EV/transcripts/handoff-briefs"

# ---------------------------------------------------------------------------
# 1. Top-level documents — copy from canonical paths
# ---------------------------------------------------------------------------

# Required source files. Bail loudly if any is missing — the submission
# package must be reproducible from the repo, not assembled by hand.
require() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing required file: $path" >&2
    exit 1
  fi
}

require "docs/audit/enterprise-audit-report.md"
require "docs/runbooks/feature-flag-rollback.md"
require "docs/runbooks/devops-followups.md"
require ".github/PULL_REQUEST_TEMPLATE.md"

cp "docs/audit/enterprise-audit-report.md" "$OUT/enterprise-audit-report.md"
echo "→ Copied enterprise audit report"

# ---------------------------------------------------------------------------
# 2. Evidence — handoff briefs, ADRs, retros, security audits, QA, runbooks
# ---------------------------------------------------------------------------

# Handoff briefs — copy every .md under .claude/briefs/sprint-*/
if compgen -G ".claude/briefs/sprint-*/*.md" > /dev/null; then
  cp -r .claude/briefs/sprint-* "$EV/transcripts/handoff-briefs/"
  echo "→ Copied handoff briefs"
fi

# ADRs — every numbered file in docs/adr/
if compgen -G "docs/adr/*.md" > /dev/null; then
  mkdir -p "$EV/adr"
  cp docs/adr/*.md "$EV/adr/"
  echo "→ Copied $(ls docs/adr/*.md | wc -l) ADR(s)"
fi

# Sprint retros
if compgen -G "docs/retros/*.md" > /dev/null; then
  mkdir -p "$EV/retros"
  cp docs/retros/*.md "$EV/retros/"
  echo "→ Copied $(ls docs/retros/*.md | wc -l) sprint retro(s)"
fi

# Security audits
if compgen -G "docs/security/*.md" > /dev/null; then
  cp docs/security/*.md "$EV/security/"
  echo "→ Copied security audits"
fi

# QA matrices
if compgen -G "docs/qa/*.md" > /dev/null; then
  cp docs/qa/*.md "$EV/qa/"
  echo "→ Copied QA matrices"
fi

# Runbooks
if [[ -d "docs/runbooks" ]]; then
  mkdir -p "$EV/runbooks"
  cp docs/runbooks/*.md "$EV/runbooks/"
  echo "→ Copied runbooks"
fi

# Plan-mode plan
if [[ -f "$HOME/.claude/plans/refactored-growing-alpaca.md" ]]; then
  cp "$HOME/.claude/plans/refactored-growing-alpaca.md" \
     "$EV/transcripts/plan-mode-s5.md"
  echo "→ Copied S5 plan-mode transcript"
fi

# ---------------------------------------------------------------------------
# 3. Goldens — copy every PNG baseline
# ---------------------------------------------------------------------------

GOLDEN_COUNT=0
while IFS= read -r -d '' png; do
  rel="${png#$REPO_ROOT/}"
  dest="$EV/goldens/${rel#apps/mobile/test/}"
  mkdir -p "$(dirname "$dest")"
  cp "$png" "$dest"
  GOLDEN_COUNT=$((GOLDEN_COUNT + 1))
done < <(find apps/mobile/test -name "*.png" -path "*/goldens/*" -print0 2>/dev/null || true)
echo "→ Copied $GOLDEN_COUNT golden baseline(s)"

# ---------------------------------------------------------------------------
# 4. Coverage summary (if lcov.info exists)
# ---------------------------------------------------------------------------

if [[ -f "apps/mobile/coverage/lcov.info" ]]; then
  TOTAL_LINES=$(grep -c "^DA:" apps/mobile/coverage/lcov.info || echo 0)
  HIT_LINES=$(awk -F',' '/^DA:/ && $2 != 0' apps/mobile/coverage/lcov.info | wc -l)
  if [[ "$TOTAL_LINES" -gt 0 ]]; then
    PCT=$(awk "BEGIN { printf \"%.1f\", ${HIT_LINES} * 100 / ${TOTAL_LINES} }")
  else
    PCT="n/a"
  fi
  cat > "$EV/coverage/lcov-summary.txt" <<EOF
Coverage summary (${PCT}%)
  $HIT_LINES / $TOTAL_LINES lines covered

Source: apps/mobile/coverage/lcov.info
Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  echo "→ Captured coverage summary: ${PCT}%"
fi

# Domain coverage report — generated by the existing tool
if [[ -f "apps/mobile/tool/check_domain_coverage.dart" ]]; then
  echo "→ NOTE: run \`dart run apps/mobile/tool/check_domain_coverage.dart\` against a fresh \`flutter test --coverage\` and pipe the output to $EV/coverage/domain-coverage.txt before tagging v1.5"
fi

# ---------------------------------------------------------------------------
# 5. Repo link
# ---------------------------------------------------------------------------

if command -v git >/dev/null 2>&1; then
  REMOTE=$(git remote get-url origin 2>/dev/null || echo "<no remote>")
  TAG=$(git tag -l v1.5 | head -n1)
  cat > "$EV/repo-link.txt" <<EOF
Repository: $REMOTE
Release tag: ${TAG:-<v1.5 not yet tagged>}
HEAD: $(git rev-parse HEAD)
Branch: $(git rev-parse --abbrev-ref HEAD)

Captured: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
  echo "→ Captured repo-link.txt (tag: ${TAG:-not yet})"
fi

# ---------------------------------------------------------------------------
# 6. CI run captures (optional)
# ---------------------------------------------------------------------------

if [[ "$SKIP_CI" == "0" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "WARN: gh CLI not available; skipping CI run capture (use --skip-ci to silence)" >&2
  else
    # Capture the most recent run on main as the v1.5 reference. If
    # the v1.5 tag is annotated and has its own workflow run, prefer
    # that — but in the pre-tag dry-run main is the right anchor.
    LATEST_MAIN_RUN=$(gh run list --branch main --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || echo "")
    if [[ -n "$LATEST_MAIN_RUN" ]]; then
      gh run view "$LATEST_MAIN_RUN" --log > "$EV/ci-runs/main-latest.log" 2>/dev/null || \
        echo "WARN: gh run view failed for run $LATEST_MAIN_RUN"
      echo "→ Captured CI log for run $LATEST_MAIN_RUN"
    else
      echo "WARN: no CI runs found on main"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 7. Submission README + checklist
# ---------------------------------------------------------------------------

cat > "$OUT/README.md" <<'EOF'
# MoodBloom — May 30 Final Submission

This directory is auto-assembled by `tool/package_evidence.sh`. Do not
hand-edit; re-run the script.

## What's here

- `enterprise-audit-report.md` — the Enterprise Term Assignment R5
  audit + orchestration report. **Read this first.**
- `csc231-project-report.pdf` — CSC231 Project Report (placed by hand
  before the May 26 deadline)
- `csc234-uxui-report.pdf` — CSC234 UX/UI Report (placed by hand
  before the May 28 deadline)
- `slides/` — Sprint 5 demo slides + final presentation slides
- `evidence/` — supporting artifacts:
  - `repo-link.txt` — repo URL + v1.5 tag + HEAD commit
  - `adr/` — every ADR
  - `retros/` — sprint retros (S2-S5)
  - `runbooks/` — feature-flag rollback + DevOps follow-ups
  - `qa/` — Android matrix, Web matrix, a11y sweep, perf profile
  - `security/` — every security audit
  - `goldens/` — every golden PNG baseline
  - `coverage/` — lcov summary + domain coverage report
  - `crashlytics/` — Crashlytics dashboard screenshot (placed by hand)
  - `transcripts/` — handoff briefs + Plan Mode transcripts
  - `ci-runs/` — `gh run view` exports of the v1.5 CI runs

## Build instructions

```bash
# Build the submission directory in place:
tool/package_evidence.sh

# Build + zip:
tool/package_evidence.sh --zip

# Offline build (skip gh CLI calls):
tool/package_evidence.sh --skip-ci
```

## Pre-build checklist

1. `git tag v1.5` is pushed to origin
2. `flutter test --coverage` has run on the v1.5 head (so
   `apps/mobile/coverage/lcov.info` exists)
3. CSC231 + CSC234 reports are placed in this directory
4. Crashlytics dashboard screenshot is placed in
   `evidence/crashlytics/dashboard-2026-05-19.png`
5. Sprint 5 retro is finalised at `docs/retros/sprint-5-retro.md`
EOF
echo "→ Wrote README"

cat > "$OUT/submission-checklist.md" <<EOF
# Final submission checklist (May 30)

Tick each box once verified. Do not submit until every box is ticked.

## Code

- [ ] v1.5 tag pushed to origin (\`git tag -l v1.5\` non-empty)
- [ ] All Sprint 5 PRs merged into \`main\`
- [ ] CI green on \`main\` at the v1.5 commit (flutter + firestore-rules + functions jobs)

## Reports

- [ ] Enterprise Audit Report finalised (sections 1-8 all populated)
- [ ] CSC231 Project Report PDF placed at \`docs/submission/csc231-project-report.pdf\`
- [ ] CSC234 UX/UI Report PDF placed at \`docs/submission/csc234-uxui-report.pdf\`
- [ ] Sprint 5 retro finalised at \`docs/retros/sprint-5-retro.md\`

## Evidence

- [ ] Crashlytics dashboard screenshot at \`docs/submission/evidence/crashlytics/dashboard-2026-05-19.png\`
- [ ] Slides PDFs at \`docs/submission/slides/\`
- [ ] DevOps follow-ups runbook reflects post-deploy state

## Bundle

- [ ] \`tool/package_evidence.sh --zip\` runs cleanly
- [ ] \`docs/submission.zip\` exists and round-trips (unzip → contents intact)
- [ ] \`docs/submission/README.md\` is up-to-date

## Submission

- [ ] CSC231 Project Report submitted (May 26)
- [ ] CSC234 UX/UI Report submitted (May 28)
- [ ] Final evidence package submitted (May 30)

Generated by \`tool/package_evidence.sh\` on $(date -u +"%Y-%m-%dT%H:%M:%SZ").
EOF
echo "→ Wrote submission checklist"

# ---------------------------------------------------------------------------
# 8. Optional zip
# ---------------------------------------------------------------------------

if [[ "$WANT_ZIP" == "1" ]]; then
  if ! command -v zip >/dev/null 2>&1; then
    echo "ERROR: --zip requested but \`zip\` not found in PATH" >&2
    exit 1
  fi
  ZIP_PATH="$REPO_ROOT/docs/submission.zip"
  rm -f "$ZIP_PATH"
  (cd docs && zip -rq "$ZIP_PATH" submission)
  echo "→ Wrote $ZIP_PATH ($(du -h "$ZIP_PATH" | cut -f1))"
fi

echo "✓ Done. Bundle at $OUT"
