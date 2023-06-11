-module(roster_client).
-compile(export_all).
-include_lib("n2o/include/n2o.hrl").
-include_lib("emqttc/include/emqttc_packet.hrl").
-include("roster.hrl").
-include("roster_test.hrl").

-record(mqttc, {client :: pid(), status :: connected}).

set_config(Key, Val) -> application:set_env(?MODULE, Key, Val).
get_config(Key, Default) -> application:get_env(?MODULE, Key, Default).

start_client(ClientId) -> start_client(ClientId, <<>>, [{host, ?HOST}]).
start_client(ClientId, Token) -> start_client(ClientId, Token, [{host, ?HOST}]).
start_client(ClientId, Token, Opts) ->
	receive_drop(),
	stop_client(ClientId),
	Username = proplists:get_value(username, Opts, <<"api">>),
	n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster,
		state = #state{mqtt_opts = [{password, Token}|Opts ++ ?DEFAULT_MQTTC_OPTS], username = Username,
		receive_pid = self()}, name = ClientId}),
	init = receive_test(ClientId, init), ok.

start_cli_receive(ClientId, Token)  -> start_cli_receive(ClientId, Token, 0).
start_cli_receive(ClientId, Token, Counter) -> start_cli_receive(ClientId, Token, Counter, [{host, ?HOST}]).
start_cli_receive(ClientId, Token, Counter, Opts) -> start_client(ClientId, Token, Opts),
	case ?CVERSION of
		<<"version/10">> -> receive_test(ClientId, #'Auth'{}, Counter);
		_ -> send_receive(ClientId, Counter+1, #'Profile'{status = get})
	end.

stop_client(ClientIds) when is_list(ClientIds) -> [stop_client(ClientId) || ClientId <- ClientIds], ok;
stop_client(ClientId) ->
	case n2o_pi:pid(system, ClientId) of
		Pid when is_pid(Pid) ->
			case process_info(Pid) of
				undefined ->
					catch [supervisor:F(roster, {system, ClientId}) || F <- [terminate_child, delete_child]],
					n2o:cache(system, {system, ClientId}, undefined), ok;
				_ -> n2o_pi:stop(system, ClientId), ok end; _ -> ok end.

receive_drop() -> receive _ -> receive_drop() after ?DRP_TMOUT -> skip end.

filter(Term, _) ->
	case Term of
		{send_push, _, _, _} -> skip;
		#'Message'{type = [sys | _], status = [], files = Files} = _Msg ->
			roster:info(?MODULE, "system:~p", [case Files of [] -> []; _ ->
				(hd(Files))#'Desc'.payload end]); %% ignore muc system messages
		#'Contact'{presence = Presence} when Presence == online; Presence == offline -> skip; %% ignore Contact presence
		#'Contact'{status = internal} -> skip; %% ignore Contact presence
		#'Member'{presence = Presence, status = Status}
			when Status /= patch andalso (Presence == online orelse Presence == offline) ->
			skip; %% ignore Member presence
		_ -> % roster:info("Term value: ~p", [Term]),
			send end.
filter_friend(Term, State) ->
	case {Term, filter(Term, State)} of
		{#'Contact'{status = Status}, skip} when Status == request;Status == authorization;Status == ignore;
			Status == ban;Status == unban;Status == banned;Status == friend;Status == update -> send;
		{_, Res} -> Res end.

proc(#mqttc{}, #pi{} = H)	-> {reply, [], H};
proc(init, #pi{name = ?SYS_REST_CLIENT, state = #state{receive_pid = Self} = State} = Async) ->
	{ok, C} = application:get_env(rest, rest_pid),
	Self ! init,
	{ok, Async#pi{state = State#state{mqttc = C, client_id = ?SYS_REST_CLIENT}}};
proc(init, #pi{name = ?SYS_BRIDGE_TEST_CLIENT, state = #state{receive_pid = Self} = State} = Async) ->
	{ok, C} = emqttc:start_link([{client_id, ?SYS_BRIDGE_TEST_CLIENT}, {logger, {console, error}}, {reconnect, 5}]),
	roster:info(?MODULE, "MICRO BRIDGE SIMULATOR PROC started", []),
	register(sys_bridge, C),
	Self ! init,
	{ok, Async#pi{state = State#state{mqttc = whereis(sys_bridge), client_id = ?SYS_BRIDGE_TEST_CLIENT}}};
proc(init, #pi{name = ClientId, state = #state{mqtt_opts = Opts, receive_pid = Self, username = Username} = State} = Async) ->
	roster:info(?MODULE, "ClientInit:~p\r", [ClientId]),
	{ok, C} = emqttc:start_link([{client_id, ClientId},
		{clean_sess, false}, {logger, {console, error}},
		{username, Username}, {reconnect, 5}] ++ Opts),
	Self ! init,
	{ok, Async#pi{state = State#state{mqttc = C, client_id = ClientId}}};

proc({filter, Filter}, #pi{state = #state{receive_pid = Self} = State} = H) ->
	Self ! ok,
	{reply, [], H#pi{state = State#state{filter = Filter}}};

proc(last_res, #pi{state = #state{receive_pid = Self, last_res = LastRes} = State} = H) ->
	Self ! lists:ukeysort(1, LastRes),
	{reply, [], H#pi{state = State#state{last_res = []}}};
proc(unsort_last_res, #pi{state = #state{receive_pid = Self, last_res = LastRes} = State} = H) ->
	Self ! LastRes,
	{reply, [], H#pi{state = State#state{last_res = []}}};
proc({publish, _, BinTerm}, #pi{state = #state{receive_pid = Self, last_res = LastRes, filter = FilterFun} = State} = H) ->
	case ?MODULE:FilterFun(Term = binary_to_term(BinTerm), State) of
		send ->
			write_log([Term]),
			Self ! Term; _ -> skip end,
	{reply, [], H#pi{state = State#state{last_res = [Term | LastRes]}}};
proc(_Term, #pi{state = #state{mqttc = {error, _} = Err}} = H) ->
	roster:info("mqttc error: ~p", [Err]),
	{reply, [], H};
proc({callback, CallbackFun}, #pi{state = State} = H) ->
	State2 = CallbackFun(State),
	{reply, [], H#pi{state = State2}};
proc(Term, #pi{state = #state{mqttc = C}} = H)	->
	roster:send_event(C, <<>>, <<>>, Term),
	{reply, [], H}.

stop_vnodes() when ?HOST == ?LOC -> roster:stop_vnodes(), timer:sleep(1000);
stop_vnodes() -> skip.
start_vnodes() when ?HOST == ?LOC -> roster:start_vnodes(), timer:sleep(1000);
start_vnodes() -> skip.

gen_name(Name) -> gen_name(Name, iolist_to_binary(["DevKey_", Name])).
gen_name(Name, DevKey) -> gen_name(Name, DevKey, "emqttd_").
gen_name_reg(Name) -> gen_name_reg(Name, iolist_to_binary(["DevKey_", Name])).
gen_name_reg(Name, DevKey) -> gen_name(Name, DevKey, "reg_").
gen_name(Name, DevKey, Prefix) -> iolist_to_binary([Prefix, Name, "_", DevKey]).
gen_anylist(N) -> gen_anylist(N, <<"DevKey">>).
gen_anylist(N, Prefix) -> [iolist_to_binary([Prefix, integer_to_binary(D)]) || D <- lists:seq(1, N)].

rosters(_ClientId, Phone) ->
	{ok, #'Profile'{rosters = RosterIds}} = kvs:get('Profile', Phone),
	[roster:phone_id(Phone, Id) || Id <- RosterIds].
rosters(#'Profile'{rosters = Rosters, phone = Phone}) ->
	[roster:phone_id(Phone, Id) || #'Roster'{id = Id} <- Rosters].

reg_fake_user(Phone) -> reg_fake_user(Phone, <<"DevKey_", Phone/binary>>, 1000, []).
reg_fake_user(Phone, DevKey) -> reg_fake_user(Phone, DevKey, 1000).
reg_fake_user(Phone, DevKey, Sleep) -> reg_fake_user(Phone, DevKey, Sleep, []).
reg_fake_user(Phone, DevKey, Sleep, Opts) ->
	reg_fake_user(Phone, DevKey, Sleep, Opts,
		[#'Feature'{id = <<Phone/binary, "_", DevKey/binary, "_", ?DEFAULT_LANGUAGE_KEY/binary>>, key = ?DEFAULT_LANGUAGE_KEY, value = <<"English:en">>, group = ?LANG_KEY}]).
reg_fake_user(Phone, DevKey, Sleep, Opts, Features) ->
	RegClientId = gen_name_reg(Phone, DevKey),
	receive_drop(),
	stop_client(RegClientId),
	start_client(RegClientId, <<>>, Opts),
	#io{code = #ok2{src = {ClientId, Token}}} =
		send_receive(RegClientId, #'Auth'{type = reg, dev_key = DevKey, sms_code = <<"12">>, phone = {fake, Phone}, settings = Features}),
	stop_client(RegClientId), timer:sleep(Sleep), %% wait for Persona put
	receive_drop(), {ClientId, Token}.

client_ids(Phone) -> [ClientId || #'Auth'{client_id = ClientId} <- kvs:index('Auth', user_id, roster:phone_id(Phone))].
client_id(Phone) -> hd(client_ids(Phone)).

test_info(Module, Term, #cx{} = State) -> Module:info(Term, [], State);
test_info(Module, Term, Phone) -> test_info(Module, Term, #cx{params = client_id(Phone)}).

test_info(#'History'{roster_id = Phone, feed = Feed, data = Data} = History) ->
	test_info(roster_history,
		History#'History'{
			roster_id = roster:phone_id(Phone),
			feed = feed(Feed),
			data = [Msg#'Message'{feed_id = feed(MsgFeed), from = roster:phone_id(From), to = roster:phone_id(To)}
				|| #'Message'{feed_id = MsgFeed, from = From, to = To} = Msg <- Data]}, Phone);

test_info(#'Message'{from= From, to=To, feed_id = Feed, files = Data} = Message) ->
	test_info(roster_message,
		Message#'Message'{},
		From).

feed(#p2p{from = From, to = To}) -> [FromId, ToId] = [roster:phone_id(P) || P <- [From, To]], roster:feed_key(p2p, FromId, ToId);
feed(Feed) -> Feed.

receive_test(ClientId, Term) -> receive_test(ClientId, Term, 0).
receive_test(ClientId, Term, Counter) -> receive_test(ClientId, Term, Counter, ?TIMEOUT).
receive_test(_ClientId, _Term, -1, _Timeout) -> timer:sleep(100), ok;
receive_test(ClientId, Term, Counter, Timeout) ->
    receive R ->
        case {Term, R} of
            {init, init} -> init;
            {last_res, _} when not is_list(R) -> receive_test(ClientId, Term, Counter);
            {#'History'{}, #'History'{}} -> receive_drop(), R;
            {#'History'{}, #'Contact'{}} -> receive_drop(), R;
            {#'History'{}, #'Room'{}} -> receive_drop(), R;
            {#'Message'{status = []}, #'Message'{status = []}} when Counter > 0 -> receive_test(ClientId, Term, Counter - 1);
            {#'Message'{status = []}, #'Message'{status = []}} -> R;
            {#'Job'{}, _} -> R;
            {#'Link'{}, _} -> R;
            {#'Message'{},#'Ack'{}} -> R;
            {#'Message'{status = []}, #io{code = #error{}} = IO} -> IO;
            {#'Message'{status = []}, #errors{} = IO} -> IO;
            {#'Message'{status = []}, _} -> receive_test(ClientId, Term, Counter);
            {_, _} when Counter > 0 -> receive_test(ClientId, Term, Counter - 1);
            _ -> R end
    after Timeout -> stop_client(ClientId), throw({error, {timeout, Term}})
    end.

wait_for_last_res(ClientId, Count) -> case send_receive(ClientId, 1, last_res) of [] when Count > 0 -> wait_for_last_res(ClientId, Count - 1); Res -> Res end.
send(ClientId, Term) -> write_log([Term]), n2o_pi:send(system, ClientId, Term), timer:sleep(50).

send_last(ClientId, ResultLen) -> send_last(ClientId, ResultLen, [], 5, 100).
send_last(ClientId, ResultLen, Acc, Counter, Timeout) ->
	case send_receive(ClientId, last_res) of
		Res when length(Res) < ResultLen, Counter > 0 ->
			timer:sleep(Timeout),
			send_last(ClientId, ResultLen, lists:keysort(1, Acc ++ Res), Counter-1, Timeout);
		Res -> lists:keysort(1, Acc ++ Res)
	end.

send_receive(ClientIds, Term) when is_list(ClientIds) -> [send_receive(C, Term) || C <- ClientIds];
send_receive(ClientId, Term) -> send_receive(ClientId, 1, Term).
send_receive(ClientId, Counter, Term) -> send_receive(ClientId, Counter, Term, ?TIMEOUT).
send_receive(ClientId, Counter, Term, Timeout) -> send(ClientId, Term), receive_test(ClientId, Term, Counter - 1, Timeout).

set_filer(Clients, Filter) -> [send_receive(ClientId, {filter, Filter}) || ClientId <- Clients].

receive_last(ClientId, Counter, Term) -> receive_last(ClientId, Counter, Term, ?TIMEOUT).
receive_last(ClientId, Counter, Term, Timeout) -> send_receive(ClientId, last_res), send_receive(ClientId, Counter, Term, Timeout), send_receive(ClientId, last_res).

start_connect() -> start_connect(?HOST).
start_connect(MaxCounter) when is_integer(MaxCounter)-> start_connect(?HOST, MaxCounter);
start_connect(Host) -> start_connect(Host, length(kvs:all('Auth'))).
start_connect(Host, MaxCount) when is_integer(MaxCount) -> start_connect(Host, mnesia:dirty_first('Auth'), 0, MaxCount).
start_connect(Host, CurrentId, MaxCount) when is_integer(MaxCount) -> start_connect(Host, CurrentId, 0, MaxCount).
start_connect(Host, CurrentId, Count, MaxConnect) ->
	case mnesia:dirty_next('Auth', CurrentId) of
		'$end_of_table' -> {CurrentId, Count};
		NextId when Count =< MaxConnect ->
			{ok, #'Auth'{client_id = ClientId, token = Token}} = kvs:get('Auth', NextId),
			spawn(?MODULE, start_client, [ClientId, Token, [{host, Host}]]),
			start_connect(Host, NextId, Count+1, MaxConnect);
		_ -> {CurrentId, Count}
	end.
stop_connect() -> stop_connect(?HOST).
stop_connect(MaxCounter) when is_integer(MaxCounter)-> stop_connect(?HOST, MaxCounter);
stop_connect(Host) -> stop_connect(Host, length(kvs:all('Auth'))).
stop_connect(Host, MaxCount) -> stop_connect(Host, mnesia:dirty_first('Auth'), 0, MaxCount).
stop_connect(Host, CurrentId, Count, MaxCount) ->
	case mnesia:dirty_next('Auth', CurrentId) of
		'$end_of_table' -> {CurrentId, Count};
		NextId when Count =< MaxCount ->
			{ok, #'Auth'{client_id = ClientId}} = kvs:get('Auth', NextId),
			stop_client(ClientId),
			roster:info(?MODULE, "stop connect. Number of connects is ~p", [MaxCount -Count-1]),
			stop_connect(Host, NextId, Count+1, MaxCount);
		NextId -> {NextId, Count}
	end.

write_log(Data) -> File = get_config(log, []), Format = get_config(format, "~p~n~n"), rite_log(File, Format, Data).
write_log(Format, Data) -> write_log(get_config(log, []), Format, Data).
write_log([], _Format, _Data) -> skip;
write_log(File, Format, Data) when is_list(Data) -> file:write_file(File, io_lib:format(Format, Data));
write_log(File, Format, Data)  -> write_log(File, Format, [Data]).
