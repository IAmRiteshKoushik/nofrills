CREATE TABLE "dbsc_bound_key" (
	"id" text PRIMARY KEY NOT NULL,
	"session_id" text NOT NULL,
	"kind" text NOT NULL,
	"jwk" text NOT NULL,
	"created_at" integer NOT NULL,
	"algorithm" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "dbsc_session" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"tier" text NOT NULL,
	"created_at" integer NOT NULL,
	"expires_at" integer NOT NULL,
	"last_refresh_at" integer NOT NULL
);
--> statement-breakpoint
ALTER TABLE "dbsc_bound_key" ADD CONSTRAINT "dbsc_bound_key_session_id_dbsc_session_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."dbsc_session"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "dbsc_session" ADD CONSTRAINT "dbsc_session_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;