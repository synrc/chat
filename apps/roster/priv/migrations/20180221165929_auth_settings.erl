-module('20180221165929_auth_settings').
-behavior(db_migration).
-export([up/0, down/0]).

-record('Auth',         {client_id   = [] :: [] | binary(),
    dev_key     = [] :: [] | binary(),
    user_id     = [] :: [] | binary(),
    phone       = [] :: [] | binary(),
    token       = [] :: [] | binary(),
    type        = [] :: [] | atom(),
    sms_code    = [] :: [] | binary(),
    attempts    = [] :: [] | integer(),
    services    = [] :: list(atom()),
    settings    = [] :: list(),
    push        = [] :: [] | binary(),
    os          = [] :: [] | atom() | ios | android | web,
    created     = [] :: [] | integer() | binary(),
    last_online = [] :: [] | integer() }).

upd_auth(Auth) -> roster:upd_record(Auth, #'Auth'.services, []).

transform() ->
    mnesia:transform_table('Auth', fun upd_auth/1, record_info(fields, 'Auth')),
    [] = [A|| #'Auth'{push = Os, settings = Push}=A <-kvs:all('Auth'), is_binary(Push) andalso is_atom(Os)],
    ok.

up() ->
    roster:up_table('Auth', 14, 15, fun transform/0).

down() ->
    ok.
