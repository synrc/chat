-module(roster_link).
-include_lib("chat/include/roster.hrl").
-include_lib("n2o/include/n2o.hrl").

-compile(export_all).

info(#'Link'{id = LinkId, type = group, status = join = LStatus} = RequestData, Req, #cx{params = ClientId, client_pid = C} = State) when LinkId /= [] -> {bert, #io{}}, Req, State};
info(#'Link'{id = LinkId, status = get = LStatus} = RequestData, Req, #cx{params = ClientId} = State) when LinkId /= [] -> {reply, {bert, #io{}}, Req, State};
info(#'Link'{id = LinkId, room_id = RoomId, type = Type, status = update = LStatus} = RequestData, Req, #cx{params = ClientId} = State) when RoomId /= [], LinkId /= [] -> {reply, {bert, #io{}}, Req, State};
info(#'Link'{type = group, status = delete = LStatus} = RequestData, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State};
info(#'Link'{} = RequestData, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State}.


