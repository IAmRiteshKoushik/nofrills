-- Complete PostgreSQL schema for the Better Auth Referral plugin.
-- Source snapshot: drizzle/meta/0039_snapshot.json
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

CREATE TABLE "public"."referral_code" (
  "id" text PRIMARY KEY NOT NULL,
  "user_id" text NOT NULL,
  "code" text NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL,
  CONSTRAINT "referral_code_user_id_unique" UNIQUE ("user_id"),
  CONSTRAINT "referral_code_code_unique" UNIQUE ("code"),
  CONSTRAINT "referral_code_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE "public"."referrals" (
  "id" text PRIMARY KEY NOT NULL,
  "referrer_user_id" text NOT NULL,
  "referred_user_id" text NOT NULL,
  "referral_code_id" text NOT NULL,
  "status" text DEFAULT 'completed' NOT NULL,
  "completed_at" timestamp,
  "created_at" timestamp DEFAULT now() NOT NULL,
  CONSTRAINT "referrals_referred_user_id_unique" UNIQUE ("referred_user_id"),
  CONSTRAINT "referrals_referrer_user_id_user_id_fk" FOREIGN KEY ("referrer_user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "referrals_referred_user_id_user_id_fk" FOREIGN KEY ("referred_user_id") REFERENCES "public"."user" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "referrals_referral_code_id_referral_code_id_fk" FOREIGN KEY ("referral_code_id") REFERENCES "public"."referral_code" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
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

CREATE TABLE "public"."referral_step_completion" (
  "id" text PRIMARY KEY NOT NULL,
  "referral_id" text NOT NULL,
  "step" text NOT NULL,
  "completion_key" text NOT NULL,
  "metadata" jsonb,
  "completed_at" timestamp DEFAULT now() NOT NULL,
  CONSTRAINT "referral_step_completion_completion_key_unique" UNIQUE ("completion_key"),
  CONSTRAINT "referral_step_completion_referral_id_referrals_id_fk" FOREIGN KEY ("referral_id") REFERENCES "public"."referrals" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX "verification_identifier_idx" ON "public"."verification" USING btree ("identifier" ASC NULLS LAST);

CREATE UNIQUE INDEX "account_issuer_accountId_uidx" ON "public"."account" USING btree ("issuer" ASC NULLS LAST, "account_id" ASC NULLS LAST);

CREATE INDEX "account_userId_idx" ON "public"."account" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "session_userId_idx" ON "public"."session" USING btree ("user_id" ASC NULLS LAST);
