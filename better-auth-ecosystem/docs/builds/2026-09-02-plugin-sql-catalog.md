# Plugin SQL catalog Buildout

Created: 2026-09-02
Agent: Codex
Status: VERIFIED
Approved: Yes
Rounds: 1
Worktree: No
Type: Build

## Summary

**Goal:** Add a `plugin-sql/` catalog with one plainly named SQL file for every
Better Auth plugin whose schema exploration completed successfully.

**Oracle:** The catalog has exactly one file for each successful README plugin
section, excludes the blocked PayU attempt, and every schema-bearing file matches
the corresponding generated add migration.

**Misfire:** The folder could contain only plugins that generated DDL, making
successfully explored no-schema plugins look unresearched. Those plugins need
comment-only SQL files that record the intentional no-DDL result.

**Constraints:** Do not apply migrations or alter the database. Copy add SQL only,
not rollback SQL. Preserve existing migration and README files.

## Acceptance Criteria

- [x] Criterion 1: `plugin-sql/` contains one kebab-case `.sql` file for each
  successfully explored plugin in README and no file for the blocked PayU plugin.
- [x] Criterion 2: Every plugin that generated schema has SQL identical to its add
  migration after the catalog header comments.
- [x] Criterion 3: Every successfully explored no-schema plugin has a comment-only
  SQL file that states no additional DDL is required.
- [x] Criterion 4: All catalog files are valid text, pass whitespace checks, and
  no database command has been run.

## Progress Tracking

- [x] Task 1: Build the successful-plugin inventory and map schema plugins to add migrations.
- [x] Task 2: Create schema-bearing plugin SQL files from the generated add migrations.
- [x] Task 3: Create comment-only SQL files for successful no-schema plugins.
- [x] Task 4: Verify catalog coverage, source equivalence, naming, and formatting.

## Implementation Tasks

### Task 1: Build the inventory

**Objective:** Derive the successful plugin list and migration mapping from README
and the generated Drizzle files, excluding PayU because its package could not load.

### Task 2: Add schema SQL

**Objective:** Copy each plugin's generated add migration into its named catalog
file with a short source header.

### Task 3: Add no-schema SQL

**Objective:** Represent every successful no-schema exploration with an intentional
comment-only SQL file.

### Task 4: Verify the catalog

**Objective:** Compare file coverage with README, compare DDL bodies with source
migrations, and run formatting checks without touching the database.

## Round Log

- In progress: identified 37 successful explorations. Twenty-three generated add
  SQL and fourteen produced a confirmed no-schema result. PayU is excluded because
  its published package could not be loaded for generation.
- Created the 23 schema-bearing files from their add migrations and 14
  comment-only files for plugins whose completed generation cycle produced no DDL.
- Round 1: completed all four tasks. Judge: 4/4 pass. The catalog contains all
  37 successful plugins, excludes PayU, matches every source add migration, and
  clearly records every intentional no-schema result.

## Changed Files

- docs/builds/2026-09-02-plugin-sql-catalog.md
- plugin-sql/

## Not Verified

- SQL execution against PostgreSQL was not run because this catalog is generated
  schema reference material and the workflow must not change the database.
- Full test suite and lint were not run because the project defines neither a test
  script nor a lint script.
- Browser flows were not exercised because the new files are standalone SQL and
  are not loaded by the application.
- External review was unavailable; the catalog received a direct coverage and
  source-equivalence review instead.

## Verification Record

Profile: API, because the artifact contains executable PostgreSQL DDL even though
the application does not load it automatically.

- Catalog inventory comparison against the 37-plugin expected list — pass.
- Normalized body comparison for all 23 schema files against their source add
  migrations — pass.
- Comment-only and no-DDL checks for all 14 no-schema files — pass.
- Rollback guard, `! rg -q '^DROP\\b' plugin-sql` — pass.
- Trailing-whitespace scan across `plugin-sql/` and this Buildout — pass.
- `pnpm db:generate` — pass; final output: `No schema changes, nothing to migrate`.
- `pnpm exec tsc --noEmit` — pass.
- `pnpm build` — pass; the existing TanStack demo route reports only the
  `createServerFn().inputValidator()` deprecation warning.
- Regression review — pass; existing README, Drizzle migrations, auth schema, and
  plugin-free Better Auth configuration were not modified.
