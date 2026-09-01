# TanStack Better Auth Buildout

Created: 2026-09-01
Agent: Codex
Status: VERIFIED
Approved: Yes
Rounds: 1
Worktree: No
Type: Build

## Summary

**Goal:** Create a TanStack Start application through the TanStack CLI with Drizzle and Better Auth configured.

**Oracle:** The application builds successfully with a real Better Auth server instance using the shared Drizzle database and an `/api/auth/$` handler.

**Misfire:** A project could compile while Better Auth ignores Drizzle or has no reachable handler. The build and a focused configuration check rule this out.

**Constraints:** Use pnpm. Do not configure Better Auth plugins. Existing parent-directory changes remain untouched.

**Assumed:** “bedrock” means Better Auth, based on the requested follow-up and the documented Drizzle integration.

## Acceptance Criteria

- [x] Criterion 1: The TanStack CLI-generated project is present and `pnpm build` succeeds.
- [x] Criterion 2: Drizzle defines a PostgreSQL client, schema, config, and migration workflow using `DATABASE_URL`.
- [x] Criterion 3: Better Auth uses the shared Drizzle database with the PostgreSQL adapter and an empty plugin list, and the TanStack Start auth route forwards GET and POST requests to it.

## Out of Scope

- Authentication providers and Better Auth plugins
- Provisioning a PostgreSQL database or applying migrations

## Progress Tracking

- [x] Task 1: Generate the TanStack Start project with the Drizzle add-on.
- [x] Task 2: Configure the database environment, schema, and migrations.
- [x] Task 3: Add Better Auth with the Drizzle adapter and TanStack Start handler.
- [x] Task 4: Verify the generated project and configuration.

## Implementation Tasks

### Task 1: Generate the application

**Objective:** Use the TanStack CLI to replace the empty npm placeholder with a runnable TanStack Start project and its Drizzle integration.

### Task 2: Configure Drizzle

**Objective:** Ensure the generated database setup uses a PostgreSQL connection string, has an explicit schema entry point, and exposes migration commands.

### Task 3: Configure Better Auth

**Objective:** Add Better Auth's Drizzle adapter and mount its request handler without Better Auth plugins.

### Task 4: Verify the setup

**Objective:** Run the available type, lint, and production build checks and inspect the final integration points.

## Round Log

- Round 1: All tasks completed. The TanStack CLI generated the Start application and Drizzle integration. Better Auth generated its Drizzle schema, uses the shared PostgreSQL client with `plugins: []`, and handles `/api/auth/$`. All criteria passed on the commands and live request below.

## Changed Files

- docs/builds/2026-09-01-tanstack-better-auth.md
- .cta.json
- .env.example
- .gitignore
- .vscode/
- README.md
- drizzle.config.ts
- drizzle/0000_organic_leopardon.sql
- drizzle/meta/0000_snapshot.json
- drizzle/meta/_journal.json
- package.json
- pnpm-lock.yaml
- pnpm-workspace.yaml
- public/drizzle.svg
- src/components/
- src/db/auth-schema.ts
- src/db/index.ts
- src/db/schema.ts
- src/lib/auth-client.ts
- src/lib/auth.ts
- src/routes/
- src/styles.css
- tsconfig.json
- tsr.config.json
- vite.config.ts

## Not Verified

- No PostgreSQL instance was supplied, so `pnpm db:migrate` and an email/password sign-up were not run.
- No lint or test script exists in the generated project.
- The CLI-generated Drizzle demo still emits a deprecation warning for `inputValidator`; it is outside this authentication setup.

## Verification Record

- Profile: Full
- Live target: `pnpm dev`, then `GET /` returned 200 and `GET /api/auth/not-a-better-auth-endpoint` returned Better Auth's 404 without a base URL warning.
- Commands:
  - `pnpm auth:generate` — pass
  - `pnpm db:generate` — pass, then no schema changes on the repeat run
  - `pnpm exec tsc --noEmit` — pass
  - `pnpm build` — pass
  - `git -C /home/rk/dev/nofrills diff --check -- better-auth-ecosystem` — pass
- Review: manual integration review completed. The shared Drizzle client includes the generated auth schema, and `src/lib/auth.ts` passes that schema to the PostgreSQL adapter with an empty plugin list.
- Docs: README.md updated with local environment, schema-generation, migration, handler, and client instructions.
- Regression: `pnpm auth:generate`, `pnpm db:generate`, type checking, and production build passed after the final configuration edits.
