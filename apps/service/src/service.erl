-module(service).
-behaviour(application).
-export([start/2, stop/1, init/1]).
-compile(export_all).

init([]) -> {ok, {{one_for_one, 5, 10}, []}}.
start(_,_) -> supervisor:start_link({local,?MODULE},?MODULE, []).
stop(_) -> ok.

