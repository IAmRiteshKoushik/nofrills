-- Complete PostgreSQL schema for the Better Auth Invite plugin.
-- Source snapshot: drizzle/meta/0037_snapshot.json
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

CREATE TABLE "public"."invite" (
  "id" text PRIMARY KEY NOT NULL,
  "token" text NOT NULL,
  "created_at" timestamp NOT NULL,
  "expires_at" timestamp NOT NULL,
  "max_uses" integer NOT NULL,
  "infinity_max_uses" boolean DEFAULT false NOT NULL,
  "created_by_user_id" text NOT NULL,
  "redirect_to_after_upgrade" text,
  "share_inviter_name" boolean NOT NULL,
  "email" text,
  "emails" text[],
  "role" text NOT NULL,
  "new_account" boolean,
  "status" text NOT NULL,
  CONSTRAINT "invite_token_unique" UNIQUE ("token"),
  CONSTRAINT "invite_created_by_user_id_user_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."user" ("id") ON DELETE SET NULL ON UPDATE NO ACTION
);

CREATE TABLE "public"."invite_use" (
  "id" text PRIMARY KEY NOT NULL,
  "invite_id" text NOT NULL,
  "used_at" timestamp NOT NULL,
  "used_by_user_id" text,
  CONSTRAINT "invite_use_invite_id_invite_id_fk" FOREIGN KEY ("invite_id") REFERENCES "public"."invite" ("id") ON DELETE SET NULL ON UPDATE NO ACTION,
  CONSTRAINT "invite_use_used_by_user_id_user_id_fk" FOREIGN KEY ("used_by_user_id") REFERENCES "public"."user" ("id") ON DELETE SET NULL ON UPDATE NO ACTION
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

CREATE INDEX "verification_identifier_idx" ON "public"."verification" USING btree ("identifier" ASC NULLS LAST);

CREATE UNIQUE INDEX "account_issuer_accountId_uidx" ON "public"."account" USING btree ("issuer" ASC NULLS LAST, "account_id" ASC NULLS LAST);

CREATE INDEX "account_userId_idx" ON "public"."account" USING btree ("user_id" ASC NULLS LAST);

CREATE INDEX "session_userId_idx" ON "public"."session" USING btree ("user_id" ASC NULLS LAST);
