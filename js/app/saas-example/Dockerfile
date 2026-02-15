# syntax=docker/dockerfile:1.7-labs

FROM oven/bun:1 as builder

WORKDIR /usr/src/app

ENV NODE_ENV=production

COPY --parents **/bunfig.toml ./
COPY --parents **/package.json ./
COPY --parents **/bun.lock ./
RUN bun i --frozen-lockfile --ignore-scripts

COPY . ./
RUN ls -al
RUN bun turbo build --filter @app/saas-example

FROM oven/bun:1-slim

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/js/app/saas-example/build .

ENV NODE_ENV=production

EXPOSE 3000
ENTRYPOINT ["bun", "run", "main.js"]
