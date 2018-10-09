FROM elixir:1.7.3-alpine as builder

ARG APP_NAME=k8s_phoenix
ARG PHOENIX_SUBDIR=.
ENV MIX_ENV=prod REPLACE_OS_VARS=true TERM=xterm

WORKDIR /opt/app

RUN mix local.rebar --force && \
    mix local.hex --force

COPY . .

RUN mix do deps.get, deps.compile, compile
RUN mix release --env=prod --verbose \
    && mv _build/prod/rel/${APP_NAME} /opt/release \
    && mv /opt/release/bin/${APP_NAME} /opt/release/bin/start_server

FROM alpine:latest

RUN apk update && apk --no-cache --update add bash openssl-dev
ENV PORT=4000 MIX_ENV=prod REPLACE_OS_VARS=true

WORKDIR /opt/app
EXPOSE ${PORT}

COPY --from=builder /opt/release .
CMD ["/opt/app/bin/start_server", "foreground"]
