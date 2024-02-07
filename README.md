# Erlang - Rinha de Backend 2024

## fabiokleis
submissão feita com:
- nginx como load balancer
- postgres como banco de dados
- erlang para api com as libs cowboy e epgsql
- [repositório da api](https://github.com/fabiokleis/rinha-de-backend-2024)


[@fabiokleis](https://twitter.com/FabioKleis) @ twitter


Embrace the power and simplicity of Makefiles.
## Build
```shell
make rebar.config
```
```shell
rebar3 release
```

```shell
rebar3 shell
```
To add a new request function handler
```shell
make new t=cowboy.http n=function_handler_name SP=4
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

