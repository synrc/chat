-module(roster_room).
-include_lib("chat/include/roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("roster/include/static/roster_text.hrl").
-compile(export_all).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"Roster Service">>, state = []}).

info(#'Member'{status = patch, id = Id} = Member, Req, #cx{params = ClientId, from = From} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Member'{} = Member, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = create, id = Room, admins = [Admin|_], type=Type} = R, Req, #cx{state = verified} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = create, id = <<Room/binary>>, name = Name, admins = [Owner|TA]= Admins, members = Members, data = Data} = R, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = patch, id = Room, name = Name, data = AvatarDesc} = R, Req, #cx{params = ClientId, client_pid = C} = State) when Room /= [] -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = remove, members = Members, admins = Admins0, id = Room}, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = delete, members = [], admins = [], id = Room} = R, Req, #cx{params = <<"sys_", _/binary>> = ClientId, client_pid = C} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = leave, id = Room}, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = get, id = Room}, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = Mute, id = Room}, Req, #cx{params = ClientId, client_pid = C} = State) when Mute == mute;Mute == unmute -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{} = Room, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};
info(#'Room'{status = S, id=R, members=M, admins=A}, Q, #cx{params=C, client_pid=C, state=RS} = X) when (S==add orelse(S==join andalso RS/=create))andalso(M/=[]orelse A/=[]) -> {reply, {bert, #io{}}, Req, State#cx{from = Topic}};

proc(init, #pi{name = roster_room} = Async) -> {ok, Async};
proc({send_push, NewMembers, Msg, Type}, #pi{} = H) -> {reply, [], H}.

