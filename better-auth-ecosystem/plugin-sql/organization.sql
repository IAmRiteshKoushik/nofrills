-- Complete PostgreSQL schema for the Better Auth Organization plugin.
-- Source snapshot: drizzle/meta/0007_snapshot.json
-- Contains the base application schema and this plugin's final schema state.

CREATE TABLE "public"."organization" (
  "id" text PRIMARY KEY NOT NULL,
  "name" text NOT NULL,
  "slug" text NOT NULL,
  "logo" text,
  "created_at" timestamp NOT NULL,
  "metadata" text,
  CONSTRAINT "organization_slug_unique" UNIQUE ("slug")
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

CREATE TABLE "public"."invitation" (
  "id" text PRIMARY KEY NOT NULL,
  "organization_id" text NOT NULL,
  "email" text NOT NULL,
  "role" text,
  "status" text DEFAULT 'pending' NOT NULL,
  "expires_at" timestamp NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "inviter_id" text NOT NULL,
  CONSTRAINT "invitation_organization_id_organization_id_fk" FOREIGN KEY ("organization_id") REFERENCES "public"."organization" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "invitation_inviter_id_user_id_fk" FOREIGN KEY ("inviter_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."member" (
  "id" text PRIMARY KEY NOT NULL,
  "organization_id" text NOT NULL,
  "user_id" text NOT NULL,
  "role" text DEFAULT 'member' NOT NULL,
  "created_at" timestamp NOT NULL,
  CONSTRAINT "member_organization_id_organization_id_fk" FOREIGN KEY ("organization_id") REFERENCES "public"."organization" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "member_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
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
  "active_organization_id" text,
  CONSTRAINT "session_token_unique" UNIQUE ("token"),
  CONSTRAINT "session_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX "verification_identifier_idx" ON "public"."verification" USING btree ("identifier" ASC NULLS LAST);

CREATE UNIQUE INDEX "account_issuer_accountId_uidx" ON "public"."account" USING btree ("issuer" ASC NULLS LAST, "account_id" ASC NULLS LAST);

CREATE INDEX "account_userId_idx" ON "public"."account" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "invitation_organizationId_idx" ON "public"."invitation" USING btree ("organization_id" ASC NULLS LAST);

CREATE INDEX "invitation_email_idx" ON "public"."invitation" USING btree ("email" ASC NULLS LAST);

CREATE INDEX "member_organizationId_idx" ON "public"."member" USING btree ("organization_id" ASC NULLS LAST);

CREATE INDEX "member_userId_idx" ON "public"."member" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "session_userId_idx" ON "public"."session" USING btree ("user_id" ASC NULLS LAST);
