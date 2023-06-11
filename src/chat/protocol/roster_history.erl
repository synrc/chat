-module(roster_history).
-include_lib("chat/include/roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("kvs/include/kvs.hrl").
-compile(export_all).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"History Service">>, state = []}).

info(#'History'{roster_id = RosterId, feed = #'StickerPack'{} = Feed, size = N, status = get} = Data, Req, #cx{params = ClientId} = State) -> {reply, {bert, Data#'History'{data = []}, Req, State};
info(#'History'{status = get_reply, entity_id = Id} = History, Req, #cx{params = ClientId} = State) when Id /= [] -> {reply, {bert, History#'History'{data = []}}, Req, State};
info(#'History'{status = double_get, feed = Feed, size = N, entity_id = MId, data = []} = History, Req, #cx{} = State) when N > 0, MId > 0 -> {reply, {bert, History#'History'{data = [], size = 0}}, Req, State};
info(#'History'{status = get} = History, Req, #cx{state = []} = State) -> info(History, Req, State#cx{state = {status, get}});
info(#'History'{status = get, data = [#'Message'{feed_id = Feed}|_]} = History, Req, State) when Feed /= []-> info(History#'History'{feed = Feed}, Req, State);
info(#'History'{status = get, roster_id = Roster0, feed = Feed, size = N, entity_id = MId, data = MsgData} = History, Req, #cx{params = ClientId, state = {status, InitialStatus}} = State) -> {reply, {bert, IO}, Req, State};
info(#'History'{status = update, feed = Feed, entity_id = MId}, Req, #cx{client_pid = C, params = ClientId, state = verified} = State) -> {reply, {bert, D}, Req, State#cx{state = []}};
info(#'History'{status = update, entity_id = MId} = History, Req, #cx{} = State) when MId == 0; MId == []->  info(History, Req, State#cx{state = verified});
info(#'History'{feed = Feed, status = delete}, Req, #cx{client_pid = C, params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State};
info(#'History'{} = Data, Req, State) -> {reply, {bert, <<>>}, Req, State}.


