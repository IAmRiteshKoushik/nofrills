# Plugin Research Documentation

## Two Factor (authentication)

The Two-Factor plugin was configured for TOTP and generated
`drizzle/0003_natural_nehzno.sql`. It was later removed; the rollback migration
`drizzle/0004_yielding_vivisector.sql` was applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `user` | `two_factor_enabled` | `boolean` | `false` | Indicates whether the user had enabled 2FA. |
| `two_factor` | `id` | `text` | none | Primary key. |
| `two_factor` | `secret` | `text` | none | TOTP secret. |
| `two_factor` | `backup_codes` | `text` | none | Stored backup and recovery codes. |
| `two_factor` | `user_id` | `text` | none | Required foreign key to `user.id`; cascaded on user deletion. |
| `two_factor` | `verified` | `boolean` | `true` | Whether the second-factor setup was verified. |
| `two_factor` | `failed_verification_count` | `integer` | `0` | Tracked failed verification attempts. |
| `two_factor` | `locked_until` | `timestamp` | none | Optional temporary lockout time. |

The generated migration also created indexes on `two_factor.secret` and
`two_factor.user_id`.

## Magic Link Plugin (authentication)

The Magic Link plugin was configured with a fail-closed delivery placeholder for
schema generation, then removed. It generated no new table or field because it
reuses Better Auth's existing `verification` table for single-use link tokens.
No migration was generated or applied.

## Email OTP Plugin (authentication)

The Email OTP plugin was configured with a fail-closed delivery placeholder for
schema generation, then removed. It generated no new table or field because it
reuses Better Auth's existing `verification` table for OTP records. No migration
was generated or applied.

## Passkey Plugin (authentication)

The Passkey plugin generated `drizzle/0005_lazy_lorna_dane.sql`, then was
removed. The rollback migration `drizzle/0006_great_tag.sql` was generated.
Neither migration has been applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `passkey` | `id` | `text` | none | Primary key. |
| `passkey` | `name` | `text` | none | Optional user label for the passkey. |
| `passkey` | `public_key` | `text` | none | Registered WebAuthn public key. |
| `passkey` | `user_id` | `text` | none | Required foreign key to `user.id`; cascades on user deletion. |
| `passkey` | `credential_id` | `text` | none | Identifier assigned to the registered credential. |
| `passkey` | `counter` | `integer` | none | WebAuthn signature counter. |
| `passkey` | `device_type` | `text` | none | Authenticator device type. |
| `passkey` | `backed_up` | `boolean` | none | Whether the credential is backed up. |
| `passkey` | `transports` | `text` | none | Optional authenticator transports. |
| `passkey` | `created_at` | `timestamp` | none | Optional registration timestamp. |
| `passkey` | `aaguid` | `text` | none | Optional authenticator model identifier. |

The generated migration also adds indexes on `passkey.user_id` and
`passkey.credential_id`.

## Admin Plugin (authorization)

| Table | New column | Type | Default | Purpose |
|---|---|---|---|---|
| `user` | `role` | `text` | none | Stores the user's Better Auth role, such as `admin` or `user`. |
| `user` | `banned` | `boolean` | `false` | Marks an account as banned. |
| `user` | `ban_reason` | `text` | none | Stores the reason for a ban. |
| `user` | `ban_expires` | `timestamp` | none | Optional expiry for a temporary ban. |
| `session` | `impersonated_by` | `text` | none | Records the user ID of the administrator who started an impersonation session. |

## Organization Plugin (authorization)

The Organization plugin generated `drizzle/0007_white_the_hand.sql`, then was
removed. The rollback migration `drizzle/0008_lush_jigsaw.sql` was generated.
Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `organization` | `id`, `name`, `slug` (unique), `logo`, `created_at`, `metadata` |
| `member` | `id`, `organization_id`, `user_id`, `role` (default `member`), `created_at` |
| `invitation` | `id`, `organization_id`, `email`, `role`, `status` (default `pending`), `expires_at`, `created_at`, `inviter_id` |
| `session` | Added nullable `active_organization_id` |

The migration also adds foreign keys from memberships and invitations to their
organization and users, plus indexes for organization and user lookups.

## Agent Auth Plugin (authorization)

## MCP Auth Plugin (authorization)

## Captcha Plugin (utility)

The Captcha plugin was loaded with a nonfunctional Turnstile placeholder for
schema inspection, then removed. It generated no table, field, or migration.

## Last Login Method Plugin (utility)

The Last Login Method plugin was generated with database persistence enabled.
`drizzle/0009_glossy_boomer.sql` adds nullable `user.last_login_method` (`text`)
to store the most recently used authentication method. The plugin was then
removed; `drizzle/0010_superb_human_fly.sql` drops that field. Neither migration
is applied.

## Multi-Session Plugin (utility)

The Multi-Session plugin was configured and then removed. It stores multiple
active sessions in browser cookies and generated no table, field, or migration.

## Stripe Plugin (payments)

## PayU Plugin (payments)

## Invite (community)

## Referral (community)

## Inbox (community)

## Email Challenge (community)

## DBSC Toolkit (security)
