-- Dev seed: OAuth client for feed-platform-web + a dev user (FK requirement).
-- Idempotent: updates existing local rows so repeated runs repair stale dev values.

-- 1) Dev user (required by oauth_application.user_id FK)
INSERT OR IGNORE INTO `user` (`id`, `name`, `email`, `email_verified`, `image`, `created_at`, `updated_at`)
VALUES ('dev-user-id', 'Dev User', 'dev@example.com', 1, NULL, datetime('now'), datetime('now'));

-- 2) OAuth client for feed-platform-web
INSERT INTO `oauth_application` (`id`, `name`, `client_id`, `client_secret`, `skip_consent`, `redirect_uris`, `user_id`, `created_at`, `updated_at`)
VALUES (
  'oauth-client-feed-platform-web',
  'Feed Platform Web',
  'feed-platform-web',
  'dev-secret-do-not-use-in-prod',
  1,
  '["http://127.0.0.1:8789/api/v1/auth/oauth2/callback/identity-provider"]',
  'dev-user-id',
  datetime('now'),
  datetime('now')
)
ON CONFLICT(`id`) DO UPDATE SET
  `name` = excluded.`name`,
  `client_id` = excluded.`client_id`,
  `client_secret` = excluded.`client_secret`,
  `skip_consent` = excluded.`skip_consent`,
  `redirect_uris` = excluded.`redirect_uris`,
  `user_id` = excluded.`user_id`,
  `updated_at` = excluded.`updated_at`;
