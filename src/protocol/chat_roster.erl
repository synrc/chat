-module(chat_roster).
-include_lib("chat/include/CHAT.hrl").
-include_lib("n2o/include/n2o.hrl").
-export([start/0, info/3, proc/2]).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"Roster Service">>, state = []}).

info(#'Roster'{status = list}, Req, #cx{params = ClientId} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{state = []}};
info(#'Roster'{status = add, id = RosterId, contacts = RosterList}, Req, #cx{params = ClientId, session = Token} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{state = []}};
info(#'Roster'{status = del, id = RosterId}, Req, #cx{params = ClientId, session = Token} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{state = []}};
info(#'Roster'{status = patch, id = RosterId0}, Req, #cx{params = ClientId} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{state = []}};
info(#'Roster'{status = nicknameid, id = RosterId, nickname = nicknameToBeValidated}, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{state = []}};
info(#'Roster'{status = get, id = RosterId}, Req, #cx{params = ClientId } = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{state = []}};
info(#'Roster'{status = Status, id = RosterId}, Req, #cx{params = ClientId} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{state = []}}.

proc(init, #pi{name = ?MODULE} = Async) -> {ok, Async};
proc({update_contact, #'Contact'{phone = PhoneId}}, #pi{} = H) -> {reply, [], H};
proc({update_roster, #'Roster'{id = RosterId, nickname = nickname}}, #pi{} = H) -> {reply, [], H};
proc({delete_roster, #'Roster'{id = RosterId, nickname = nickname}}, #pi{} = H) -> {reply, [], H}.
