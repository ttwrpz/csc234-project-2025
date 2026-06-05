# MoodBloom — Final Pitch · Speaker Script

**Release:** v1.6 · commit `0e55021a` · regenerated 2026-06-03 (24-slide edition — mapped 1:1 to the official 7-section outline; business + algorithm depth folded in)
**Total target:** ~13:55 (10–15 min window) + Q&A
**Cadence:** 150 wpm → 30s ≈ 75 words · 45s ≈ 112 words

> One block per slide; the deck's `\note{}` echoes each. `[DO:]` = on-screen action; `[FALLBACK:]` = recovery; `[pause]`/`[emphasize:]` sparingly. The orange **"Business:"** lines on the deck are deliberate — say them aloud for the committee's industry half. Every block ends with a hand-off transition.

**Speaker legend:** Orchestrator = Theerawat · Architect/Reviewer = Napat (design) / Kraiwich (technical) · QA/Release = Jedsarit (demo) / Teerin (QA + a11y).

---

## Slide 1 · Title · ~30s · Orchestrator

**On screen:** Title — MoodBloom, value prop, v1.6 · 0e55021a.
**Speaker:** Orchestrator (Theerawat) — **Time:** 30s (~75 words)

### Script (verbatim)

> "Good morning. We're Group 2, and this is MoodBloom. In one sentence: a compassionate, cross-platform mood-tracker that turns daily logging into the slow cultivation of a personal garden — engineered as a five-sprint, multi-agent AI orchestration.
>
> We'll make the case on three fronts: the [emphasize: business] opportunity, the therapeutic safety, and the engineering maturity behind it."

### Transition

"Let me introduce the team — and the slightly unusual way we organize."

---

## Slide 2 · The Team · ~30s · Orchestrator

**On screen:** Three role cards.
**Speaker:** Orchestrator (Theerawat) — **Time:** 30s (~75 words)

### Script (verbatim)

> "Five of us, three orchestration roles. I'm the Orchestrator — sprint planning and Plan Mode. Kraiwich and Napat are Architect-Reviewers — architecture, ADRs, PR review. Teerin and Jedsarit are QA and Release — tests, security, CI.
>
> We say [emphasize: orchestration] deliberately: our workflow is multi-agent, so each of us directs AI subagents in our scope."

### Transition

"To frame the problem and the business case, over to Napat, our UI/UX lead."

---

## Slide 3 · The Enterprise Challenge & Opportunity · ~45s · Architect/Reviewer (Napat)

**On screen:** Four challenge bullets + the market/opportunity line + orange "market gap" line.
**Speaker:** Napat — **Time:** 45s (~112 words)

### Script (verbatim)

> "The business reality first. A self-care app's value is entirely retention-bound — if the user uninstalls, the value is [emphasize: zero].
>
> And these apps bleed users fast: the majority lapse within about two weeks — Bakker and Rickard, 2018. The usual fix makes it worse — contingent-reward gamification is documented as counter-therapeutic, Cheng 2019. Incumbents punish you: wilting plants, lost streaks, clinical labels.
>
> And the prize is large: this is a six-to-seven-billion-dollar market growing toward twenty-billion-plus by 2030, where value equals retention equals lifetime value. So the retention fix is itself the harm — that's an open market gap."

### Transition

"Here's how we close it — three engineering decisions."

---

## Slide 4 · The Solution · ~35s · Architect/Reviewer (Napat)

**On screen:** Three differentiators.
**Speaker:** Napat — **Time:** 35s (~95 words)

### Script (verbatim)

> "First — plants never die. Garden health is a moving average; a single bad day moves it by at most fifteen-hundredths. No one day collapses the garden, and [emphasize: all five] tiers are alive — even Storm Season; the plants shelter.
>
> Second — five statistical algorithms feed a three-tier intervention; Kraiwich goes deep on those shortly.
>
> Third — and our QA lead proves this — Tier 3 is byte-for-byte deterministic. It is [emphasize: impossible] for the AI to run on our most vulnerable users."

### Transition

"So where does that put us against the field?"

---

## Slide 5 · Competitive Positioning & Business Model · ~40s · Architect/Reviewer (Napat)

**On screen:** 2×2 positioning map + business model + orange "monetize delight" line.
**Speaker:** Napat — **Time:** 40s (~105 words)

### Script (verbatim)

> "On this map — manual versus AI-assisted, punitive versus compassionate — Daylio and How We Feel are manual; Headspace and Finch lean on subscription and gamified streaks. The top-right corner — AI-assisted [emphasize: and] compassionate — is empty. That's us.
>
> The model is deliberate: today, cosmetic-only tokens — flower skins; therapeutic features are [emphasize: always] free. Next, optional cosmetic packs — no premium currency, no paywalled insights. Our channel is business-to-business-to-consumer through university counseling services, where our users already are.
>
> We monetize delight, never distress — which is why trust is the moat."

### Transition

"Two people we built this for."

---

## Slide 6 · Personas · ~25s · Architect/Reviewer (Napat)

**On screen:** Lin + Som cards; tagline.
**Speaker:** Napat — **Time:** 25s (~65 words)

### Script (verbatim)

> "Lin — a CS student with mild anxiety; goal, log in under thirty seconds; she churned from three naggy apps. Som — going through a sustained low; he wants to feel noticed, not labeled, because a wrong word does real harm.
>
> [pause] Lin tests engagement. Som tests safety. Every feature answers to one of them."

### Transition

"Let's see it running. Over to Jedsarit."

---

## Slide 7 · Demo Agenda · ~25s · QA/Release (Jedsarit)

**On screen:** Five-step agenda + fallback note.
**Speaker:** Jedsarit — **Time:** 25s (~62 words)

### Script (verbatim)

> "Five quick beats: cross-platform parity, authentication, offline-first, accessibility, and an intervention walkthrough. One promise up front — every step has a pre-recorded backup, so if anything stalls we cut to video and keep talking. And we will [emphasize: not] trigger an intervention live; that one's canned by design."

### Transition

"Same app, two platforms."

---

## Slide 8 · Cross-Platform · ~40s · QA/Release (Jedsarit)

**On screen:** Android + Web screenshots side by side + orange "one codebase" line.
**Speaker:** Jedsarit — **Time:** 40s (~105 words)

### Script (verbatim)

> "On the left, the release build on a physical Galaxy S23 — not an emulator. On the right, the exact same screen in Chrome, pixel-matched, from the release web build.
>
> [DO: log one mood live on the phone, then repeat on the Web window.]
>
> [FALLBACK if a device or build stalls: 'Here's that flow captured,' stay on these two images.]
>
> One Dart codebase — and the v1.6 redesign made it [emphasize: responsive] across phone, tablet, and desktop. From a business angle that's one team serving three form factors, two markets — no separate native builds."

### Transition

"Now the enterprise plumbing underneath."

---

## Slide 9 · Enterprise Features · ~50s · QA/Release (Jedsarit + Teerin)

**On screen:** 2×2 — auth, offline-first, a11y, atmosphere + orange retention line.
**Speaker:** Jedsarit (auth + offline), Teerin (a11y) — **Time:** 50s (~130 words)

### Script (verbatim)

> **Jedsarit:** "Authentication: Firebase Auth plus biometric, a PIN fallback, and a WebAuthn passkey on web — which [emphasize: shipped] in the v1.6 patch (still Sprint 5), not just a foundation anymore.
>
> Offline-first is the one to watch. [DO: airplane mode on, log a mood — the toast is instant because we wrote to the local database first.] [DO: network back on, watch Firestore populate within ~2 seconds.] [FALLBACK: play the offline video.] Business-wise, that's engagement surviving the subway — and engagement is retention.
>
> Accessibility — Teerin."
>
> **Teerin:** "[DO: bump system font to 200%.] [DO: dark mode for contrast.] [DO: TalkBack announces each chip's role, state, action.] [FALLBACK: the a11y video.] Larger addressable market, procurement-grade compliance."

### Transition

"The last beat is the one we canned on purpose."

---

## Slide 10 · Intervention Banner (canned) · ~35s · QA/Release (Jedsarit)

**On screen:** Banner + breathing-sheet stills.
**Speaker:** Jedsarit — **Time:** 35s (~88 words)

### Script (verbatim)

> "A pattern triggers, a banner slides up, you tap Open, you get a two-minute breathing sheet, and a cooldown timer shows in the debug overlay.
>
> [DO: play the embedded Tier-1 walkthrough video.]
>
> [FALLBACK: narrate over these two stills, left to right.]
>
> We canned it for a reason that's itself a feature: a live trigger needs fourteen days of data, and the global cooldown blocks repeats in one session. The guard won't let us demo it twice — exactly what you'd want."

### Transition

"That safety system is really an AI-orchestration story. Theerawat."

---

## Slide 11 · The Four Subagents · ~35s · Orchestrator (Theerawat)

**On screen:** 2×2 agent cards with "cannot" lines.
**Speaker:** Theerawat — **Time:** 35s (~95 words)

### Script (verbatim)

> "Four subagents, each with a tightly-scoped definition file. The architect designs briefs and writes ADRs — but never writes feature code. The flutter-engineer implements to brief — but never reviews or approves its own work. The QA engineer owns the tests and may never let domain coverage drop below eighty percent. The security reviewer is read-only — risk registers, [emphasize: not] patches.
>
> The invariant: the agent that writes the code is never the agent that approves it."

### Transition

"And it all starts in Plan Mode."

---

## Slide 12 · Plan Mode · ~35s · Orchestrator (Theerawat)

**On screen:** Verbatim Sprint-5 kickoff quote + two bullets.
**Speaker:** Theerawat — **Time:** 35s (~88 words)

### Script (verbatim)

> "Every kickoff opens in Plan Mode. Verbatim from Sprint 5: [pause] 'Enter Plan Mode. This is the highest-stakes sprint of the project — Tier 3 messages must be byte-for-byte deterministic. Read carefully.'
>
> The orchestrator plans, the humans approve, [emphasize: then] we dispatch. And we can prove the loop ran — six planning sessions are committed under docs-slash-evidence, one even marked 'approved via remote refinement.'"

### Transition

"Planning's only worth it if it catches things."

---

## Slide 13 · Human-in-the-Loop · ~40s · Orchestrator (Theerawat)

**On screen:** Three documented catches + orange "governed AI" line.
**Speaker:** Theerawat — **Time:** 40s (~105 words)

### Script (verbatim)

> "Three times a human caught what the AI missed — all documented, none shipped. One: an agent coded a statistical test to a tolerance an integer value physically can't reach; our architect caught it and amended the spec. Two: a security audit found account-deletion wiped the database but not the user's stored photos — we fixed and re-verified it. Three: a brief proposed merging two components 'for simplicity'; we rejected the coupling, and polish proved us right.
>
> That's the difference between governed AI and unmanaged AI — what an enterprise buyer diligences."

### Transition

"So what does a human actually hand an agent — and what did that buy us?"

---

## Slide 14 · Handoff Briefs + Orchestration ROI · ~45s · Orchestrator (Theerawat)

**On screen:** HB-007 structure (left) + "what the model bought us" ROI bullets (right) + orange "delivery model" line.
**Speaker:** Theerawat — **Time:** 45s (~112 words)

### Script (verbatim)

> "A handoff brief. Here's HB-007's real structure — goal, inputs, files, the state machine, cooldown rules, acceptance, open questions, non-goals. Three features shipped this way.
>
> And here's what the model bought us, commercially. Five sprints, five people: 157 commits, eleven-hundred-plus tests, fourteen ADRs. [emphasize: Velocity] — role-scoped agents plus briefs mean parallel delivery. [emphasize: Governance] — ADRs are an audit trail, hooks enforce the gates. [emphasize: Cost] — fewer people, reproducible builds.
>
> What surprised us most: when the brief was sharp, the code was right; when it was vague, even the best model drifted."

### Transition

"Let me hand the architecture to Kraiwich."

---

## Slide 15 · Clean Architecture · ~35s · Architect/Reviewer (Kraiwich)

**On screen:** TikZ three-layer diagram.
**Speaker:** Kraiwich — **Time:** 35s (~95 words)

### Script (verbatim)

> "Strict clean architecture, three layers, dependencies pointing [emphasize: inward] — presentation and data both depend on the domain; the domain depends on nothing but pure Dart.
>
> And this isn't a guideline. Domain purity is enforced by a commit hook: any domain file that imports Flutter or Firebase is [emphasize: rejected] at write time. That's why we can unit-test the entire ecosystem without booting a Flutter binding. Sprint 4 and 5 added nine pure-Dart engines — and the most important one is next."

### Transition

"This is the heart of the product — the pattern engine."

---

## Slide 16 · The Pattern Engine — Five Algorithms · ~40s · Architect/Reviewer (Kraiwich)

**On screen:** Five-algorithm table + Mann-Kendall formula + z_day≠Z_trend note + orange "on-device" line.
**Speaker:** Kraiwich — **Time:** 40s (~105 words)

### Script (verbatim)

> "Every entry computes a mood score, updates the moving average, then runs [emphasize: five] detectors — each tuned to a different failure mode. Mann-Kendall is a fourteen-day trend test — gradual worsening, Tier 1. Sliding five-of-seven catches sustained lows, Tier 2. Three-consecutive, the z-score, and CUSUM each catch a different acute drop, Tier 3.
>
> One subtlety worth flagging: the z-score and Mann-Kendall both use the letter Z, but they're different math — a single-day crash versus a fourteen-day trend. And all five run [emphasize: on-device], in pure Dart — no server, no inference cost."

### Transition

"Above that engine sits state and navigation."

---

## Slide 17 · State & Navigation · ~30s · Architect/Reviewer (Kraiwich)

**On screen:** Riverpod / GoRouter split.
**Speaker:** Kraiwich — **Time:** 30s (~80 words)

### Script (verbatim)

> "State is Riverpod with codegen — family providers per user, AsyncValue to unify loading, error, and data. Navigation is GoRouter with a stateful indexed-stack shell — five tabs — and three stacked guards: onboarding, auth, and a privacy lock. The privacy guard preserves the return route, so a locked deep link resumes [emphasize: exactly] where you intended after unlock."

### Transition

"And how that data is secured in the cloud."

---

## Slide 18 · Firestore · ~40s · Architect/Reviewer (Kraiwich)

**On screen:** Sub-tree + rule / design bullets + orange "blast radius" line.
**Speaker:** Kraiwich — **Time:** 40s (~105 words)

### Script (verbatim)

> "Everything lives under a per-user tree. Reading the rule: 'isOwner' is per-user access — you touch only your own subtree; createdAt is immutable; and diff-affectedKeys-hasOnly is a field-level allowlist — a client physically cannot smuggle an extra field past it.
>
> On modeling: we [emphasize: denormalize] the weekly garden into a rich snapshot, so reads stay single-document. And because access is per-user, single-collection, and time-ordered, Firestore's automatic indexes are enough — no composite-index burden. Per-user isolation means a breach's blast radius is one account. That's where an enterprise security review starts."

### Transition

"Which brings us to enterprise readiness — Teerin."

---

## Slide 19 · Four Quality Gates · ~35s · QA/Release (Teerin)

**On screen:** 2×2 gates (a11y/perf documented) + sources footnote + orange diligence line.
**Speaker:** Teerin — **Time:** 35s (~95 words)

### Script (verbatim)

> "Numbers, not adjectives. Correctness: one-thousand-forty-five Flutter tests and ninety-four Cloud Function tests pass — eleven-thirty-nine total. Domain coverage runs ninety-four to a hundred percent. Security: zero open high or critical.
>
> Accessibility is [emphasize: documented], not a gap — fifty-three a11y tests plus a WCAG double-A contrast sweep, light and dark; our Tier-3 affordances clear seven-to-one. Performance: a static review with zero high findings plus a device cold-start runbook. We name the two open optimizations — image caching and one dark-contrast token — rather than hide them."

### Transition

"But first, the single most important test we wrote."

---

## Slide 20 · Tier 3 Determinism · ~45s · QA/Release (Teerin)

**On screen:** TC-40 and TC-41 code blocks + orange "risk engineered out" line.
**Speaker:** Teerin — **Time:** 45s (~112 words)

### Script (verbatim)

> "On the left, TC-40: we dispatch a Tier 3 intervention, then assert ai-dot-calls is empty — Gemini was [emphasize: never] invoked — and that the message carries the 1323 hotline.
>
> On the right, TC-41: fifty-five adversarial strings into the Quote Safety Filter — clinical words, urgency words, malformed input. Expected pass-throughs: [pause] zero. We hit it.
>
> Underneath is a type-level fence: the AI method only accepts an enum of one and two. Tier three [emphasize: cannot] be passed — it won't compile. The single biggest legal and trust risk in a wellness product, engineered out at the type level."

### Transition

"Once it's sound, the question is whether it stays sound in production."

---

## Slide 21 · Observability · ~20s · QA/Release (Teerin)

**On screen:** No-log list / Remote Config flags.
**Speaker:** Teerin — **Time:** 20s (~52 words)

### Script (verbatim)

> "Observability is also a privacy posture. We capture crashes and structured events but [emphasize: never] mood text, email-uid pairs, or Gemini bodies — a hook even warns on a stray print. And three Remote Config flags let us change behavior without shipping a build."

### Transition

"Which is our rollback story."

---

## Slide 22 · Feature-Flag Rollback · ~20s · QA/Release (Teerin)

**On screen:** Three-row rollback table + red Tier-3 line.
**Speaker:** Teerin — **Time:** 20s (~52 words)

### Script (verbatim)

> "Three failure scenarios, three single-flag flips, each with a safe degradation. But read the red line: Tier 3 [emphasize: cannot] be rolled back by a flag — because it never used AI. The safest path is the one with the fewest moving parts. By design."

### Transition

"Theerawat closes us out."

---

## Slide 23 · Summary of Value · ~30s · Orchestrator (Theerawat)

**On screen:** Three claims + tagline.
**Speaker:** Theerawat — **Time:** 30s (~80 words)

### Script (verbatim)

> "Three takeaways. Business — a retention-first wedge into a roughly twenty-billion-dollar market; we monetize delight, never distress. Therapeutic safety — deterministic Tier 3, a disclaimer in five places, mood-agnostic rewards. And enterprise readiness — eleven-thirty-nine tests, type-level safety fences, per-user isolation, observable and rollback-capable.
>
> [pause] In short: a garden you can audit — and a business you can defend."

### Transition

"Two lessons, then we're yours."

---

## Slide 24 · Lessons & CTA · ~30s · Orchestrator (Theerawat)

**On screen:** Two lessons + v1.6 shipped / next + CTA.
**Speaker:** Theerawat — **Time:** 30s (~85 words)

### Script (verbatim)

> "Two lessons. On AI orchestration: the handoff brief is the unit of work — sharpen the brief, the implementation follows. On safety: when the user is most vulnerable, the code must be most [emphasize: boring] — Tier 3 has no AI by design. Our v1.6 patch — still Sprint 5 — shipped the responsive redesign and WebAuthn passkeys; next we're closing image-caching and the last contrast token.
>
> We're open for your technical audit and your questions. Thank you."

### Transition

"[Open Q&A — see qa-prep.md. Team can field in parallel by role.]"

---

## Timing summary (150 wpm)

| Section | Slides | Budget | Speaker(s) |
|---|---|---|---|
| 1. Title & Team | 1–2 | ~1:00 | Orchestrator |
| 2. Problem & Business Solution | 3–6 | ~2:25 | Architect/Reviewer (Napat) |
| 3. Live Demo | 7–10 | ~2:30 | QA/Release (Jedsarit + Teerin) |
| 4. Multi-Agent AI | 11–14 | ~2:35 | Orchestrator |
| 5. Architecture & Data | 15–18 | ~2:25 | Architect/Reviewer (Kraiwich) |
| 6. Reliability & Quality Gates | 19–22 | ~2:00 | QA/Release (Teerin) |
| 7. Conclusion | 23–24 | ~1:00 | Orchestrator |
| **Total** | **24** | **~13:55** | — |

**Compression to ~13:00 if the panel wants it short — in priority order:**
1. **Move Slide 16 (algorithms) to Appendix A4** and reference it only if a commentator asks (−40s). Cleanest cut: depth, not narrative.
2. Trim Slide 5's model bullets to one line (−15s); cut Slide 9's a11y beat to one sentence (−20s); Slide 21 to one sentence (−10s).

**Never** cut Slides 3, 4, 13, 14, or 20 — business thesis + technical differentiators the committee is there to probe. (Slide 16 is the exception: deep but appendix-able.)

**Business-narration reminder:** the orange "Business:" line on Slides 3, 5, 8, 9, 13, 14, 16, 18, 19, 20 is your cue to say the commercial "so-what" out loud — that's what keeps the industry half of the committee engaged through the technical middle.

---

## Appendix index (Q&A jump-targets — NOT spoken)

The deck carries 8 backup slides after Slide 24 (Beamer `\appendix`, separately numbered A1–A8). They are **not** part of the ~13:55 run — flip to one only when a commentator drills in. No verbatim script: you speak *to* the artifact reactively. The map:

| Slide | Title | Pull it up when asked… | Source |
|---|---|---|---|
| **A1** | EWMA worked example + tiers | "Why α=0.15?" / "How does one bad day affect the garden?" (Q13) | spec §2.3 |
| **A2** | Firestore `moods` rule, verbatim | "Show me the rules / the `diff()` pattern." (Q1) | `firestore.rules:55–69` |
| **A3** | Tier-3 type fence, full source | "Walk me through the enum." (Q2) | `ai_allowed_tier.dart` |
| **A4** | Pattern Engine — other four detectors | "Show the CUSUM / z-score math." (algorithm drill; companion to main Slide 16) | spec §2.4 |
| **A5** | Cooldown state machine + persistence | "How does the cooldown survive restart?" (Q15) | ADR-0008, `cooldown_guard.dart` |
| **A6** | Account deletion cascade | "How does deletion work? GDPR?" (Q11) | ADR-0009, `wipeUserData.ts` |
| **A7** | Disclaimer — 5 placements + copy | "Where's the medical disclaimer? HIPAA?" (Q12) | `disclaimer_copy.dart` |
| **A8** | Test pyramid & coverage | "What's your coverage?" / "1018 vs 1045?" (Q3, Q26) | `docs/evidence/platform-execution/` |

**How to navigate to an appendix slide live:** in most PDF viewers/Beamer, type the slide's absolute page number + `Enter`, or hyperlink from the divider. Decide your viewer's method during the pre-show drill. Returning: type the page number of the slide you left (note it on your printed script).
