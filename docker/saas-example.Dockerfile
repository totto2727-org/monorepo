FROM jetpackio/devbox:latest AS devbox

WORKDIR /code

USER root:root
RUN mkdir -p /code && chown ${DEVBOX_USER}:${DEVBOX_USER} /code

USER ${DEVBOX_USER}:${DEVBOX_USER}
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.json devbox.json
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.lock devbox.lock

RUN devbox run -- echo "Installed Packages."

RUN nix-store --gc
#RUN nix-store --optimise

FROM devbox AS builder

ENV NODE_ENV=production

COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} --parents **/bunfig.toml /code/
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} --parents **/package.json /code/
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} --parents **/bun.lock /code/
RUN devbox run -- bun i --frozen-lockfile --ignore-scripts

COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} . /code/
RUN devbox run -- bun turbo build --filter @app/saas-example

FROM oven/bun:1-slim

WORKDIR /usr/src/app
COPY --from=builder /code/js/app/saas-example/build ./

ENTRYPOINT ["bun", "run", "main.js"]
