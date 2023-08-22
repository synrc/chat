-module(chat_history).
-include_lib("chat/include/CHAT.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("kvs/include/kvs.hrl").
-export([start/0,info/3]).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"History Service">>, state = []}).

info(#'History'{status = get_reply, entity = Id} = History, Req, #cx{params = ClientId} = State) when Id /= [] -> {reply, {bert, History#'History'{data = []}}, Req, State};
info(#'History'{status = get} = History, Req, #cx{state = []} = State) -> info(History, Req, State#cx{state = {status, get}});
info(#'History'{status = get, data = [#'Message'{feed = Feed}|_]} = History, Req, State) when Feed /= []-> info(History#'History'{feed = Feed}, Req, State);
info(#'History'{status = get, roster = Roster0, feed = Feed, size = N, entity = MId, data = MsgData} = History, Req, #cx{params = ClientId, state = {status, InitialStatus}} = State) -> {reply, {bert, #'IO'{}}, Req, State};
info(#'History'{status = update, feed = Feed, entity = MId}, Req, #cx{client_pid = C, params = ClientId, state = verified} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{state = []}};
info(#'History'{status = update, entity = MId} = History, Req, #cx{} = State) when MId == 0; MId == []->  info(History, Req, State#cx{state = verified});
info(#'History'{status = delete, feed = Feed}, Req, #cx{client_pid = C, params = ClientId} = State) -> {reply, {bert, #'IO'{}}, Req, State};
info(#'History'{roster = RosterId, size = N, status = get} = Data, Req, #cx{params = ClientId} = State) -> {reply, {bert, Data#'History'{data = []}}, Req, State};
info(#'History'{} = Data, Req, State) -> {reply, {bert, <<>>}, Req, State}.


