-module(chat_search).
-include_lib("chat/include/chat.hrl").
-include_lib("n2o/include/n2o.hrl").
-export([start/0, info/3, proc/2]).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"Search Protocol">>, state = []}).

info(#'Search'{id = FromRosterId, field = <<"link">>, type = '==', value = SearchVal, status = room}, Req, #cx{params = <<"emqttd_",_/binary>> = ClientId} = State) -> {reply, {bert, #io{}}, Req, State};
info(#'Search'{id = From, field = <<"nick">>, type = '==', value = Q, status = contact}, Req, #cx{params = <<"emqttd_", _/binary>> = ClientId} = State) -> {reply, {bert, #io{}}, Req, State};
info(#'Search'{id = From, field = <<"phone">>, type = '==', value = Phones, status = contact}, Req, #cx{params = <<"emqttd_", _/binary>> = ClientId} = State) -> {reply, {bert, #io{}}, Req, State};
info(#'Search'{} = Data, Req, State) -> {reply, {bert, #io{}}, Req, State}.

proc(init, #pi{name = roster_search} = Async) -> {ok, Async}.
