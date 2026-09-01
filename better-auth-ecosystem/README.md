# Plugin Research Documentation

## Table of contents

| Category | Plugins |
|---|---|
| Authentication | [Two Factor](#two-factor-authentication), [Magic Link](#magic-link-plugin-authentication), [Email OTP](#email-otp-plugin-authentication), [Passkey](#passkey-plugin-authentication), [Phone Number](#phone-number-plugin-authentication), [Anonymous](#anonymous-plugin-authentication), [Username](#username-plugin-authentication), [One Tap](#one-tap-plugin-authentication), [Sign In With Ethereum](#sign-in-with-ethereum-plugin-authentication), [Generic OAuth](#generic-oauth-plugin-authentication), [Last Login Method](#last-login-method-plugin-utility), [Multi-Session](#multi-session-plugin-utility) |
| Authorization and management | [Admin](#admin-plugin-authorization), [Organization](#organization-plugin-authorization), [SSO](#sso-plugin-authorization-and-management), [SCIM](#scim-plugin-authorization-and-management) |
| API and tokens | [Agent Auth](#agent-auth-plugin-authorization), [API Key](#api-key-plugin-api-and-tokens), [JWT](#jwt-plugin-api-and-tokens), [Bearer](#bearer-plugin-api-and-tokens), [One-Time Token](#one-time-token-plugin-api-and-tokens), [OAuth Proxy](#oauth-proxy-plugin-api-and-tokens) |
| OAuth and OIDC providers | [OAuth 2.1 Provider](#oauth-21-provider-plugin-oauth-and-oidc-providers), [MCP](#mcp-auth-plugin-authorization), [Device Authorization](#device-authorization-plugin-oauth-and-oidc-providers) |
| Security and utilities | [Captcha](#captcha-plugin-utility), [Have I Been Pwned](#have-i-been-pwned-plugin-security-and-utilities), [i18n](#i18n-plugin-security-and-utilities), [Open API](#open-api-plugin-security-and-utilities), [Test Utils](#test-utils-plugin-security-and-utilities), [DBSC Toolkit](#dbsc-toolkit-security) |
| Analytics and tracking | [Dub](#dub-plugin-analytics-and-tracking) |
| Payments | [Stripe](#stripe-plugin-payments), [PayU](#payu-plugin-payments) |
| Community | [Invite](#invite-community), [Referral](#referral-community), [Inbox](#inbox-community), [Email Challenge](#email-challenge-community) |

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

## Phone Number Plugin (authentication)

The Phone Number plugin has not been configured or schema-inspected in this
project.

## Anonymous Plugin (authentication)

The Anonymous plugin has not been configured or schema-inspected in this
project.

## Username Plugin (authentication)

The Username plugin has not been configured or schema-inspected in this project.

## One Tap Plugin (authentication)

The One Tap plugin has not been configured or schema-inspected in this project.

## Sign In With Ethereum Plugin (authentication)

The Sign In With Ethereum plugin has not been configured or schema-inspected in
this project.

## Generic OAuth Plugin (authentication)

The Generic OAuth plugin has not been configured or schema-inspected in this
project.

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

## SSO Plugin (authorization and management)

The SSO plugin has not been configured or schema-inspected in this project.

## SCIM Plugin (authorization and management)

The SCIM plugin has not been configured or schema-inspected in this project.

## Agent Auth Plugin (authorization)

The Agent Auth plugin has not been configured or schema-inspected in this
project.

## API Key Plugin (API and tokens)

The API Key plugin has not been configured or schema-inspected in this project.

## JWT Plugin (API and tokens)

The JWT plugin has not been configured or schema-inspected in this project.

## Bearer Plugin (API and tokens)

The Bearer plugin has not been configured or schema-inspected in this project.

## One-Time Token Plugin (API and tokens)

The One-Time Token plugin has not been configured or schema-inspected in this
project.

## OAuth Proxy Plugin (API and tokens)

The OAuth Proxy plugin has not been configured or schema-inspected in this
project.

## OAuth 2.1 Provider Plugin (OAuth and OIDC providers)

The OAuth 2.1 Provider plugin has not been configured or schema-inspected in
this project.

## MCP Auth Plugin (authorization)

The MCP plugin has not been configured or schema-inspected in this project.

## Device Authorization Plugin (OAuth and OIDC providers)

The Device Authorization plugin has not been configured or schema-inspected in
this project.

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

## Have I Been Pwned Plugin (security and utilities)

The Have I Been Pwned plugin has not been configured or schema-inspected in this
project.

## i18n Plugin (security and utilities)

The i18n plugin has not been configured or schema-inspected in this project.

## Open API Plugin (security and utilities)

The Open API plugin has not been configured or schema-inspected in this project.

## Test Utils Plugin (security and utilities)

The Test Utils plugin has not been configured or schema-inspected in this
project.

## Dub Plugin (analytics and tracking)

The Dub plugin has not been configured or schema-inspected in this project.

## Stripe Plugin (payments)

## PayU Plugin (payments)

## Invite (community)

## Referral (community)

## Inbox (community)

## Email Challenge (community)

## DBSC Toolkit (security)
