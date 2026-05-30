-- Dev seed: OAuth client for feed-platform-web + a dev user (FK requirement).
-- Idempotent: uses INSERT OR IGNORE so repeated runs are safe.

-- 1) Dev user (required by oauth_application.user_id FK)
INSERT OR IGNORE INTO `user` (`id`, `name`, `email`, `email_verified`, `image`, `created_at`, `updated_at`)
VALUES ('dev-user-id', 'Dev User', 'dev@example.com', 1, NULL, datetime('now'), datetime('now'));

-- 2) OAuth client for feed-platform-web
INSERT OR IGNORE INTO `oauth_application` (`id`, `name`, `client_id`, `client_secret`, `redirect_uris`, `user_id`, `created_at`, `updated_at`)
VALUES (
  'oauth-client-feed-platform-web',
  'Feed Platform Web',
  'feed-platform-web',
  'dev-secret-do-not-use-in-prod',
  '["http://localhost:8788/auth/callback"]',
  'dev-user-id',
  datetime('now'),
  datetime('now')
);
