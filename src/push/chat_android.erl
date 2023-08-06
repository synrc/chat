-module(chat_android).
-include_lib("chat/include/CHAT.hrl").
-export([description/0, notify/3, headers/0, test_push_notification/0]).

-define(FCM_SERVER_KEY, proplists:get_value(fcm_server_key, application:get_env(chat, push_api, []))).
-define(FCM_SEND_ENDPOINT, "https://fcm.googleapis.com/fcm/send").
-define(FCM_CONTENT_TYPE, "application/x-www-form-urlencoded;charset=UTF-8").
-define(FCM_TEST_DEVICE_ID, <<"maxim:00000">>).

description() -> "Android Push Notifications Module".
headers() -> ContentType = "application/json", Headers = [{"Authorization", binary_to_list(iolist_to_binary(["key=", ?FCM_SERVER_KEY]))}, {"Content-Type", ContentType}], Headers.
test_push_notification() -> MessageBody = "A words is an origin.", notify(MessageBody, MessageBody, ?FCM_TEST_DEVICE_ID).

notify(MessageTitle, MessageBody, DeviceId) when is_binary(MessageTitle) -> notify(binary_to_list(MessageTitle), MessageBody, DeviceId);
notify(MessageTitle, MessageBody, DeviceId) when is_binary(MessageBody) -> notify(MessageTitle, binary_to_list(MessageBody), DeviceId);
notify(MessageTitle, MessageBody, DeviceId) when is_binary(DeviceId) -> notify(MessageTitle, MessageBody, binary_to_list(DeviceId));
notify(_, MessageBody, DeviceId) -> Payload = binary_to_list(iolist_to_binary(["registration_id=", DeviceId, "&data=", MessageBody, "&priority=high"])),
    chat:info(?MODULE, "Payload ~p~n~n", [Payload]),
    Request = {?FCM_SEND_ENDPOINT, headers(), ?FCM_CONTENT_TYPE, Payload},
    {_, _} = chat_rest:send_request(post, Request, [], []),
    ok.

