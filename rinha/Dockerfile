FROM erlang:alpine AS build

RUN mkdir /app
WORKDIR /app

COPY config config/
##COPY bin bin/
COPY apps apps/
COPY rebar.config .

RUN rebar3 release
##RUN ./bin/mkimage

FROM alpine

RUN apk add --no-cache openssl && \
    apk add --no-cache ncurses-libs && \
     apk add --no-cache libstdc++ && \
      apk add --no-cache libgcc

COPY --from=build /app/_build/default/rel/rinha /rel

CMD ["/rel/bin/rinha", "foreground"]
