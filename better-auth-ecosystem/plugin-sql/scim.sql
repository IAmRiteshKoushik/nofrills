-- Complete PostgreSQL schema for the Better Auth SCIM plugin.
-- Source snapshot: drizzle/meta/0021_snapshot.json
-- Contains the base application schema and this plugin's final schema state.

CREATE TABLE "public"."scim_connection_binding" (
  "id" text PRIMARY KEY NOT NULL,
  "connection_id" text NOT NULL,
  "connection_key" text NOT NULL,
  "provisioning_domain_id" text NOT NULL,
  "created_at" timestamp NOT NULL,
  "decommissioned_at" timestamp,
  "decommission_status" text DEFAULT 'active' NOT NULL,
  "decommission_cursor_user_id" text,
  "decommission_reconciled_user_count" integer DEFAULT 0 NOT NULL,
  "decommission_batch_count" integer DEFAULT 0 NOT NULL,
  "decommission_revision" integer DEFAULT 0 NOT NULL,
  "decommission_completed_at" timestamp,
  "decommission_lease_id" text,
  "decommission_lease_expires_at" timestamp,
  CONSTRAINT "scim_connection_binding_connection_key_unique" UNIQUE ("connection_key")
);

CREATE TABLE "public"."scim_group" (
  "id" text PRIMARY KEY NOT NULL,
  "connection_id" text NOT NULL,
  "provisioning_domain_id" text NOT NULL,
  "revision" integer DEFAULT 0 NOT NULL,
  "display_name" text NOT NULL,
  "display_name_key" text NOT NULL,
  "external_id" text,
  "external_id_key" text,
  "order_key" text NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  CONSTRAINT "scim_group_display_name_key_unique" UNIQUE ("display_name_key"),
  CONSTRAINT "scim_group_external_id_key_unique" UNIQUE ("external_id_key"),
  CONSTRAINT "scim_group_order_key_unique" UNIQUE ("order_key")
);

CREATE TABLE "public"."user" (
  "id" text PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "email" text NOT NULL,
  "email_verified" boolean DEFAULT false NOT NULL,
  "image" text,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp DEFAULT now() NOT NULL,
  CONSTRAINT "user_email_unique" UNIQUE ("email")
);

CREATE TABLE "public"."verification" (
  "id" text PRIMARY KEY NOT NULL,
  "identifier" text NOT NULL,
  "value" text NOT NULL,
  "expires_at" timestamp NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp DEFAULT now() NOT NULL
);

CREATE TABLE "public"."account" (
  "id" text PRIMARY KEY NOT NULL,
  "issuer" text NOT NULL,
  "account_id" text NOT NULL,
  "provider_id" text NOT NULL,
  "user_id" text NOT NULL,
  "access_token" text,
  "refresh_token" text,
  "id_token" text,
  "access_token_expires_at" timestamp,
  "refresh_token_expires_at" timestamp,
  "scope" text,
  "password" text,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp NOT NULL,
  CONSTRAINT "account_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."scim_identity_tombstone" (
  "id" text PRIMARY KEY NOT NULL,
  "connection_id" text NOT NULL,
  "provisioning_domain_id" text NOT NULL,
  "external_id" text NOT NULL,
  "external_id_key" text NOT NULL,
  "user_id" text NOT NULL,
  "profile" text NOT NULL,
  "deleted_at" timestamp NOT NULL,
  CONSTRAINT "scim_identity_tombstone_external_id_key_unique" UNIQUE ("external_id_key"),
  CONSTRAINT "scim_identity_tombstone_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."scim_subject" (
  "id" text PRIMARY KEY NOT NULL,
  "user_id" text NOT NULL,
  "profile_source_id" text,
  "revision" integer NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  CONSTRAINT "scim_subject_user_id_unique" UNIQUE ("user_id"),
  CONSTRAINT "scim_subject_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."scim_user" (
  "id" text PRIMARY KEY NOT NULL,
  "connection_id" text NOT NULL,
  "provisioning_domain_id" text NOT NULL,
  "user_id" text NOT NULL,
  "connection_user_key" text NOT NULL,
  "user_name" text NOT NULL,
  "user_name_key" text NOT NULL,
  "primary_email" text NOT NULL,
  "work_email_value_index" text NOT NULL,
  "email_value_index" text NOT NULL,
  "display_name" text NOT NULL,
  "formatted_name" text NOT NULL,
  "given_name" text,
  "family_name" text,
  "serialized_emails" text NOT NULL,
  "serialized_attributes" text,
  "external_id" text,
  "external_id_key" text,
  "active" boolean NOT NULL,
  "order_key" text NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  CONSTRAINT "scim_user_connection_user_key_unique" UNIQUE ("connection_user_key"),
  CONSTRAINT "scim_user_user_name_key_unique" UNIQUE ("user_name_key"),
  CONSTRAINT "scim_user_external_id_key_unique" UNIQUE ("external_id_key"),
  CONSTRAINT "scim_user_order_key_unique" UNIQUE ("order_key"),
  CONSTRAINT "scim_user_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."session" (
  "id" text PRIMARY KEY NOT NULL,
  "expires_at" timestamp NOT NULL,
  "token" text NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp NOT NULL,
  "ip_address" text,
  "user_agent" text,
  "user_id" text NOT NULL,
  CONSTRAINT "session_token_unique" UNIQUE ("token"),
  CONSTRAINT "session_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."scim_group_member" (
  "id" text PRIMARY KEY NOT NULL,
  "connection_id" text NOT NULL,
  "group_id" text NOT NULL,
  "scim_user_id" text NOT NULL,
  "membership_key" text NOT NULL,
  "created_at" timestamp NOT NULL,
  CONSTRAINT "scim_group_member_membership_key_unique" UNIQUE ("membership_key"),
  CONSTRAINT "scim_group_member_group_id_scim_group_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."scim_group" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "scim_group_member_scim_user_id_scim_user_id_fk" FOREIGN KEY ("scim_user_id") REFERENCES "public"."scim_user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."scim_projection_grant" (
  "id" text PRIMARY KEY NOT NULL,
  "connection_id" text NOT NULL,
  "provisioning_domain_id" text NOT NULL,
  "scim_user_id" text NOT NULL,
  "user_id" text NOT NULL,
  "source_kind" text NOT NULL,
  "source_id" text NOT NULL,
  "source_value" text,
  "role" text NOT NULL,
  "grant_key" text NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  CONSTRAINT "scim_projection_grant_grant_key_unique" UNIQUE ("grant_key"),
  CONSTRAINT "scim_projection_grant_scim_user_id_scim_user_id_fk" FOREIGN KEY ("scim_user_id") REFERENCES "public"."scim_user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "scim_projection_grant_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX "scimConnectionBinding_connectionId_idx" ON "public"."scim_connection_binding" USING btree ("connection_id" ASC NULLS LAST);

CREATE INDEX "scimGroup_connectionId_idx" ON "public"."scim_group" USING btree ("connection_id" ASC NULLS LAST);

CREATE INDEX "scimGroup_provisioningDomainId_idx" ON "public"."scim_group" USING btree ("provisioning_domain_id" ASC NULLS LAST);

CREATE INDEX "verification_identifier_idx" ON "public"."verification" USING btree ("identifier" ASC NULLS LAST);

CREATE UNIQUE INDEX "account_issuer_accountId_uidx" ON "public"."account" USING btree ("issuer" ASC NULLS LAST, "account_id" ASC NULLS LAST);

CREATE INDEX "account_userId_idx" ON "public"."account" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "scimIdentityTombstone_connectionId_idx" ON "public"."scim_identity_tombstone" USING btree ("connection_id" ASC NULLS LAST);

CREATE INDEX "scimIdentityTombstone_provisioningDomainId_idx" ON "public"."scim_identity_tombstone" USING btree ("provisioning_domain_id" ASC NULLS LAST);

CREATE INDEX "scimIdentityTombstone_userId_idx" ON "public"."scim_identity_tombstone" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "scimSubject_profileSourceId_idx" ON "public"."scim_subject" USING btree ("profile_source_id" ASC NULLS LAST);

CREATE INDEX "scimUser_connectionId_idx" ON "public"."scim_user" USING btree ("connection_id" ASC NULLS LAST);

CREATE INDEX "scimUser_provisioningDomainId_idx" ON "public"."scim_user" USING btree ("provisioning_domain_id" ASC NULLS LAST);

CREATE INDEX "scimUser_userId_idx" ON "public"."scim_user" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "session_userId_idx" ON "public"."session" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "scimGroupMember_connectionId_idx" ON "public"."scim_group_member" USING btree ("connection_id" ASC NULLS LAST);

CREATE INDEX "scimGroupMember_groupId_idx" ON "public"."scim_group_member" USING btree ("group_id" ASC NULLS LAST);

CREATE INDEX "scimGroupMember_scimUserId_idx" ON "public"."scim_group_member" USING btree ("scim_user_id" ASC NULLS LAST);

CREATE INDEX "scimProjectionGrant_connectionId_idx" ON "public"."scim_projection_grant" USING btree ("connection_id" ASC NULLS LAST);

CREATE INDEX "scimProjectionGrant_provisioningDomainId_idx" ON "public"."scim_projection_grant" USING btree ("provisioning_domain_id" ASC NULLS LAST);

CREATE INDEX "scimProjectionGrant_scimUserId_idx" ON "public"."scim_projection_grant" USING btree ("scim_user_id" ASC NULLS LAST);

CREATE INDEX "scimProjectionGrant_userId_idx" ON "public"."scim_projection_grant" USING btree ("user_id" ASC NULLS LAST);
