-module(roster_presence).
-include_lib("chat/include/roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-export([info/3]).

info(#'Presence'{uid=UID, status=Status} = RequestData, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, ?MODULE:send_presence(Status, chat:phone_id(ClientId), C)}, Req, State};
info(#'Presence'{} = RequestData, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{code = #error{code = invalid_data}}}, Req, State}.

