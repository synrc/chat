-module(roster_roster).
-include("roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-compile(export_all).

-define(MAX_NAME_LENGTH, 32).
-define(MIN_NAME_LENGTH, 2).
-define(MIN_SURNAME_LENGTH, 1).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"Roster Service">>, state = []}).

info(#'Roster'{status = patch, avatar = Avatar} = Data, Req, #cx{params = ClientId, client_pid = C, state = #'Roster'{id = RosterId0, phone = Phone, avatar = OldAvatar, roomlist = Rooms, status = Status} = State) -> {reply, {bert, #io{}}, Req, State#cx{state = []}};
info(#'Roster'{id = RosterId0, status = patch, names = Names, surnames = Surnames, avatar = Avatar} = Data, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State#cx{state = []}};
info(#'Roster'{id = RosterId, nick = NickToBeValidated, status = nick} = Data, Req, #cx{params = ClientId, client_pid = C} = State) -> {reply, {bert, #io{}}, Req, State#cx{state = []}};
info(#'Roster'{id=RosterId, status=get},Req, #cx{params = ClientId }=State) -> {reply, {bert, #io{}}, Req, State#cx{state = []}};
info(#'Roster'{id = RosterId, userlist = List, status = del}, Req, #cx{params = ClientId, session = Token} = State) -> {reply, {bert, #io{}}, Req, State#cx{state = []}};
info(#'Roster'{id = RosterId, userlist = RosterList, status = add}, Req, #cx{params = ClientId, session = Token} = State) -> {reply, {bert, #io{}}, Req, State#cx{state = []}};
info(#'Roster'{phone = Phone, status = list}, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State#cx{state = []}};
info(#'Roster'{id = RosterId, status = Status}, Req, #cx{params = ClientId} = State) -> {reply, {bert, #io{}}, Req, State#cx{state = []}}.

proc(init, #pi{name = ?MODULE} = Async) -> {ok, Async};
proc({update_ac, #'Contact'{phone_id = PhoneId} = C}, #pi{} = H) -> {reply, [], H};
proc({update_index, #'Roster'{id = RosterId, nick = Nick}}, #pi{} = H) -> {reply, [], H};
proc({delete_index, #'Roster'{id = RosterId, nick = Nick}}, #pi{} = H) -> {reply, [], H}.