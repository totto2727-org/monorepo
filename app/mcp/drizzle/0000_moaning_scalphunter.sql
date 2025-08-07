CREATE TABLE `data_source` (
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`mcp_tool_name` text NOT NULL,
	`type` text NOT NULL,
	`url` text NOT NULL,
	PRIMARY KEY(`url`, `mcp_tool_name`, `type`),
	FOREIGN KEY (`mcp_tool_name`) REFERENCES `mcp_tool`(`name`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `mcp_tool` (
	`created_at` integer DEFAULT (unixepoch()) NOT NULL,
	`description` text NOT NULL,
	`last_used` integer DEFAULT (unixepoch()) NOT NULL,
	`name` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL
);
