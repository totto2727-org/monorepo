-- Create "user" table
CREATE TABLE `user` (
  `id` text NOT NULL,
  `name` text NOT NULL,
  `email` text NOT NULL,
  `email_verified` integer NOT NULL,
  `image` text NULL,
  `created_at` text NOT NULL,
  `updated_at` text NOT NULL,
  PRIMARY KEY (`id`)
);
-- Create "session" table
CREATE TABLE `session` (
  `id` text NOT NULL,
  `user_id` text NOT NULL,
  `token` text NOT NULL,
  `expires_at` text NOT NULL,
  `ip_address` text NULL,
  `user_agent` text NULL,
  `created_at` text NOT NULL,
  `updated_at` text NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `session_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
);
-- Create "account" table
CREATE TABLE `account` (
  `id` text NOT NULL,
  `user_id` text NOT NULL,
  `account_id` text NOT NULL,
  `provider_id` text NOT NULL,
  `access_token` text NULL,
  `refresh_token` text NULL,
  `access_token_expires_at` text NULL,
  `refresh_token_expires_at` text NULL,
  `scope` text NULL,
  `id_token` text NULL,
  `password` text NULL,
  `created_at` text NOT NULL,
  `updated_at` text NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `account_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
);
-- Create "verification" table
CREATE TABLE `verification` (
  `id` text NOT NULL,
  `identifier` text NOT NULL,
  `value` text NOT NULL,
  `expires_at` text NOT NULL,
  `created_at` text NOT NULL,
  `updated_at` text NOT NULL,
  PRIMARY KEY (`id`)
);
-- Create "passkey" table
CREATE TABLE `passkey` (
  `id` text NOT NULL,
  `name` text NULL,
  `public_key` text NOT NULL,
  `user_id` text NOT NULL,
  `credential_i_d` text NOT NULL,
  `counter` integer NOT NULL,
  `device_type` text NOT NULL,
  `backed_up` integer NOT NULL,
  `transports` text NULL,
  `aaguid` text NULL,
  `created_at` text NOT NULL,
  `updated_at` text NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `passkey_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
);
-- Create "jwks" table
CREATE TABLE `jwks` (
  `id` text NOT NULL,
  `public_key` text NOT NULL,
  `private_key` text NOT NULL,
  `created_at` text NOT NULL,
  PRIMARY KEY (`id`)
);
-- Create "oauth_application" table
CREATE TABLE `oauth_application` (
  `id` text NOT NULL,
  `name` text NOT NULL,
  `client_id` text NOT NULL,
  `client_secret` text NOT NULL,
  `redirect_uris` text NOT NULL,
  `user_id` text NOT NULL,
  `created_at` text NOT NULL,
  `updated_at` text NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `oauth_application_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
);
-- Create "oauth_access_token" table
CREATE TABLE `oauth_access_token` (
  `id` text NOT NULL,
  `access_token` text NOT NULL,
  `refresh_token` text NULL,
  `client_id` text NOT NULL,
  `user_id` text NOT NULL,
  `scope` text NULL,
  `expires_at` text NOT NULL,
  `created_at` text NOT NULL,
  `updated_at` text NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `oauth_access_token_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
);
-- Create "oauth_consent" table
CREATE TABLE `oauth_consent` (
  `id` text NOT NULL,
  `user_id` text NOT NULL,
  `client_id` text NOT NULL,
  `scope` text NULL,
  `created_at` text NOT NULL,
  `updated_at` text NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `oauth_consent_user_id_fk` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
);
