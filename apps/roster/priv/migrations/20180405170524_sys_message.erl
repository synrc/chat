-module('20180405170524_sys_message').
-behavior(db_migration).
-export([up/0, down/0]).

-record('Message',      {id        = [] :: [] | integer(),
    container = chain :: atom() | chain | cur,
    feed_id   = [],
    prev      = [] :: [] | integer(),
    next      = [] :: [] | integer(),
    msg_id    = [] :: [] | binary(),
    from      = [] :: [] | binary(),
    to        = [] :: [] | binary(),
    created   = [] :: [] | integer() | binary(),
    files     = [] :: [] | list(),
    type      = [] :: [] | atom() | reply | forward | sched | read | edited
    | online | offline | join | leave | add | clear | patch,
    link      = [] :: [] | integer(),
    seenby    = [] :: [] |  list(binary() | integer()),
    repliedby = [] :: [] | list(integer()),
    status    = [] :: [] | client | async | delete
    | sent | internal | update | edit | muc }).

up() ->
    [kvs:put(M#'Message'{type = [sys]})|| #'Message'{status = internal} = M<-kvs:all('Message')],
    ok.

down() ->
    ok.
