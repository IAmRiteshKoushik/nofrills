# Orval React frontend Buildout

Created: 2026-09-12
Agent: Codex
Status: VERIFIED
Approved: Yes
Rounds: 1
Worktree: No
Type: Build

## Summary

**Goal:** Add a TypeScript and React TODO frontend in `orval-prototype` that uses TanStack Router, TanStack Query, Axios, and Orval, without TanStack Start.

**Oracle:** A browser walkthrough creates a TODO, marks it complete, and deletes it through the generated query hooks against the Go API.

**Misfire:** The screen could look functional while hand-written API types or requests bypass Orval. Criterion 2 catches that.

**Constraints:** Keep every project file under `orval-prototype`; use `pnpm` for Node tooling; do not add authentication or TanStack Start.

## Acceptance Criteria

- [x] Criterion 1: The running frontend lets a user create, complete, and delete a TODO, with each state change visible after the API response in a browser walkthrough.
- [x] Criterion 2: `pnpm generate` creates the client in `src/api/generated`, and the hand-written frontend imports its TODO operations and types only from that generated output.
- [x] Criterion 3: The application uses TanStack Router for its route tree and TanStack Query for server state, verified by source inspection and a clean TypeScript production build.
- [x] Criterion 4: The generated client uses Axios with the local Go API base URL, verified from `orval.config.ts` and a successful API-backed walkthrough.

## Out of Scope

- Authentication, persistent storage, and TanStack Start.

## Progress Tracking

- [x] Task 1: Create the Vite React project and package scripts.
- [x] Task 2: Configure Orval and generate the Axios and TanStack Query client.
- [x] Task 3: Build the TODO route and UI around generated hooks.
- [x] Task 4: Verify the generated client, production build, and browser flow.

## Implementation Tasks

### Task 1: Create the frontend foundation

**Objective:** Add the TypeScript React application, Vite configuration, and `pnpm` commands under `orval-prototype` without affecting other prototypes.

### Task 2: Configure generated API access

**Objective:** Make Orval consume the existing OpenAPI document and generate Axios functions plus TanStack Query hooks in a clearly owned generated directory.

### Task 3: Build the TODO interface

**Objective:** Implement a route that lists, creates, updates, and deletes TODOs using only the generated API layer for server interactions.

### Task 4: Run the application and inspect the result

**Objective:** Build, type-check, run the Go API and Vite app, then exercise the visible CRUD flow in a browser.

## Round Log

### Round 1

All tasks completed. The browser flow at `http://localhost:5173` began with an empty list, created `Verify Orval end to end`, marked it complete, then deleted it. The screen returned to the empty state. At a 390px viewport, the form rendered in one column without clipped controls.

## Changed Files

- `orval-prototype/.gitignore`
- `orval-prototype/README.md`
- `orval-prototype/go.mod`
- `orval-prototype/index.html`
- `orval-prototype/main.go`
- `orval-prototype/main_test.go`
- `orval-prototype/orval.config.ts`
- `orval-prototype/package.json`
- `orval-prototype/pnpm-lock.yaml`
- `orval-prototype/pnpm-workspace.yaml`
- `orval-prototype/src/api/axios-instance.ts`
- `orval-prototype/src/api/generated/`
- `orval-prototype/src/main.tsx`
- `orval-prototype/src/router.tsx`
- `orval-prototype/src/routes/todos.tsx`
- `orval-prototype/src/styles.css`
- `orval-prototype/tsconfig.app.json`
- `orval-prototype/tsconfig.json`
- `orval-prototype/tsconfig.node.json`
- `orval-prototype/vite.config.ts`

## Not Verified

- No separate frontend unit-test suite exists in this small prototype. Browser CRUD exercised the generated hooks against the live API instead.
- The Axios base URL intentionally targets the local two-process demo. A deployed static build needs an environment-specific API URL or a reverse proxy.

## Verification Record

- Profile: Full
- Live target: T3 collaborative browser at `http://localhost:5173`, with Go API at `http://localhost:8080`.
- Commands:
  - `PATH=/usr/local/go/bin:$PATH go test ./...` - pass
  - `pnpm generate` - pass
  - `pnpm check` - pass
  - `pnpm build` - pass
  - `pnpm audit --prod` - pass, no known vulnerabilities after upgrading Axios to 1.20.0
  - `pnpm --package=@redocly/cli@latest dlx redocly lint openapi.yaml` - pass with three expected local-demo warnings
  - `curl -fsS http://localhost:8080/health` - pass
  - `git diff --check -- .` - pass
- Browser: desktop and 390px mobile snapshots passed; desktop CRUD created, updated, and deleted one TODO.
- Review: independent source review found an Axios 1.13.2 vulnerability. Upgraded to Axios 1.20.0, then reran generation, type-checking, build, audit, and a browser create flow. The remaining local-demo limits are disclosed above.
- Docs: `orval-prototype/README.md` updated.
- Regression: all listed commands rerun after the final edits.
