-module(roster_push).
-include("roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("kvs/include/kvs.hrl").
-compile([start/0, authToSend, proc/2]).


start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"Push Service">>, state = []}).
proc(init, #pi{name = <<"Push Service">>} = Async) -> {ok, Async};
proc({async_push, Session, Payload, PushAlert, PushType}, #pi{} = H) -> push(Session, Payload, PushAlert, PushType), {reply, [], H}.

authToSend(#'Auth'{os = OS, push = PushToken, user_id = PhoneId, settings = AuthSettings}, Payload, PushAlert, PushType) -> push(OS, PushToken, Payload, PushAlert, PushType, AuthSettings).
push(_, [], _, _, _, _) -> skip;
push(ios, Push, Payload, PushAlert, <<"calling">>, AuthSettings) -> push:notify(PushAlert, Payload, <<"calling">>, Push, AuthSettings);
push(ios, Push, Payload, PushAlert, PushType, AuthSettings) ->  push:notify(PushAlert, base64:encode(term_to_binary(Payload)), PushType, Push, AuthSettings);
push(android, Push, Payload, PushAlert, PushType, _) -> push:notify(PushAlert,http_uri:encode(binary_to_list(base64:encode(term_to_binary(#push{model=Payload,type=PushType,alert=PushAlert,title=PushAlert,badge=1})))),Push);
push(_, _, _, _, _, _) -> skip.

