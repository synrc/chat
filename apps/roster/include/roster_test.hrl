-ifndef(ROSTER_TEST_HRL).
-define(ROSTER_TEST_HRL, true).

-define(LOC, "127.0.0.1").
-define(HOST, ?LOC).
-define(DRP_TMOUT, case ?HOST of ?LOC -> 100;_ -> 1000 end).
-define(TIMEOUT, 7000).

%% Auth data
%% FG - Feature Group
%% FK - Feature Key
-define(TEST_FG, <<"TEST_DATA">>).
-define(TEST_SESSION_FK, <<"TEST_SESSION">>).
-define(FAKE_NUMBER_PREFIX, <<"380">>).
-define(DEV_KEY_PREFIX, <<"DevKey_">>).

-define(CVERSION,<<"version/10">>). %% client version

-define(DEFAULT_MQTTC_OPTS, [{clean_sess, true},
	{will, [{qos, 0}, {retain, false}, {topic, ?CVERSION}, {payload, <<"I die">>}]}]).


-record(state, {mqttc = [], mqtt_opts = [], client_id = <<>>, username = <<"api">>,
	receive_pid = [], filter = filter, last_res = []}).

-endif.

