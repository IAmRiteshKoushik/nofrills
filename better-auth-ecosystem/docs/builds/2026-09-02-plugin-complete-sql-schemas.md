# Complete plugin SQL schemas Buildout

Created: 2026-09-02
Agent: Codex
Status: VERIFIED
Approved: Yes
Rounds: 2
Worktree: No
Type: Build

## Summary

**Goal:** Rewrite every `plugin-sql/<plugin>.sql` file as a complete standalone
PostgreSQL schema containing the Better Auth base schema plus that plugin's schema.

**Oracle:** Each file reconstructs the Better Auth portion of its corresponding
Drizzle snapshot using only `CREATE` statements, with all authentication columns,
defaults, keys, constraints, and indexes present and no `ALTER` statement anywhere
in `plugin-sql/`.

**Misfire:** Concatenating the base and add migrations would leave `ALTER TABLE`
statements and could duplicate tables. The catalog must render the final snapshot
state directly, with foreign keys embedded in dependency-ordered table definitions.

**Constraints:** Overwrite the existing plugin SQL files. Do not modify Drizzle
migrations or snapshots, run migrations, or write to the database. No-schema
plugins receive the complete Better Auth base schema. Application tables such as
the TanStack demo's `todos` table are excluded.

## Acceptance Criteria

- [x] Criterion 1: All 37 plugin files contain a complete Better Auth schema, with
  no-schema plugins equal to the authentication part of the base snapshot and schema
  plugins equal to the authentication part of their add snapshot.
- [x] Criterion 2: Every Better Auth snapshot table, column, default, primary key,
  unique constraint, foreign key, and index is represented in the corresponding SQL
  file, while the application-only `todos` table is absent.
- [x] Criterion 3: No file under `plugin-sql/` contains an `ALTER` or `DROP`
  statement, and referenced tables appear before tables that declare foreign keys.
- [x] Criterion 4: Existing Drizzle migrations, snapshots, README, and application
  schema remain unchanged, and no database command is run.

## Progress Tracking

- [x] Task 1: Map all plugin files to their complete Drizzle snapshots.
- [x] Task 2: Render dependency-ordered complete PostgreSQL schemas with inline constraints.
- [x] Task 3: Overwrite all plugin SQL files and verify snapshot equivalence.
- [x] Task 4: Run project and formatting regression checks without applying SQL.
- [x] Task 5: Remove the application-only `todos` table and reverify every schema.

## Implementation Tasks

### Task 1: Map snapshots

**Objective:** Use the add-migration snapshot for each schema plugin and the base
snapshot for every successful no-schema plugin.

### Task 2: Render complete schemas

**Objective:** Render tables in foreign-key dependency order, placing foreign and
unique constraints inside `CREATE TABLE` and rendering indexes after all tables.

### Task 3: Rewrite and compare

**Objective:** Replace each existing SQL file and compare the parsed SQL inventory
against its source snapshot.

### Task 4: Verify regressions

**Objective:** Confirm no forbidden statements, no source-file changes, and no
application schema delta.

### Task 5: Restrict the base to Better Auth

**Objective:** Remove `todos` from every catalog file, then compare each remaining
table, column, constraint, and index with the Better Auth portion of its snapshot.

## Round Log

- In progress: mapped 23 schema-bearing plugins to their add snapshots and 14
  no-schema plugins to `0000_snapshot.json`. Snapshot foreign-key graphs contain
  no cycles, so every constraint can be declared inline without `ALTER TABLE`.
- Rewrote all 37 plugin files from their complete snapshots. Tables are ordered
  by foreign-key dependency, constraints are inline, and indexes follow the table
  definitions.
- Structural comparison passed across 37 files, 232 table definitions, 1,952
  columns, 237 named constraints, and 225 indexes.
- Round 1: completed all four tasks. Judge: 4/4 pass. Every file reconstructs
  its mapped complete snapshot, contains no migration-style mutation statement,
  and leaves the source schema and migration history unchanged.
- User clarification after Round 1: "base schema" means Better Auth's base tables,
  not the combined application snapshot. Criterion 1 previously required the full
  base snapshot, and Criterion 2 required every snapshot table. Both now explicitly
  exclude the application-only `todos` table. Added Task 5 for the correction.
- Round 2: removed `todos` from all 37 files and re-ran the judge against the
  clarified criteria. Judge: 4/4 pass. The catalog now contains only Better Auth
  core and plugin schema objects.

## Changed Files

- docs/builds/2026-09-02-plugin-complete-sql-schemas.md
- plugin-sql/

## Not Verified

- The SQL was not executed against PostgreSQL because the user asked for schema
  files only and the established workflow prohibits database changes.
- Full test suite and lint were not run because the project defines neither a test
  script nor a lint script.
- Browser flows were not exercised because the application does not load these
  standalone SQL reference files.
- External review was unavailable; an independent structural inventory and source
  preservation check was run instead.

## Verification Record

Profile: API, because the files contain executable PostgreSQL schema definitions.

- Snapshot structural comparison across 37 files — pass: 195 tables, 1,841
  columns, 237 named constraints, and 225 indexes matched.
- Application-table exclusion check, `! rg -n '\\btodos\\b' plugin-sql` — pass.
- Foreign-key dependency-order validation — pass.
- `! rg -n '^\\s*(ALTER|DROP)\\b' plugin-sql` — pass.
- Trailing-whitespace and terminating-semicolon checks — pass.
- `git diff --exit-code -- README.md drizzle src package.json pnpm-lock.yaml` —
  pass; source schemas, migrations, documentation, and application files are unchanged.
- `pnpm db:generate` — pass; final output: `No schema changes, nothing to migrate`.
- `pnpm exec tsc --noEmit` — pass.
- `pnpm build` — pass; the existing TanStack demo route reports only the
  `createServerFn().inputValidator()` deprecation warning.
- Regression review — pass; all 37 filenames remain present, PayU remains excluded,
  and no database command was run.
