CREATE TABLE `organization_link` (
	`created_at` integer NOT NULL,
	`organization_id` text(24) NOT NULL,
	`provider` text NOT NULL,
	`provider_organization_id` text NOT NULL,
	`updated_at` integer NOT NULL,
	PRIMARY KEY(`organization_id`, `provider`),
	FOREIGN KEY (`organization_id`) REFERENCES `organization`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `organization_link_unique_provider_organization_id_idx` ON `organization_link` (`provider_organization_id`,`provider`);--> statement-breakpoint
CREATE TABLE `primary_user_link` (
	`created_at` integer NOT NULL,
	`provider` text NOT NULL,
	`updated_at` integer NOT NULL,
	`user_id` text(24) PRIMARY KEY NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`user_id`,`provider`) REFERENCES `user_link`(`user_id`,`provider`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `user_link` (
	`created_at` integer NOT NULL,
	`provider` text NOT NULL,
	`provider_user_email` text NOT NULL,
	`provider_user_id` text NOT NULL,
	`updated_at` integer NOT NULL,
	`user_id` text(24) NOT NULL,
	PRIMARY KEY(`user_id`, `provider`),
	FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `user_link_unique_provider_user_id_email_idx` ON `user_link` (`provider_user_id`,`provider`);--> statement-breakpoint
CREATE UNIQUE INDEX `user_link_unique_provider_user_email_idx` ON `user_link` (`provider_user_email`,`provider`);--> statement-breakpoint
DROP TABLE `cloudflare_access_organization`;--> statement-breakpoint
DROP TABLE `cloudflare_access_user`;