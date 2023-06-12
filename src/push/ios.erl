-module(ios).
-include_lib("chat/include/roster.hrl").
-include_lib("chat/include/push.hrl").

-define(APNS_TEST_DEVICE_ID, "maxim:0000").
-define(APNS_CERT_DIR, proplists:get_value(apns_cert_dir, application:get_env(chat, push_api, []))).
-define(APNS_PORT, proplists:get_value(apns_port, application:get_env(chat, push_api, []))).
-define(GATEWAY_LIST, [{<<"SANDBOX">>, "gateway.sandbox.push.apple.com"},
                       {<<"LIVE">>,    "gateway.push.apple.com"}]).

-define(BANDLE_LIST, [{<<"com.synrc.root">>, {"cert_rc.pem", "key_rc.pem"}},
                      {<<"com.synrc.mobile">>, {"cert_prod.pem", "key_prod.pem"}},
                      {<<"com.synrc.dev">>, {"cert_dev.pem", "key_dev.pem"}}]).

notify(Alert, Custom, Type, DeviceId, SessionSettings) when is_binary(DeviceId) -> notify(Alert, Custom, Type, binary_to_list(DeviceId), SessionSettings);
notify(A, C, T, DeviceId, SessionSettings) -> [Alert, Custom, Type] = [iolist_to_binary([L]) || L <- [A, C, T]], application:ensure_started(ssl),
    Aps = jsx:encode([{<<"model">>, Custom}, {<<"type">>, Type}, {<<"title">>, Alert}, {<<"version">>, <<?VERSION>>}, 
                      {<<"dns">>, get_data_from_feature(SessionSettings, ?FKPN_SERVER_DNS)}]),
    PayloadString = binary_to_list(iolist_to_binary(["{\"aps\": {\"synrc\": ", Aps, "}}"])),
    Payload = list_to_binary(PayloadString), PayloadLength = size(Payload),
    FormattedDeviceId = list_to_integer(DeviceId, 16),
    Packet = <<0:8, 32:16/big, FormattedDeviceId:256/big, PayloadLength:16/big, Payload/binary>>,
    {_, {CertFile, KeyFile}} = get_bandle(SessionSettings),
    Options = [{certfile, path_to_pem_file(CertFile)}, {keyfile, path_to_pem_file(KeyFile)}, {mode, binary}],
    [send_push(Addr, Packet, Options, 1) || {_, Addr} <- get_gateway(SessionSettings)],
    ok.

send_push(Addr, Payload, Options, Attempt) ->
    Duration = Attempt * 500,
    {Status, Socket} = ssl:connect(Addr, ?APNS_PORT, Options, Duration),
    case Status of
        ok ->
            ssl:send(Socket, Payload),
            ssl:close(Socket);
        error ->
            if
                Attempt > 10 ->
                    io:format("Final error", []);
                true ->
                    timer:sleep(Duration),
                    io:format("Error with socket opening. Reason:~p", [Socket]),
                    send_push(Addr, Payload, Options, Attempt + 1)
            end
    end.

path_to_pem_file(FileName) -> iolist_to_binary([?APNS_CERT_DIR, FileName]).
get_data_from_feature(SessionSettings, Key) -> case lists:keyfind(Key, #'Feature'.key, SessionSettings) of #'Feature'{value = Value} -> Value; _ -> [] end.
get_bandle(SessionSettings) -> [H|_]=get_from_session(SessionSettings, ?FKPN_BANDLE, ?BANDLE_LIST), H.
get_gateway(SessionSettings) -> get_from_session(SessionSettings, ?FKPN_GATEWAY, ?GATEWAY_LIST).

get_from_session(SessionSettings, Key, AcceptedValues) ->
    case get_data_from_feature(SessionSettings, Key) of
        [] -> AcceptedValues;
        FoundValue -> Filtered = lists:filter(fun(X) -> element(1,X) == FoundValue end, AcceptedValues),
            case Filtered of [] -> AcceptedValues; _ -> Filtered end
    end.


test_push_notification() ->
    Custom = <<"maxim:00000">>,
    Msg = lists:concat(["Test it! ", vox_api:generate_random_data(4)]),
    SessionSettings = [#'Feature'{id = <<"ID_Sandbox">>, key = <<"APNS_GATEWAY">>, value = <<"SANDBOX">>, group = <<"AUTH_DATA">>},
                       #'Feature'{id = <<"ID_Dns">>, key = <<"SERVER_DNS">>, value = <<"SomeDNSValue">>, group = <<"AUTH_DATA">>},
                       #'Feature'{id = <<"ID_Bandle">>, key = <<"IOS_BANDLE">>,value = <<"com.synrc.mobile">>, group = <<"AUTH_DATA">>}],
    notify(Msg, Custom, <<"message">>, ?APNS_TEST_DEVICE_ID, SessionSettings).