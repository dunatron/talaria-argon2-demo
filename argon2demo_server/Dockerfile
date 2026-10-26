# Build from the project root with:
#   docker build -f argon2demo_server/Dockerfile .
#
# MUST use `dart build cli` so serverpod_argon2 native assets are included.

FROM dart:3.12.2 AS build

WORKDIR /app
COPY pubspec.lock .
COPY argon2demo_server argon2demo_server
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.12.2' \
  'workspace:' \
  '  - argon2demo_server' \
  > pubspec.yaml
RUN dart pub get

WORKDIR /app/argon2demo_server
RUN dart build cli --target bin/main.dart --output build
RUN mv build/bundle/bin/main build/bundle/bin/server
RUN mkdir -p config web

FROM alpine:latest
WORKDIR /app

ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

COPY --from=build /runtime/ /
COPY --from=build /app/argon2demo_server/build/bundle/ ./
COPY --from=build /app/argon2demo_server/config/ config/
COPY --from=build /app/argon2demo_server/web/ web/
COPY --from=build /app/argon2demo_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

EXPOSE 8180
EXPOSE 8181
EXPOSE 8182

ENTRYPOINT ./bin/server --mode=$runmode --server-id=$serverid --logging=$logging --role=$role
