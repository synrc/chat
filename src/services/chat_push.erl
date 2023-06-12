-module(chat_push).
-include("roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("kvs/include/kvs.hrl").
-export([start/0, proc/2, push/6, notify/3, notify/5]).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"Push Service">>, state = []}).
proc(init, #pi{name = <<"Push Service">>} = Async) -> {ok, Async};
proc({async_push, Session, Payload, PushAlert, PushType}, #pi{} = H) -> push(Session, Payload, PushAlert, PushType), {reply, [], H}.

authToSend(#'Auth'{os = OS, push = PushToken, user_id = PhoneId, settings = AuthSettings}, Payload, PushAlert, PushType) -> push(OS, PushToken, Payload, PushAlert, PushType, AuthSettings).

push(#'Auth'{os = OS, push = [], user_id = PhoneId, settings = AuthSettings}, Payload, PushAlert, PushType) -> skip;
push(#'Auth'{os = OS, push = PushToken, user_id = PhoneId, settings = AuthSettings}, Payload, PushAlert, PushType) ->
    push(OS, PushToken, Payload, PushAlert, PushType, AuthSettings),
    [PhoneId, OS, binary:part(PushToken, 0, erlang:min(25, size(PushToken))), PushAlert, PushToken].

push(_, [], _, _, _, _) -> skip;
push(ios, Push, Payload, PushAlert, <<"calling">>, AuthSettings) -> notify(PushAlert, Payload, <<"calling">>, Push, AuthSettings);
push(ios, Push, Payload, PushAlert, PushType, AuthSettings) ->  notify(PushAlert, base64:encode(term_to_binary(Payload)), PushType, Push, AuthSettings);
push(android, Push, Payload, PushAlert, PushType, _) -> notify(PushAlert,http_uri:encode(binary_to_list(base64:encode(term_to_binary(#push{model=Payload,type=PushType,alert=PushAlert,title=PushAlert,badge=1})))),Push);
push(_, _, _, _, _, _) -> skip.

notify(MessageTitle, MessageBody, DeviceId) -> chat_android:notify(MessageTitle, MessageBody, DeviceId).
notify(Alert, Custom, Type, DeviceId, SessionSettings) -> chat_ios:notify(Alert, Custom, Type, DeviceId, SessionSettings).
