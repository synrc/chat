%% FGPN - Feature Group for Push Notification
%% FKPN - Feature Key for Push Notification

-define(FGPN_INFO,       <<"PUSH_SETTINGS">>).
-define(FKPN_BANDLE,     <<"IOS_BANDLE">>).
-define(FKPN_GATEWAY,    <<"APNS_GATEWAY">>).
-define(FKPN_SERVER_DNS, <<"SERVER_DNS">>).

-define(ROOT, application:get_env(chat, upload, code:priv_dir(chat))).
-define(NEXT, 250 * 1024).
-define(STOP, 0).
-define(MAX_ROOM_LENGTH, 32).
-define(MIN_ROOM_LENGTH, 1).
-define(MAX_NAME_LENGTH, 32).
-define(MIN_NAME_LENGTH, 2).
-define(MIN_SURNAME_LENGTH, 1).
-define(VERSION, <<"SYNRC-1-6.6.14">>).
-define(LOC, "127.0.0.1").
-define(HOST, ?LOC).
-define(DROP_TIMEOUT, case ?HOST of ?LOC -> 100;_ -> 1000 end).
-define(TIMEOUT, 7000).
-define(TEST_FG, <<"TEST_DATA">>).
-define(TEST_SESSION_FK, <<"TEST_SESSION">>).
-define(FAKE_NUMBER_PREFIX, <<"380">>).
-define(DEV_KEY_PREFIX, <<"DevKey_">>).
-define(CLIENT_VERSION,<<"version/101">>).
-define(DEFAULT_MQTTC_OPTS, [{clean_sess, true}, {will, [{qos, 0}, {retain, false}, {topic, ?CLIENT_VERSION}, {payload, <<"I die">>}]}]).
-define(DEFAULT_LANGUAGE_KEY, <<"ua">>).
-define(LANG_KEY, <<"ua">>).

-record(pushService,    {recipients = [] :: list(binary()), id = [] :: [] | binary(), ttl = 0 :: [] | integer(), module = [] :: [] | binary(), priority = [] :: [] | binary(), payload = [] :: [] | binary()}).
-record(publishService, {message = [] :: [] | binary(), topic = [] :: [] | binary(), qos = 0 :: [] | integer()}).
-record(push,           {model = [] :: [] | term(),type  = [] :: [] | binary(),title = [] :: [] | binary(),alert = [] :: [] | binary(),badge = [] :: [] | integer(),sound = [] :: [] | binary()}).

