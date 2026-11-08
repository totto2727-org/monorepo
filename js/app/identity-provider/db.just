default:
    @just --list db

schema-apply:
    mkdir -p ./node_modules/.cache/
    atlas schema apply --env local
    vp run setup:kysely

reset:
    rm ./node_modules/.cache/db

dev: schema-apply
    turso dev -f ./node_modules/.cache/db --port 8080

migrate-apply: reset
    atlas migrate apply --env local

migrate-diff: migrate-apply
    atlas migrate diff --env local

seed-oauth: schema-apply
    echo "Seeding OAuth application..."
    sqlite3 ./node_modules/.cache/db < ./db/seeds/oauth_application.sql
