# Better Auth plugin schema research Buildout

Created: 2026-09-02
Agent: Codex
Status: VERIFIED
Approved: Yes
Rounds: 1
Worktree: No
Type: Build

## Summary

**Goal:** Research every currently unresearched plugin heading in `README.md` by
temporarily configuring it, generating its Better Auth and Drizzle schema changes,
recording the exact result, and returning the application to its base configuration.

**Oracle:** `README.md` records a generated schema result or an evidence-backed
statement that no schema is added for every target heading, while `src/lib/auth.ts`
ends with `plugins: []` and a final `pnpm db:generate` reports no pending source-schema
change.

**Misfire:** The README could list generic descriptions without a real generator run.
Each plugin's recorded result must be supported by that plugin's generation attempt and
the resulting Drizzle migration or no-change output.

**Constraints:** Do not run `pnpm db:migrate`, `pnpm db:push`, or any database write.
Preserve existing README findings. Use non-production placeholders only. Do not add real
credentials, call payment providers, or send email. Keep unrelated working-tree files
untouched.

**Assumed:** “All plugins introduced in README” includes all currently unresearched
official, payment, and community headings. A package or integration that cannot be
identified and configured safely will be recorded as blocked with the precise missing
choice rather than guessed.

## Acceptance Criteria

- [x] Criterion 1: Every currently unresearched README heading has either an exact
  generated table and field record or a documented no-schema result backed by a plugin
  generation attempt.
- [x] Criterion 2: No migration is applied and the final source configuration has an
  empty Better Auth plugin array, as shown by `src/lib/auth.ts` and the final Drizzle
  no-change generation output.
- [x] Criterion 3: The existing findings remain in README and every new entry clearly
  distinguishes generated-only migrations from applied migrations.
- [x] Criterion 4: The final source configuration typechecks and builds successfully.

## Out of Scope

- Enabling any researched plugin in the finished application
- Production credentials, webhook delivery, email delivery, or payment-provider calls
- Applying migrations or changing the database

## Progress Tracking

- [x] Task 1: Research and inspect the remaining authentication and authorization plugins.
- [x] Task 2: Research and inspect API, token, OAuth, and provider plugins.
- [x] Task 3: Research and inspect security, utility, and analytics plugins.
- [x] Task 4: Research payment and community plugins only where an exact compatible package and safe schema-only setup can be verified.
- [x] Task 5: Restore the base configuration, update README, and run final checks.

## Implementation Tasks

### Task 1: Inspect authentication and authorization plugins

**Objective:** Run the documented schema-only cycle for Phone Number, Anonymous,
Username, One Tap, Sign In With Ethereum, Generic OAuth, SSO, and SCIM.

### Task 2: Inspect API, token, and OAuth plugins

**Objective:** Run the same cycle for Agent Auth, API Key, JWT, Bearer, One-Time Token,
OAuth Proxy, OAuth 2.1 Provider, MCP, and Device Authorization.

### Task 3: Inspect security, utility, and analytics plugins

**Objective:** Run the same cycle for Have I Been Pwned, i18n, Open API, Test Utils, and
Dub.

### Task 4: Inspect payment and community plugins

**Objective:** Verify package ownership and compatibility for Stripe, PayU, Invite,
Referral, Inbox, Email Challenge, and DBSC Toolkit, then perform schema-only cycles only
when they need no real provider account, credential, or unsafe guessed integration.

### Task 5: Restore and verify

**Objective:** Remove all temporary plugin configuration, document generated results and
known blockers, then typecheck and build the returned base configuration.

## Round Log

- In progress: completed schema-only add/remove cycles for Phone Number,
  Anonymous, Username, One Tap, Sign In With Ethereum, Generic OAuth, SSO, SCIM,
  API Key, JWT, Bearer, One-Time Token, OAuth Proxy, and Device Authorization.
  No migration has been applied. SCIM initially failed because the Drizzle adapter
  lacked native transaction support; enabling `transaction: true` for its temporary
  configuration allowed generation, and that setting was removed afterwards.
- Completed Agent Auth, OAuth 2.1 Provider, and MCP cycles. MCP initially
  required the OAuth Provider models to be generated before its own schema
  could load; its final add/remove pair contains the OAuth tables and JWKS.
- Completed no-schema checks for Have I Been Pwned, i18n, Open API, Test Utils,
  and Dub.
- Completed generated-only add/remove cycles for Stripe, Invite, Referral,
  Inbox, Email Challenge, and DBSC Toolkit. Referral emitted an invalid reverse
  Drizzle relation; it was corrected temporarily so the plugin-free generator
  could overwrite it and produce the rollback.
- Attempted PayU generation with the catalogued `better-auth-payu@0.1.0`
  package. Its published package omits the `dist` files named by its exports,
  so generation could not start. This blocker is recorded in README.
- Round 1: completed all five tasks. Judge: 4/4 pass. README contains a generated
  result or an exact failed-attempt result for every target heading; the final
  auth config is plugin-free; existing findings remain; schema generation,
  typechecking, and the production build pass.

## Changed Files

- docs/builds/2026-09-02-plugin-schema-research.md
- README.md
- package.json
- pnpm-lock.yaml
- src/lib/auth.ts
- src/db/auth-schema.ts
- drizzle/

## Not Verified

- Full test suite: the project has no test script or test configuration.
- Lint: the project has no lint script or lint configuration.
- Applied-database state: not checked by applying migrations because the user
  explicitly required generated schema changes only.
- Browser and live auth flows: not exercised because every researched plugin is
  intentionally removed from the final configuration.
- External review: no configured changes reviewer was available in this session;
  the migration pairs and README entries received a manual diff review instead.

## Verification Record

Profile: API, because the run produced database migration SQL but no enabled
runtime plugin or new user interface.

- `pnpm db:generate` — pass; final output: `No schema changes, nothing to migrate`.
- `pnpm exec tsc --noEmit` — pass.
- `pnpm build` — pass; the existing TanStack demo route reports only the
  `createServerFn().inputValidator()` deprecation warning.
- `git diff --check -- README.md docs/builds/2026-09-02-plugin-schema-research.md src/lib/auth.ts src/db/auth-schema.ts package.json pnpm-lock.yaml drizzle` — pass.
- Manual review of `README.md`, `src/lib/auth.ts`, `src/db/auth-schema.ts`,
  `package.json`, and migration pairs `0033` through `0046` — pass.
- Documentation sync — pass; every README heading now contains a result and the
  table of contents links all plugin sections.
- Regression check — pass; `src/lib/auth.ts` ends with `plugins: []`, the auth
  schema contains only the core models, and research-only packages are absent
  from `package.json`.
