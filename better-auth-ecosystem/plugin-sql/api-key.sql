-- Complete PostgreSQL schema for the Better Auth API Key plugin.
-- Source snapshot: drizzle/meta/0023_snapshot.json
-- Contains the base application schema and this plugin's final schema state.

CREATE TABLE "public"."apikey" (
  "id" text PRIMARY KEY NOT NULL,
  "config_id" text DEFAULT 'default' NOT NULL,
  "name" text,
  "start" text,
  "reference_id" text NOT NULL,
  "prefix" text,
  "key" text NOT NULL,
  "refill_interval" integer,
  "refill_amount" integer,
  "last_refill_at" timestamp,
  "enabled" boolean DEFAULT true,
  "rate_limit_enabled" boolean DEFAULT true,
  "rate_limit_time_window" integer DEFAULT 86400000,
  "rate_limit_max" integer DEFAULT 10,
  "request_count" integer DEFAULT 0,
  "remaining" integer,
  "last_request" timestamp,
  "expires_at" timestamp,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL,
  "permissions" text,
  "metadata" text
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

CREATE INDEX "apikey_configId_idx" ON "public"."apikey" USING btree ("config_id" ASC NULLS LAST);

CREATE INDEX "apikey_referenceId_idx" ON "public"."apikey" USING btree ("reference_id" ASC NULLS LAST);

CREATE INDEX "apikey_key_idx" ON "public"."apikey" USING btree ("key" ASC NULLS LAST);

CREATE INDEX "verification_identifier_idx" ON "public"."verification" USING btree ("identifier" ASC NULLS LAST);

CREATE UNIQUE INDEX "account_issuer_accountId_uidx" ON "public"."account" USING btree ("issuer" ASC NULLS LAST, "account_id" ASC NULLS LAST);

CREATE INDEX "account_userId_idx" ON "public"."account" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "session_userId_idx" ON "public"."session" USING btree ("user_id" ASC NULLS LAST);
