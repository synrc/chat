-module('20180405173126_unsub_auth').
-behavior(db_migration).
-export([up/0, down/0]).

-record(mqtt_topic,
{ topic      :: binary(),
    flags = [] :: [retained | static]
}).

up() ->
    [n2o_vnode:unsubscribe(ClientId, Topic)
        ||#mqtt_topic{topic = <<"auth/", ClientId/binary>> = Topic} <-kvs:all(mqtt_topic)],
    ok.

down() ->
    ok.
