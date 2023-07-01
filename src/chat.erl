-module(chat).
-behaviour(application).
-export([start/2, stop/1, init/1, connect/0, pub/1, sub/1, tables/0, metainfo/0, phone_id/1]).
-include_lib("chat/include/roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("kvs/include/metainfo.hrl").
-include_lib("mnesia/src/mnesia.hrl").

-define(EMAIL_RE, <<"[a-zA-Z0-9\+\.\_\%\-\+]{1,256}\@[a-zA-Z0-9][a-zA-Z0-9\-]{0,64}(\.[a-zA-Z0-9][a-zA-Z0-9\-]{0,25})+">>).
-define(PHONE_RE,<<"(?:\\+?(\\d{1})?-?\\(?(\\d{3})\\)?[\\s-\\.]?)?(\\d{3})[\\s-\\.]?(\\d{4})[\\s-\\.]?">>).
-define(URL_RE, <<"(?:(?:https?|ftp|file|smtp):\/\/|www\.|ftp\.)(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[-A-Za-z0-9+&@#\/%=~_|$?!:,.])*(?:\([-A-Za-z0-9+&@#\/%=~_|$?!:,.]*\)|[A-Za-z0-9+&@#\/%=~_|$])">>).



connect() ->
   {ok,Pid} = emqtt:start_link([
       {client_id, <<"5HT">>},
       {ssl, true},
       {host, "localhost"},
       {port, 8883},
       {ssl_opts, [
           {verify,verify_peer},
           {customize_hostname_check,
               [{match_fun, fun ({ip,{127,0,0,1}},{dNSName,"localhost"}) -> true;
                                (_,_) -> false end}]},
           {certfile,"priv/mosquitto/client.pem"},
           {keyfile,"priv/mosquitto/client.key"},
           {cacertfile,"priv/mosquitto/caroot.pem"}]}]),
   io:format("MQTT Server Connection: ~p", [Pid]),
   emqtt:connect(Pid),
   Pid.

sub(Conn) -> emqtt:subscribe(Conn, {<<"hello">>, 0}).
pub(Conn) -> emqtt:publish(Conn, <<"hello">>, <<"Hello World!">>, 0).

stop(_) -> ok.
init([]) -> {ok, {{one_for_one, 5, 10}, []}}.
start(_, _) -> supervisor:start_link({local, chat}, chat, []).
metainfo() ->  #schema{name = kvs, tables = tables()}.

tables()  -> [ #table{name = writer, fields = record_info(fields, writer)},
               #table{name = reader, fields = record_info(fields, reader)},
               #table{name = reader, fields = record_info(fields, reader)},
               #table{name = 'Auth',  fields = record_info(fields, 'Auth'), keys = [dev_key, user_id, phone, push]},
               #table{name = 'Roster', fields = record_info(fields, 'Roster')},
               #table{name = 'Message', container = chain, fields = record_info(fields, 'Message'), keys = [from, to, msg_id]},
               #table{name = 'Room', fields = record_info(fields, 'Room')},
               #table{name = 'Link', fields = record_info(fields, 'Link'), keys = [room_id]},
               #table{name = 'Member', container = chain, fields = record_info(fields, 'Member')},
               #table{name = 'Profile',  fields = record_info(fields, 'Profile')},
               #table{name = 'Index',  fields = record_info(fields, 'Index')},
               #table{name = 'StickerPack', fields = record_info(fields, 'StickerPack')}
             ].


phone_id(Id) -> Id.
