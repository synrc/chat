-module(roster_presence).
-include("roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("rest_static.hrl").
-compile(export_all).

info(#'Presence'{uid=UID, status=Status} = RequestData, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, send_presence(Status, roster:phone_id(ClientId), C)}, Req, State};
info(#'Presence'{} = RequestData, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{code = #error{code = invalid_data}}}, Req, State}.

