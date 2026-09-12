# Browser avatar ring

Type: Build
Status: VERIFIED
Approved: Yes
Rounds: 1
Worktree: No

## Summary

Goal: A small dependency-free HTML/JS prototype that extracts three colors from the supplied GitHub avatar in the browser and renders a gradient ring.
Oracle: The live page loads the supplied remote image and displays computed swatches matching its CSS gradient.
Misfire: Hardcoded colors could look convincing; changing to a local test image must change the palette.
Constraints: All prototype files stay under avatar-ring. Preserve the original brainstorming PLAN.md.
Assumed: Centered circular crop, static gradient, local uploads as an additional comparison control. No design reference.

## Acceptance Criteria

- [x] Criterion 1: The supplied GitHub image loads and produces three hexadecimal swatches used by the rendered gradient, verified in a browser.
- [x] Criterion 2: A local image changes the palette through client-side computation without an upload request.
- [x] Criterion 3: A failed image load produces a readable error and allows recovery.
- [x] Criterion 4: The page fits desktop and 390px mobile viewports without horizontal overflow.

## Progress Tracking

- [x] Task 1: Create the avatar preview and controls.
- [x] Task 2: Implement image loading, palette extraction, and gradient rendering.
- [x] Task 3: Verify browser behavior and document how to run it.

## Implementation Tasks

### Task 1: Create the preview

Objective: Display the avatar, extracted swatches, and controls in a responsive page.

### Task 2: Extract colors locally

Objective: Sample a centered circular crop, cluster colors, and apply the resulting palette with loading and error handling.

### Task 3: Verify and document

Objective: Exercise the live image, local replacement, errors, and mobile layout; provide a simple run command.

## Round Log

Round 1: All tasks and criteria passed. The task list and criteria did not change. Pilot tooling is absent; tracking and review were local.

- Criterion 1: Live Chromium loaded the supplied GitHub avatar. Computed swatches were #080808, #B4B4B4, #505050, matching the computed conic-gradient style. Extraction sampled 3,228 pixels and took 51.6 ms in this run, excluding network and decoding.
- Criterion 2: A local solid-red fixture produced three #FF0000 stops, with no HTTP requests during file selection. This catches the hardcoded-palette misfire.
- Criterion 3: Transparent, invalid, and failed remote images produced readable errors. Reset recovered the original palette after invalid input.
- Criterion 4: Desktop at 1200 × 1000 and mobile at 390 × 844 were visually inspected. Mobile had no horizontal overflow.

## Verification Record

- Live target: local static server, `python3 -m http.server 8080 --bind 127.0.0.1 --directory avatar-ring` from the workspace root.
- Runtime and user paths: temporary Playwright harness at `/tmp/avatar-ring-check/check.cjs`, run with `node /tmp/avatar-ring-check/check.cjs`, passed the criteria plus theme switching and ring-width changes. No uncaught page exceptions.
- Visual evidence: `/tmp/avatar-ring-check/desktop.png` and `/tmp/avatar-ring-check/mobile.png`, both inspected.
- Static check: `node --check avatar-ring/app.js` passed; whitespace check passed for all four implementation/documentation files.
- Code review: separate reviewer found no blocking issue. Optional limitation: a local blob URL is revoked after extraction, so opening the preview image separately is not supported reliably. Display remains intact.
- Documentation: README includes launch instructions, algorithm, CORS requirements, timing scope, and browser-only behavior. Original PLAN.md preserved.
- Regression: invalid-file recovery restored the original computed palette; no pre-existing executable implementation was changed.

## Not Verified

- Firefox, Safari, and physical mobile devices were not tested.
- No production deployment was performed.
- No standalone type checker, lint suite, or build command was run; the artifact is plain JavaScript/CSS/HTML with no configured toolchain.
- No pre-existing automated test suite existed; browser checks used a temporary harness outside the repository.
- Pilot-managed pre-build criteria review was unavailable. Criteria were reviewed locally before implementation.

## Changed Files

- index.html
- styles.css
- app.js
- README.md
- docs/builds/2026-09-12-browser-avatar-ring.md
