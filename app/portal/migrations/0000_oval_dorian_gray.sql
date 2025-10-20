CREATE TABLE `cloudflare_access_organization` (
	`cloudflare_access_id` text PRIMARY KEY NOT NULL,
	`created_at` integer NOT NULL,
	`id` text(24) NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`id`) REFERENCES `organization`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `cloudflare_access_organization_id_unique` ON `cloudflare_access_organization` (`id`);--> statement-breakpoint
CREATE TABLE `cloudflare_access_user` (
	`cloudflare_access_id` text PRIMARY KEY NOT NULL,
	`created_at` integer NOT NULL,
	`id` text(24) NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`id`) REFERENCES `user`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `cloudflare_access_user_id_unique` ON `cloudflare_access_user` (`id`);--> statement-breakpoint
CREATE TABLE `organization` (
	`created_at` integer NOT NULL,
	`id` text(24) PRIMARY KEY NOT NULL,
	`is_personal` integer NOT NULL,
	`name` text NOT NULL,
	`updated_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `user` (
	`created_at` integer NOT NULL,
	`id` text(24) PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`updated_at` integer NOT NULL
);
