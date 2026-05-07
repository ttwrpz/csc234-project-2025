#!/usr/bin/env bash
#
# package_evidence.sh — bundle the v1.5 evidence package for May-30 submission.
#
# Sprint 5 plan §10 + Audit Report §8.10. Produces a self-contained
# `docs/submission/` tree the graders read first, with every
# orchestration artifact a CSC231/CSC234 review can cite back to.
#
# Usage:
#   tool/package_evidence.sh                # full bundle
#   tool/package_evidence.sh --dry-run      # plan only, no writes
#   tool/package_evidence.sh --no-ci        # skip gh run view fetches
#                                           # (offline / no GH_TOKEN)
#
# Pre-requisites:
#   - Working tree at the v1.5 tag (or whichever tag you're packaging).
#   - `gh` CLI authenticated (skip via --no-ci if not).
#   - The course-report PDFs already in place at the canonical paths
#     listed below (May 26 + May 28 deadlines feed those in).
#
# Output:
#   docs/submission/<tree per Sprint 5 plan §10>
#   docs/submission/moodbloom-evidence-<tag>.zip  (top-level archive)
#
# Exit codes:
#   0   success
#   2   missing required artifact (e.g. enterprise-audit-report.md)
#   3   gh CLI not authenticated and --no-ci not passed
#   4   dirty working tree (refuse to package; commit first)

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMISSION_DIR="${REPO_ROOT}/docs/submission"
EVIDENCE_DIR="${SUBMISSION_DIR}/evidence"

DRY_RUN=0
SKIP_CI=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --no-ci) SKIP_CI=1; shift ;;
    -h|--help)
      sed -n '2,30p' "${BASH_SOURCE[0]}"
      exit 0 ;;
    *)
      echo "unknown flag: $1" >&2
      exit 1 ;;
  esac
done

log() { printf '[evidence] %s\n' "$*"; }
do_or_dry() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run]  %s\n' "$*"
  else
    eval "$*"
  fi
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------

log "Repo root: ${REPO_ROOT}"
cd "${REPO_ROOT}"

# Refuse to package a dirty tree — the audit-report's "this is what we
# shipped" claim is meaningless if there are uncommitted changes.
if [[ -n "$(git status --porcelain)" ]]; then
  echo "[evidence] error: working tree is dirty. Commit or stash before packaging." >&2
  exit 4
fi

GIT_TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo 'untagged')"
GIT_SHA="$(git rev-parse --short HEAD)"
log "Packaging at ${GIT_TAG} (${GIT_SHA})"

# Required artifacts — fail fast if any are missing.
declare -a REQUIRED=(
  "docs/audit/enterprise-audit-report.md"
  "docs/runbooks/feature-flag-rollback.md"
  "docs/runbooks/devops-followups.md"
  "CLAUDE.md"
  ".github/PULL_REQUEST_TEMPLATE.md"
)
for artifact in "${REQUIRED[@]}"; do
  if [[ ! -f "${REPO_ROOT}/${artifact}" ]]; then
    echo "[evidence] error: required artifact missing: ${artifact}" >&2
    exit 2
  fi
done

# gh CLI gate (unless --no-ci).
if [[ "$SKIP_CI" -eq 0 ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "[evidence] error: gh CLI not on PATH. Install or pass --no-ci." >&2
    exit 3
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "[evidence] error: gh not authenticated. Run 'gh auth login' or pass --no-ci." >&2
    exit 3
  fi
fi

# ---------------------------------------------------------------------------
# Tree skeleton
# ---------------------------------------------------------------------------

log "Building submission tree at docs/submission/"
do_or_dry "rm -rf '${SUBMISSION_DIR}'"
do_or_dry "mkdir -p '${SUBMISSION_DIR}/slides'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/ci-runs'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/coverage'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/crashlytics'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/goldens'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/qa'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/security'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/transcripts/handoff-briefs'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/adrs'"
do_or_dry "mkdir -p '${EVIDENCE_DIR}/retros'"

# ---------------------------------------------------------------------------
# Copy docs (markdown is universal; PDFs are the publish step the
# course-report authors handle separately on May 26 / May 28).
# ---------------------------------------------------------------------------

log "Copying audit + runbooks + retros + briefs..."
do_or_dry "cp '${REPO_ROOT}/docs/audit/enterprise-audit-report.md' '${SUBMISSION_DIR}/'"
do_or_dry "cp '${REPO_ROOT}/docs/runbooks/feature-flag-rollback.md' '${EVIDENCE_DIR}/'"
do_or_dry "cp '${REPO_ROOT}/docs/runbooks/devops-followups.md' '${EVIDENCE_DIR}/'"

# Architecture + ADRs.
if [[ -d "${REPO_ROOT}/docs/architecture" ]]; then
  do_or_dry "cp -r '${REPO_ROOT}/docs/architecture' '${EVIDENCE_DIR}/'"
fi
if [[ -d "${REPO_ROOT}/docs/adr" ]]; then
  do_or_dry "cp '${REPO_ROOT}/docs/adr/'*.md '${EVIDENCE_DIR}/adrs/'"
fi

# Sprint retros.
if [[ -d "${REPO_ROOT}/docs/retros" ]]; then
  do_or_dry "cp '${REPO_ROOT}/docs/retros/'*.md '${EVIDENCE_DIR}/retros/'"
fi

# Handoff briefs.
if [[ -d "${REPO_ROOT}/.claude/briefs" ]]; then
  do_or_dry "cp -r '${REPO_ROOT}/.claude/briefs/'* '${EVIDENCE_DIR}/transcripts/handoff-briefs/'"
fi

# Security audits.
if [[ -d "${REPO_ROOT}/docs/security" ]]; then
  do_or_dry "cp '${REPO_ROOT}/docs/security/'*.md '${EVIDENCE_DIR}/security/'"
fi

# QA matrices (Day 3-4 deliverables; copy whichever exist at package time).
if [[ -d "${REPO_ROOT}/docs/qa" ]]; then
  do_or_dry "cp '${REPO_ROOT}/docs/qa/'*.md '${EVIDENCE_DIR}/qa/' 2>/dev/null || true"
fi

# Test reports (Sprint 3 + any v1.5 supplement).
if [[ -d "${REPO_ROOT}/docs/test-reports" ]]; then
  do_or_dry "cp '${REPO_ROOT}/docs/test-reports/'*.md '${EVIDENCE_DIR}/qa/' 2>/dev/null || true"
fi

# CLAUDE.md and PR template — proof of the orchestration conventions.
do_or_dry "cp '${REPO_ROOT}/CLAUDE.md' '${EVIDENCE_DIR}/transcripts/'"
do_or_dry "cp '${REPO_ROOT}/.github/PULL_REQUEST_TEMPLATE.md' '${EVIDENCE_DIR}/transcripts/'"

# Plan files — anchor for the §7 worked-handoff-example narrative.
if [[ -d "${REPO_ROOT}/.claude/plans" ]]; then
  do_or_dry "cp '${REPO_ROOT}/.claude/plans/'*.md '${EVIDENCE_DIR}/transcripts/' 2>/dev/null || true"
fi

# ---------------------------------------------------------------------------
# Goldens — copy every PNG baseline so the visual contract is reviewable
# without checking out the repo.
# ---------------------------------------------------------------------------

log "Copying golden baselines..."
if [[ "$DRY_RUN" -eq 0 ]]; then
  find "${REPO_ROOT}/apps/mobile/test" -name '*.png' -type f \
    -exec cp --parents -t "${EVIDENCE_DIR}/goldens/" {} + 2>/dev/null || true
else
  printf '[dry-run]  find apps/mobile/test/**/*.png → goldens/\n'
fi

# ---------------------------------------------------------------------------
# CI run captures (skip on --no-ci).
# ---------------------------------------------------------------------------

if [[ "$SKIP_CI" -eq 0 ]]; then
  log "Fetching latest CI run for ${GIT_SHA}..."
  RUN_ID="$(gh run list --commit "${GIT_SHA}" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || echo '')"
  if [[ -n "${RUN_ID}" ]]; then
    log "  CI run: ${RUN_ID}"
    do_or_dry "gh run view ${RUN_ID} --log > '${EVIDENCE_DIR}/ci-runs/run-${RUN_ID}.log' 2>/dev/null || echo 'gh run view failed; CI evidence partial'"
  else
    log "  (no CI run found for this commit; the v1.5 tag may pre-date or post-date the latest run)"
  fi
else
  log "Skipping CI fetch (--no-ci)"
  printf '[evidence] note: populate evidence/ci-runs/ manually before submission.\n'
fi

# ---------------------------------------------------------------------------
# Coverage placeholder (Day 4 deliverable runs the actual coverage tool;
# this script just bundles whatever is on disk at package time).
# ---------------------------------------------------------------------------

if [[ -f "${REPO_ROOT}/apps/mobile/coverage/lcov.info" ]]; then
  log "Bundling coverage/lcov.info"
  do_or_dry "cp '${REPO_ROOT}/apps/mobile/coverage/lcov.info' '${EVIDENCE_DIR}/coverage/'"
fi

# ---------------------------------------------------------------------------
# Repo link + manifest
# ---------------------------------------------------------------------------

log "Writing repo-link.txt + MANIFEST..."
REPO_URL="$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' || echo 'unknown')"

cat <<EOF | (if [[ "$DRY_RUN" -eq 1 ]]; then sed 's/^/[dry-run]  /'; else cat > "${EVIDENCE_DIR}/repo-link.txt"; fi)
${REPO_URL}/tree/${GIT_TAG}

# Tag: ${GIT_TAG}
# Commit: ${GIT_SHA}
# Packaged: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

cat <<'README_EOF' | (if [[ "$DRY_RUN" -eq 1 ]]; then sed 's/^/[dry-run]  /'; else cat > "${SUBMISSION_DIR}/README.md"; fi)
# MoodBloom — submission package

Read order for graders:

1. **`enterprise-audit-report.md`** — the canonical narrative. §1 Executive
   summary; §2 Stack + architecture; §3 Security posture; §4 Quality
   gates; §5 Multi-agent orchestration workflow; §6 Agent challenges;
   §7 Worked handoff example (HB-003 §5.5b); §8 Evidence inventory.
2. **`csc231-project-report.pdf`** — CSC231 deliverable (due 2026-05-26).
3. **`csc234-uxui-report.pdf`** — CSC234 deliverable (due 2026-05-28).
4. **`slides/`** — Sprint 5 demo slides + final-presentation deck.
5. **`evidence/`** — every artifact the audit report cites:
    - `ci-runs/` — `gh run view <id> --log` exports for the release tag
    - `coverage/` — lcov + domain-coverage report
    - `crashlytics/` — dashboard screenshot
    - `goldens/` — every PNG baseline under `apps/mobile/test/**/goldens/`
    - `qa/` — Android matrix + Web matrix + a11y sweep + perf profile
    - `security/` — security audit reports (S2/S3 + v1.0 + v1.5)
    - `transcripts/` — Plan Mode + handoff briefs + CLAUDE.md +
      PR template (the orchestration-convention surface)
    - `adrs/` — every ADR (0001, 0003-0009)
    - `retros/` — sprint retros (S2 / S3 / S4 / S5)
    - `architecture/` — conceptual + implementation diagrams
    - `runbooks/` — feature-flag rollback + DevOps follow-ups
    - `repo-link.txt` — pointer to the tagged commit on GitHub

The repository link in `evidence/repo-link.txt` is the authoritative
source-of-truth for everything in this bundle. If a file in
`evidence/` and the repo disagree, the repo wins.
README_EOF

# ---------------------------------------------------------------------------
# Submission checklist
# ---------------------------------------------------------------------------

cat <<'CHECKLIST_EOF' | (if [[ "$DRY_RUN" -eq 1 ]]; then sed 's/^/[dry-run]  /'; else cat > "${SUBMISSION_DIR}/submission-checklist.md"; fi)
# Submission checklist

Fill out before zipping the bundle.

## Required (hard fail without these)

- [ ] `enterprise-audit-report.md` present + all 8 sections populated
- [ ] `csc231-project-report.pdf` present (May 26 deadline)
- [ ] `csc234-uxui-report.pdf` present (May 28 deadline)
- [ ] `evidence/repo-link.txt` points at the v1.5 tagged commit
- [ ] `evidence/security/audit-2026-05-19-v1.5.md` present + signed off
- [ ] `evidence/qa/android-matrix-*.md` present
- [ ] `evidence/qa/web-matrix-*.md` present
- [ ] `evidence/qa/a11y-sweep-*.md` present
- [ ] `evidence/qa/perf-*.md` present
- [ ] `evidence/coverage/lcov.info` present + ≥ 80% domain
- [ ] `evidence/crashlytics/dashboard-*.png` present
- [ ] `evidence/ci-runs/run-*.log` present for the release-tag commit
- [ ] `evidence/goldens/` non-empty (baseline file count ≥ 9 per S5 plan §3a.2)

## Recommended (strengthens the narrative; not blocking)

- [ ] `slides/sprint-5-demo-slides.pdf`
- [ ] `slides/final-presentation.pdf`
- [ ] `evidence/transcripts/plan-mode-s{2,3,4,5}.md`
- [ ] `evidence/transcripts/handoff-briefs/sprint-{2,3,4,5}/*.md`
- [ ] `evidence/adrs/0001*.md` and `0003-0009*.md` all present
- [ ] `evidence/retros/sprint-{2,3,4,5}-retro.md` all present

## Sign-off

- [ ] Theerawat (lead) reviewed end-to-end
- [ ] Kraiwich + Napat + Teerin + Jedsarit reviewed their sections
- [ ] Final zip produced via `tool/package_evidence.sh`
- [ ] Submitted to grading portal: ____________________
- [ ] Date: ____________________
CHECKLIST_EOF

# ---------------------------------------------------------------------------
# Zip
# ---------------------------------------------------------------------------

ZIP_NAME="moodbloom-evidence-${GIT_TAG}.zip"
log "Zipping → ${SUBMISSION_DIR}/${ZIP_NAME}"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '[dry-run]  (cd docs && zip -qr submission/%s submission)\n' "${ZIP_NAME}"
else
  (cd "${REPO_ROOT}/docs" && zip -qr "submission/${ZIP_NAME}" "submission" -x "submission/${ZIP_NAME}")
  log "Wrote $(du -h "${SUBMISSION_DIR}/${ZIP_NAME}" | awk '{print $1}') zip"
fi

log "Done. Review docs/submission/ then run the submission-checklist."
