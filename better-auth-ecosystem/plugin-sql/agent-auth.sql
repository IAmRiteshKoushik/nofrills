-- Complete PostgreSQL schema for the Better Auth Agent Auth plugin.
-- Source snapshot: drizzle/meta/0029_snapshot.json
-- Contains the base application schema and this plugin's final schema state.

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

CREATE TABLE "public"."agent_host" (
  "id" text PRIMARY KEY NOT NULL,
  "name" text,
  "user_id" text,
  "default_capabilities" text,
  "public_key" text,
  "kid" text,
  "jwks_url" text,
  "enrollment_token_hash" text,
  "enrollment_token_expires_at" timestamp,
  "status" text DEFAULT 'active' NOT NULL,
  "activated_at" timestamp,
  "expires_at" timestamp,
  "last_used_at" timestamp,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  CONSTRAINT "agent_host_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
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

CREATE TABLE "public"."agent" (
  "id" text PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "user_id" text,
  "host_id" text NOT NULL,
  "status" text DEFAULT 'active' NOT NULL,
  "mode" text DEFAULT 'delegated' NOT NULL,
  "public_key" text NOT NULL,
  "kid" text,
  "jwks_url" text,
  "last_used_at" timestamp,
  "activated_at" timestamp,
  "expires_at" timestamp,
  "metadata" text,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  CONSTRAINT "agent_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "agent_host_id_agent_host_id_fk" FOREIGN KEY ("host_id") REFERENCES "public"."agent_host" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."agent_capability_grant" (
  "id" text PRIMARY KEY NOT NULL,
  "agent_id" text NOT NULL,
  "capability" text NOT NULL,
  "denied_by" text,
  "granted_by" text,
  "expires_at" timestamp,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "status" text DEFAULT 'active' NOT NULL,
  "reason" text,
  "constraints" text,
  CONSTRAINT "agent_capability_grant_agent_id_agent_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agent" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "agent_capability_grant_denied_by_user_id_fk" FOREIGN KEY ("denied_by") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "agent_capability_grant_granted_by_user_id_fk" FOREIGN KEY ("granted_by") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."approval_request" (
  "id" text PRIMARY KEY NOT NULL,
  "method" text NOT NULL,
  "agent_id" text,
  "host_id" text,
  "user_id" text,
  "capabilities" text,
  "status" text DEFAULT 'pending' NOT NULL,
  "user_code_hash" text,
  "login_hint" text,
  "binding_message" text,
  "client_notification_token" text,
  "client_notification_endpoint" text,
  "delivery_mode" text,
  "interval" integer NOT NULL,
  "last_polled_at" timestamp,
  "expires_at" timestamp NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  CONSTRAINT "approval_request_agent_id_agent_id_fk" FOREIGN KEY ("agent_id") REFERENCES "public"."agent" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "approval_request_host_id_agent_host_id_fk" FOREIGN KEY ("host_id") REFERENCES "public"."agent_host" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "approval_request_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX "verification_identifier_idx" ON "public"."verification" USING btree ("identifier" ASC NULLS LAST);

CREATE UNIQUE INDEX "account_issuer_accountId_uidx" ON "public"."account" USING btree ("issuer" ASC NULLS LAST, "account_id" ASC NULLS LAST);

CREATE INDEX "account_userId_idx" ON "public"."account" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "agentHost_userId_idx" ON "public"."agent_host" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "agentHost_kid_idx" ON "public"."agent_host" USING btree ("kid" ASC NULLS LAST);

CREATE INDEX "agentHost_enrollmentTokenHash_idx" ON "public"."agent_host" USING btree ("enrollment_token_hash" ASC NULLS LAST);

CREATE INDEX "agentHost_status_idx" ON "public"."agent_host" USING btree ("status" ASC NULLS LAST);

CREATE INDEX "session_userId_idx" ON "public"."session" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "agent_userId_idx" ON "public"."agent" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "agent_hostId_idx" ON "public"."agent" USING btree ("host_id" ASC NULLS LAST);

CREATE INDEX "agent_status_idx" ON "public"."agent" USING btree ("status" ASC NULLS LAST);

CREATE INDEX "agent_kid_idx" ON "public"."agent" USING btree ("kid" ASC NULLS LAST);

CREATE INDEX "agentCapabilityGrant_agentId_idx" ON "public"."agent_capability_grant" USING btree ("agent_id" ASC NULLS LAST);

CREATE INDEX "agentCapabilityGrant_capability_idx" ON "public"."agent_capability_grant" USING btree ("capability" ASC NULLS LAST);

CREATE INDEX "agentCapabilityGrant_grantedBy_idx" ON "public"."agent_capability_grant" USING btree ("granted_by" ASC NULLS LAST);

CREATE INDEX "agentCapabilityGrant_status_idx" ON "public"."agent_capability_grant" USING btree ("status" ASC NULLS LAST);

CREATE INDEX "approvalRequest_agentId_idx" ON "public"."approval_request" USING btree ("agent_id" ASC NULLS LAST);

CREATE INDEX "approvalRequest_hostId_idx" ON "public"."approval_request" USING btree ("host_id" ASC NULLS LAST);

CREATE INDEX "approvalRequest_userId_idx" ON "public"."approval_request" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "approvalRequest_status_idx" ON "public"."approval_request" USING btree ("status" ASC NULLS LAST);
