# Erlang - Rinha de Backend 2024

## fabiokleis
submissão feita com:
- nginx como load balancer
- postgres como banco de dados
- erlang para api com as libs cowboy e pgo
- [repositório da api](https://github.com/fabiokleis/rinha-de-backend-2024)


[@fabiokleis](https://twitter.com/FabioKleis) @ twitter

## Build
```shell
rebar3 release
```

```shell
rebar3 shell
```

## Deploy
```shell
docker build -t fishingboo/erlang-rinher-api:latest . &&
docker push fishingboo/erlang-rinher-api:latest
```
```shell
docker-compose up 
```
```shell
docker-compose down
```

