PROJECT = api
PROJECT_DESCRIPTION = Erlang - Rinha de Backend
PROJECT_VERSION = 0.1.0

DEPS = cowboy
dep_cowboy_commit = 2.11.0

REL_DEPS = relx

DEP_PLUGINS = cowboy

include erlang.mk
