# /reports/images/ — PNG status

## Auto-rendered (4 / 9)

The four architecture / concept diagrams have been rendered via `mermaid-cli`
and committed to this directory. Their `.mmd` sources live in `src/` so the
team can re-render or edit.

| Filename | Source | Used by |
|---|---|---|
| `conceptual.png` | `src/conceptual.mmd` (mirrors `docs/architecture/conceptual.md`) | `csc231-final.tex` §5; `audit-orchestration.tex` §6 |
| `implementation.png` | `src/implementation.mmd` (mirrors `docs/architecture/implementation.md`) | `csc231-final.tex` §5 |
| `tier3-fence.png` | `src/tier3-fence.mmd` (synthesised from ADR-0012) | `csc231-final.tex` §5; `csc234-final.tex` §8; `audit-orchestration.tex` §5 |
| `ecosystem-tiers.png` | `src/ecosystem-tiers.mmd` (synthesised from spec §2.2) | `csc234-final.tex` §3 |

Re-render with:
```bash
cd reports/images
npx -y -p @mermaid-js/mermaid-cli mmdc -i src/<file>.mmd -o <file>.png -t default -b white -w 1600
```

## Still required from human — 5 app screenshots

These require a running app with seeded demo data. Capture from `flutter run
-d chrome` (fastest) or the Android emulator.

| Target filename | What to capture | Used by |
|---|---|---|
| `garden-screen.png` | Garden screen, Thriving tier, calm atmosphere, with 7-day weekly chart visible | `csc234-final.tex` §6 |
| `log-mood-screen.png` | Log Mood screen with mood-type grid + intensity slider at 3 + text field | `csc234-final.tex` §6 |
| `insights-screen.png` | Insights screen showing the bipolar disclaimer ack dialog overlay (first view) | `csc234-final.tex` §6 |
| `tier3-banner.png` | Tier 3 dispatcher banner with curated phrase + Hotline 1323 footer (Settings → Debug → "Trigger Tier 3") | `csc234-final.tex` §6, §8 |
| `harvest-banner.png` | Weekly Harvest banner with "Your garden this week has been harvested..." copy (Settings → Debug → Force harvest) | `csc234-final.tex` §6 |

## How to export Mermaid `.md` blocks to PNG

**Option A — Mermaid CLI (recommended for reproducibility):**

```bash
npm install -g @mermaid-js/mermaid-cli
# Extract the mermaid block from docs/architecture/conceptual.md into conceptual.mmd
mmdc -i conceptual.mmd -o reports/images/conceptual.png -t neutral -b transparent -w 1600
mmdc -i implementation.mmd -o reports/images/implementation.png -t neutral -b transparent -w 1600
```

**Option B — VS Code Markdown Preview Mermaid extension:**

1. Open the source `.md` in VS Code.
2. Use the preview pane, right-click the rendered diagram, "Save Image As..." `conceptual.png`.

**Option C — Mermaid Live Editor** (https://mermaid.live):

1. Paste the mermaid block.
2. Actions → Download as PNG → save with the target filename.

## How to capture app screenshots

For the four screen captures (`garden-screen.png`, `log-mood-screen.png`,
`insights-screen.png`, `tier3-banner.png`, `harvest-banner.png`):

1. Run the app: `cd apps/mobile && flutter run -d chrome` (Web is fastest for screenshots).
2. Log in with a demo account that has at least 7 days of varied mood entries.
3. Navigate to each screen.
4. For `insights-screen.png` — log out and re-log in with a fresh account, then visit Insights for the first time so the ack dialog renders.
5. For `tier3-banner.png` — Settings → Debug → "Trigger Tier 3" tile. The dispatcher fires immediately; screenshot the banner.
6. Use the browser's built-in screenshot (Ctrl+Shift+S on Firefox; DevTools "Capture node screenshot" on Chrome).
7. Crop to a clean 9:16 portrait for screens and 16:9 landscape for banners.
8. Save as `reports/images/<filename>.png`.

## Verification before Overleaf compile

After exporting all 9 PNGs, verify the LaTeX files compile without
"file not found" warnings by running locally:

```bash
cd reports
pdflatex csc234-final.tex && biber csc234-final && pdflatex csc234-final.tex
pdflatex csc231-final.tex && biber csc231-final && pdflatex csc231-final.tex
```

If you only have Overleaf access, the `.tex` files use `\IfFileExists` guards
on every `\includegraphics`, so missing PNGs degrade gracefully to a
placeholder box rather than breaking the compile. The compile will succeed
with missing PNGs but the figures will be empty — the human reviewer will
notice.

## What is NOT included as a figure

- App screenshots of crash/error states — not relevant to either course.
- Sprint chart figures (burndown, velocity) — these would be useful in
  CSC231 §8 (Retrospectives) but the source data is not on disk. Skipped.
- Performance flame-graphs — pending the device-side perf profile run
  per `docs/test-reports/sprint-5-cross-platform-runbook.md`.
