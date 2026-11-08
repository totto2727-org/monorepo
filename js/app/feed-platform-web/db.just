default:
    @just --list db

schema-apply:
    mkdir -p ./node_modules/.cache/
    atlas schema apply --env local
    vp run setup:kysely

reset:
    rm ./node_modules/.cache/db

dev: schema-apply
    turso dev -f ./node_modules/.cache/db --port 8081
