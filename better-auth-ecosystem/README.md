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

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `user` | `phone_number` | `text` | none | Stores the user's unique phone number. |
| `user` | `phone_number_verified` | `boolean` | none | Indicates whether the phone number has been verified. |

## Anonymous Plugin (authentication)

The Anonymous plugin generated `drizzle/0013_handy_blonde_phantom.sql`, then
was removed. The rollback migration `drizzle/0014_sharp_harrier.sql` was
generated. Neither migration has been applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `user` | `is_anonymous` | `boolean` | `false` | Indicates whether the user is anonymous. |

## Username Plugin (authentication)

The Username plugin generated `drizzle/0015_graceful_calypso.sql`, then was
removed. The rollback migration `drizzle/0016_concerned_famine.sql` was
generated. Neither migration has been applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `user` | `username` | `text` | none | Stores the user's unique username. |
| `user` | `display_username` | `text` | none | Stores the username used for display. |

## One Tap Plugin (authentication)

The One Tap plugin was configured for schema inspection, then removed. It
generated no table, field, or migration.

## Sign In With Ethereum Plugin (authentication)

The Sign In With Ethereum plugin generated `drizzle/0017_perfect_reptil.sql`,
then was removed. The rollback migration `drizzle/0018_crazy_butterfly.sql` was
generated. Neither migration has been applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `wallet_address` | `id` | `text` | none | Primary key. |
| `wallet_address` | `user_id` | `text` | none | Required foreign key to `user.id`; cascades on user deletion. |
| `wallet_address` | `address` | `text` | none | Stores the wallet address. |
| `wallet_address` | `chain_id` | `integer` | none | Identifies the Ethereum chain. |
| `wallet_address` | `is_primary` | `boolean` | `false` | Indicates whether this is the user's primary wallet. |
| `wallet_address` | `created_at` | `timestamp` | none | Records when the wallet address was added. |

The generated migration adds a foreign key to `user.id` and an index on
`wallet_address.user_id`.

## Generic OAuth Plugin (authentication)

The Generic OAuth plugin was configured with non-routable inspection endpoints,
then removed. It generated no table, field, or migration.

## Admin Plugin (authorization)

| Table | Field | Type | Default | Purpose |
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

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `organization` | `id`, `name`, `slug`, `logo`, `created_at`, `metadata` | various | none | Stores organization identity, profile, and metadata fields; `slug` is unique. |
| `member` | `id`, `organization_id`, `user_id`, `role`, `created_at` | various | `role`: `member` | Stores organization membership fields. |
| `invitation` | `id`, `organization_id`, `email`, `role`, `status`, `expires_at`, `created_at`, `inviter_id` | various | `status`: `pending`; `created_at`: `now()` | Stores organization invitation fields. |
| `session` | `active_organization_id` | `text` | none | Stores the active organization for the session. |

The migration also adds foreign keys from memberships and invitations to their
organization and users, plus indexes for organization and user lookups.

## SSO Plugin (authorization and management)

The SSO plugin generated `drizzle/0019_magical_jamie_braddock.sql`, then was
removed. The rollback migration `drizzle/0020_acoustic_darkhawk.sql` was
generated. Neither migration has been applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `sso_provider` | `id`, `issuer`, `oidc_config`, `saml_config`, `user_id`, `provider_id`, `organization_id`, `domain` | `text` | none | Stores SSO provider identity, configuration, ownership, and domain fields; `provider_id` is unique. |

The generated migration adds a foreign key to `user.id`.

## SCIM Plugin (authorization and management)

The SCIM plugin required Drizzle native transaction support during its temporary
configuration. It generated `drizzle/0021_lowly_roxanne_simpson.sql`, then was
removed together with that temporary adapter setting. The rollback migration
`drizzle/0022_amazing_mantis.sql` was generated. Neither migration has been
applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `scim_connection_binding` | Connection identity, provisioning domain, decommission state, cursors, counters, and lease fields | various | varies | Tracks a SCIM connection and its decommissioning state. |
| `scim_group` | Connection and domain IDs, revision, display and external identity keys, ordering, and timestamps | various | varies | Stores a provisioned SCIM group. |
| `scim_group_member` | Connection, group, SCIM user, membership key, and timestamp | various | none | Stores membership of a SCIM user in a SCIM group. |
| `scim_identity_tombstone` | Connection/domain IDs, external identity, linked user, serialized profile, and deletion time | various | none | Retains the identity of a deleted SCIM user. |
| `scim_projection_grant` | Connection/domain, SCIM user, Better Auth user, source, role, grant key, and timestamps | various | none | Stores a role grant projected from SCIM data. |
| `scim_subject` | Better Auth user ID, profile source ID, revision, and timestamps | various | none | Links a Better Auth user to its SCIM profile source. |
| `scim_user` | Connection/domain, Better Auth user, SCIM identity/profile, emails, names, attributes, lifecycle state, and timestamps | various | none | Stores the provisioned SCIM user profile and lifecycle state. |

The migration adds the documented foreign keys and lookup indexes for the SCIM
resources.

## Agent Auth Plugin (authorization)

The Agent Auth plugin generated `drizzle/0029_fancy_red_skull.sql`, then was
removed. The rollback migration `drizzle/0030_blue_psynapse.sql` was generated.
Neither migration has been applied. The registry's compatible package release is
currently `@better-auth/agent-auth` `0.6.2`, despite the main Better Auth release
being `1.7.2`.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `agent` | Identity, host and optional user links, status/mode, keys, lifecycle times, metadata, and timestamps | various | varies | Stores an agent's identity, credentials, state, and lifecycle. |
| `agent_capability_grant` | Agent, capability, grant/deny users, status, constraints, expiry, and timestamps | various | varies | Stores an agent capability grant or denial. |
| `agent_host` | Host identity, optional user link, default capabilities, keys, enrollment token state, lifecycle times, and timestamps | various | varies | Stores an agent host's identity, credentials, enrollment, and lifecycle. |
| `approval_request` | Agent/host/user links, approval method and state, capabilities, device/CIBA values, polling state, expiry, and timestamps | various | varies | Tracks an agent authorization request. |

The migration adds foreign keys to the related agent, host, and user records, as
well as lifecycle and lookup indexes.

## API Key Plugin (API and tokens)

The API Key plugin generated `drizzle/0023_groovy_kingpin.sql`, then was
removed. The rollback migration `drizzle/0024_sleepy_crusher_hogan.sql` was
generated. Neither migration has been applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `apikey` | Key/configuration identity, owner reference, key material and prefix, refill/rate-limit state, expiry, timestamps, permissions, and metadata | various | varies | Stores an API key, its owner, limits, permissions, and lifecycle. |

The migration adds indexes on `config_id`, `reference_id`, and `key`.

## JWT Plugin (API and tokens)

The JWT plugin generated `drizzle/0025_tan_silver_fox.sql`, then was removed.
The rollback migration `drizzle/0026_familiar_excalibur.sql` was generated.
Neither migration has been applied.

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `jwks` | `id` | `text` | none | Primary key. |
| `jwks` | `public_key` | `text` | none | Stores the public signing key. |
| `jwks` | `private_key` | `text` | none | Stores the private signing key. |
| `jwks` | `created_at` | `timestamp` | none | Records when the key pair was created. |
| `jwks` | `expires_at` | `timestamp` | none | Optional key-pair expiry time. |
| `jwks` | `alg` | `text` | none | Optional signing algorithm. |
| `jwks` | `crv` | `text` | none | Optional elliptic curve identifier. |

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

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `jwks` | Signing key identity, public/private keys, creation and expiry, algorithm, and curve | various | none | Stores the provider's signing keys. |
| `oauth_access_token` | Token, client/session/user links, authorization and refresh references, resources, claims, scopes, expiry, revocation, and confirmation | various | none | Stores an issued OAuth access token and its authorization context. |
| `oauth_client` | Client identity/secret, registration metadata, redirects, scopes, token settings, DPoP state, and ownership metadata | various | varies | Stores an OAuth client's registration and token configuration. |
| `oauth_client_assertion` | Assertion identifier and expiry | various | none | Tracks a client assertion until it expires. |
| `oauth_client_resource` | Client/resource relationship, metadata, and creation time | various | none | Associates an OAuth client with a protected resource. |
| `oauth_consent` | Client/user references, resources, requested claims, scopes, and timestamps | various | none | Records the scopes, resources, and claims approved by a user. |
| `oauth_refresh_token` | Token/client/session/user references, authorization state, expiry, rotation/replay data, confirmation, and scopes | various | none | Stores an OAuth refresh token and its rotation state. |
| `oauth_resource` | Resource identity, token policy, signing configuration, scopes, DPoP and disabled state, timestamps, and metadata | various | varies | Stores a protected resource and its token policy. |

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

| Table | Field | Type | Default | Purpose |
|---|---|---|---|---|
| `device_code` | `id`, device/user codes, optional user ID, expiry, status, polling state, client ID, and scope | various | none | Tracks an OAuth device authorization request and its polling state. |

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

The Have I Been Pwned plugin was configured with network checks disabled, then
removed. It generated no table, field, or migration.

## i18n Plugin (security and utilities)

The i18n plugin was configured with an inspection-only translation, then
removed. It generated no table, field, or migration.

## Open API Plugin (security and utilities)

The Open API plugin was configured for schema inspection with Have I Been Pwned
and Test Utils, then removed. It generated no table, field, or migration.

## Test Utils Plugin (security and utilities)

The Test Utils plugin was configured for schema inspection with Have I Been
Pwned and Open API, then removed. It generated no table, field, or migration.

## Dub Plugin (analytics and tracking)

The Dub plugin was configured with lead tracking disabled and a non-routable Dub
client, then removed. It generated no table, field, or migration. The official
integration package is `@dub/better-auth`; it is not published as
`@better-auth/dub`.

## Stripe Plugin (payments)

## PayU Plugin (payments)

## Invite (community)

## Referral (community)

## Inbox (community)

## Email Challenge (community)

## DBSC Toolkit (security)
