-module(chat_profile).
-include_lib("chat/include/CHAT.hrl").
-include_lib("n2o/include/n2o.hrl").
-export([start/0,info/3, proc/2]).

start() -> n2o_pi:start(#pi{module=?MODULE, table=system, sup=roster, name= <<"Profile Service">>,state=[]}).

info(#'Profile'{status=patch} = Data, Req, #cx{params = ClientId} = State) -> {reply, {bert, #'IO'{}}, Req, State};
info(#'Profile'{status = delete, roster = Roster}=Data, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #'IO'{}}, Req, State};
info(#'Profile'{status = remove}, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #'IO'{}}, Req, State};
info(#'Profile'{status = get, update = LastSync, settings = Settings}, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #'IO'{}}, Req, State};
info(#'Profile'{status = init} = Data, Req, State) -> {reply, {bert, Data}, Req, State};
info(#'Profile'{} = Data, Req, State) -> {reply, {bert, Data}, Req, State}.

proc(init,#pi{name=?MODULE} = Async) -> {ok,Async};
proc({restart, M}, #pi{state = {C, Proc}} = H) -> {reply, [], H}.
