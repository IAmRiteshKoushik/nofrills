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

The Phone Number plugin generated `drizzle/0011_steep_sandman.sql`, then was
removed. The rollback migration `drizzle/0012_even_nick_fury.sql` was generated.
Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `user` | Nullable `phone_number` (`text`, unique) and `phone_number_verified` (`boolean`) |

## Anonymous Plugin (authentication)

The Anonymous plugin generated `drizzle/0013_handy_blonde_phantom.sql`, then
was removed. The rollback migration `drizzle/0014_sharp_harrier.sql` was
generated. Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `user` | `is_anonymous` (`boolean`, default `false`) |

## Username Plugin (authentication)

The Username plugin generated `drizzle/0015_graceful_calypso.sql`, then was
removed. The rollback migration `drizzle/0016_concerned_famine.sql` was
generated. Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `user` | Nullable `username` (`text`, unique) and `display_username` (`text`) |

## One Tap Plugin (authentication)

The One Tap plugin was configured for schema inspection, then removed. It
generated no table, field, or migration.

## Sign In With Ethereum Plugin (authentication)

The Sign In With Ethereum plugin generated `drizzle/0017_perfect_reptil.sql`,
then was removed. The rollback migration `drizzle/0018_crazy_butterfly.sql` was
generated. Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `wallet_address` | `id`, `user_id`, `address`, `chain_id`, `is_primary` (default `false`), `created_at` |

The generated migration adds a foreign key to `user.id` and an index on
`wallet_address.user_id`.

## Generic OAuth Plugin (authentication)

The Generic OAuth plugin was configured with non-routable inspection endpoints,
then removed. It generated no table, field, or migration.

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

The SSO plugin generated `drizzle/0019_magical_jamie_braddock.sql`, then was
removed. The rollback migration `drizzle/0020_acoustic_darkhawk.sql` was
generated. Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `sso_provider` | `id`, `issuer`, `oidc_config`, `saml_config`, `user_id`, `provider_id` (unique), `organization_id`, `domain` |

The generated migration adds a foreign key to `user.id`.

## SCIM Plugin (authorization and management)

The SCIM plugin required Drizzle native transaction support during its temporary
configuration. It generated `drizzle/0021_lowly_roxanne_simpson.sql`, then was
removed together with that temporary adapter setting. The rollback migration
`drizzle/0022_amazing_mantis.sql` was generated. Neither migration has been
applied.

| Table | Generated fields |
|---|---|
| `scim_connection_binding` | Connection identity, provisioning domain, decommission state, cursors, counters, and lease fields |
| `scim_group` | Connection and domain IDs, revision, display and external identity keys, ordering, and timestamps |
| `scim_group_member` | Connection, group, SCIM user, membership key, and timestamp |
| `scim_identity_tombstone` | Connection/domain IDs, external identity, linked user, serialized profile, and deletion time |
| `scim_projection_grant` | Connection/domain, SCIM user, Better Auth user, source, role, grant key, and timestamps |
| `scim_subject` | Better Auth user ID, profile source ID, revision, and timestamps |
| `scim_user` | Connection/domain, Better Auth user, SCIM identity/profile, emails, names, attributes, lifecycle state, and timestamps |

The migration adds the documented foreign keys and lookup indexes for the SCIM
resources.

## Agent Auth Plugin (authorization)

The Agent Auth plugin generated `drizzle/0029_fancy_red_skull.sql`, then was
removed. The rollback migration `drizzle/0030_blue_psynapse.sql` was generated.
Neither migration has been applied. The registry's compatible package release is
currently `@better-auth/agent-auth` `0.6.2`, despite the main Better Auth release
being `1.7.2`.

| Table | Generated fields |
|---|---|
| `agent` | Identity, host and optional user links, status/mode, keys, lifecycle times, metadata, and timestamps |
| `agent_capability_grant` | Agent, capability, grant/deny users, status, constraints, expiry, and timestamps |
| `agent_host` | Host identity, optional user link, default capabilities, keys, enrollment token state, lifecycle times, and timestamps |
| `approval_request` | Agent/host/user links, approval method and state, capabilities, device/CIBA values, polling state, expiry, and timestamps |

The migration adds foreign keys to the related agent, host, and user records, as
well as lifecycle and lookup indexes.

## API Key Plugin (API and tokens)

The API Key plugin generated `drizzle/0023_groovy_kingpin.sql`, then was
removed. The rollback migration `drizzle/0024_sleepy_crusher_hogan.sql` was
generated. Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `apikey` | Key/configuration identity, owner reference, key material and prefix, refill/rate-limit state, expiry, timestamps, permissions, and metadata |

The migration adds indexes on `config_id`, `reference_id`, and `key`.

## JWT Plugin (API and tokens)

The JWT plugin generated `drizzle/0025_tan_silver_fox.sql`, then was removed.
The rollback migration `drizzle/0026_familiar_excalibur.sql` was generated.
Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `jwks` | `id`, public/private keys, `created_at`, `expires_at`, `alg`, and `crv` |

## Bearer Plugin (API and tokens)

The Bearer plugin was configured with One-Time Token and OAuth Proxy for schema
inspection, then removed. It generated no table, field, or migration.

## One-Time Token Plugin (API and tokens)

The One-Time Token plugin was configured with Bearer and OAuth Proxy for schema
inspection, then removed. It generated no table, field, or migration.

## OAuth Proxy Plugin (API and tokens)

The OAuth Proxy plugin was configured with Bearer and One-Time Token for schema
inspection, then removed. It generated no table, field, or migration.

## OAuth 2.1 Provider Plugin (OAuth and OIDC providers)

The OAuth 2.1 Provider plugin was configured with the required JWT plugin. It
generated `drizzle/0031_loving_tyger_tiger.sql`, then was removed. The rollback
migration `drizzle/0032_first_ma_gnuci.sql` was generated. Neither migration has
been applied.

| Table | Generated fields |
|---|---|
| `jwks` | Signing key identity, public/private keys, creation and expiry, algorithm, and curve |
| `oauth_access_token` | Token, client/session/user links, authorization and refresh references, resources, claims, scopes, expiry, revocation, and confirmation |
| `oauth_client` | Client identity/secret, registration metadata, redirects, scopes, token settings, DPoP state, and ownership metadata |
| `oauth_client_assertion` | Assertion identifier and expiry |
| `oauth_client_resource` | Client/resource relationship, metadata, and creation time |
| `oauth_consent` | Client/user references, resources, requested claims, scopes, and timestamps |
| `oauth_refresh_token` | Token/client/session/user references, authorization state, expiry, rotation/replay data, confirmation, and scopes |
| `oauth_resource` | Resource identity, token policy, signing configuration, scopes, DPoP and disabled state, timestamps, and metadata |

The migration also adds the OAuth foreign keys and client, user, session, token,
and resource indexes.

## MCP Auth Plugin (authorization)

The MCP plugin was configured with JWT and a non-routable protected resource.
Schema generation failed before output because the Drizzle adapter requires the
OAuth Provider models already present in the schema object, including
`oauthResource`. Retrying without the adapter schema produced the same error.
The temporary MCP configuration was removed and no migration was generated or
applied. Better Auth documents that MCP uses the OAuth Provider schema shown
above.

## Device Authorization Plugin (OAuth and OIDC providers)

The Device Authorization plugin generated `drizzle/0027_thin_loki.sql`, then
was removed. The rollback migration `drizzle/0028_clean_warstar.sql` was
generated. Neither migration has been applied.

| Table | Generated fields |
|---|---|
| `device_code` | `id`, device/user codes, optional user ID, expiry, status, polling state, client ID, and scope |

The migration adds unique indexes on the device and user codes.

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
