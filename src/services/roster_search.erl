-module(roster_search).
-include_lib("chat/include/roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-export([start/0, info/3, proc/2]).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"Search Protocol">>, state = []}).

info(#'Search'{id = FromRosterId, ref = Ref, field = <<"link">>, type = '==', value = SearchVal, status = room}, Req, #cx{params = <<"emqttd_",_/binary>> = ClientId} = State) -> {reply, {bert, #io{}}, Req, State};
info(#'Search'{id = From, ref = Ref, field = <<"nick">>, type = '==', value = Q, status = contact}, Req, #cx{params = <<"emqttd_", _/binary>> = ClientId} = State) when Ref /=[] -> {reply, {bert, #io{}}, Req, State};
info(#'Search'{id = From, ref = Ref, field = <<"phone">>, type = '==', value = Phones, status = contact}, Req, #cx{params = <<"emqttd_", _/binary>> = ClientId} = State) when is_list(Phones), Ref /=[] -> {reply, {bert, #io{}}, Req, State};
info(#'Search'{} = Data, Req, State) -> {reply, {bert, #io{}}, Req, State}.

proc(init, #pi{name = roster_search} = Async) -> {ok, Async}.
