-module(chat_message).
-include_lib("chat/include/CHAT.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("kvs/include/kvs.hrl").
-export([start/0,info/3]).

-define(MSG_EDIT_ACTION, <<"message_edit">>).
-define(MSG_DELETE_ACTION, <<"message_delete">>).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = "Message Service", state = []}).

info(#'Typing'{nickname = Phone, comments = Comments}, Req, #cx{} = State) -> {reply, {bert, <<>>}, Req, State};
info(#'Message'{id=MsgID, status=Status} = M, Req, #cx{state=[]}=State) when MsgID /= [], Status/=update-> {reply, {bert, #'Ack'{id=MsgID}}, Req, State};
info(#'Message'{status = [], id = [], feed = F, from=From0, to = To, type = Type, files = [#'FileDesc'{payload = Payload} | _] = Descs} = Msg, Req, #cx{client_pid = C, params = ClientId, state=ack} = State) -> {reply, {bert, #'IO'{}}, Req, State};
info(#'Message'{status = edit, id = Id, feed = Feed, from = From, to = To, mentioned = Mentioned, files = [#'FileDesc'{payload = Payload} | _] = Descs}, Req, #cx{params = ClientId, client_pid = C, state=ack} = State) -> {reply, {bert, #'IO'{}}, Req, State};
info(#'Message'{id = Id, feed = Feed, from = From0, seenby = Seen, status = delete}, Req, #cx{params = ClientId, client_pid = C, state=ack} = State) when is_integer(Id) -> {reply, {bert,#'IO'{}}, Req, State};
info(#'Message'{from = From, to = To} = ReqData, Req, State) -> {reply, {bert, #'IO'{code = #'ERROR'{code = invalid_data}}}, Req, State}.

