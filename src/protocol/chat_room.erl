-module(chat_room).
-include_lib("chat/include/CHAT.hrl").
-include_lib("n2o/include/n2o.hrl").
-export([start/0, info/3, proc/2]).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"Roster Service">>, state = []}).

info(#'Member'{status = patch, id = Id}, Req, #cx{params = _ClientId, from = _From} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Member'{}, Req, #cx{params = ClientId} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};

info(#'Room'{status = create, id = Room, admins = [Admin|_], type=Type}, Req, #cx{state = verified} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Room'{status = patch, id = Room, name = _Name, data = _Avatar}, Req, #cx{params = _ClientId, client_pid = _PID} = State) when Room /= [] -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Room'{status = remove, members = _Members, admins = _Admins, id = _Room}, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Room'{status = delete, members = [], admins = [], id = Room} = R, Req, #cx{params = <<"sys_", _/binary>> = ClientId, client_pid = C} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Room'{status = leave, id = Room}, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Room'{status = get, id = Room}, Req, #cx{params = ClientId} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Room'{status = MuteUnmute, id = Room}, Req, #cx{params = ClientId, client_pid = C} = State) when MuteUnmute == mute;MuteUnmute == unmute -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Room'{status = AddJoin, id=R, members=M, admins=A}, Req, #cx{params=C, client_pid=C, state=RS} = State) when (AddJoin==add orelse(AddJoin==join andalso RS/=create))andalso(M/=[]orelse A/=[]) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}};
info(#'Room'{} = Room, Req, #cx{params = ClientId} = State) -> {reply, {bert, #'IO'{}}, Req, State#cx{from = []}}.

proc(init, #pi{name = roster_room} = Async) -> {ok, Async};
proc({send_push, NewMembers, Msg, Type}, #pi{} = H) -> {reply, [], H}.

