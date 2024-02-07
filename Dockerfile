FROM erlang:alpine AS build

RUN mkdir /app
WORKDIR /app

COPY config config/
##COPY bin bin/
COPY src src/
COPY rebar.config .

RUN rebar3 release
##RUN ./bin/mkimage

FROM alpine

RUN apk add --no-cache openssl && \
    apk add --no-cache ncurses-libs && \
     apk add --no-cache libstdc++ && \
      apk add --no-cache libgcc

COPY --from=build /app/_build/default/rel/erlang_rinher_api /rel

CMD ["/rel/bin/erlang_rinher_api", "foreground"]
