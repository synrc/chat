-module('20180411165621_erase_muc_status').
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

-record(writer,  {id    = [] :: term(), % {p2p,_,_} | {muc,_}
    count =  0 :: integer(),
    cache = [] :: [] | tuple(),
    args  = [] :: term(),
    first = [] :: [] | tuple()}).


up() ->
    [begin
         Mc2 = case Mc of #'Message'{status = muc} -> Mc#'Message'{status = [], type = [sys]};
                   #'Message'{status = internal} -> Mc#'Message'{type = [sys]};
                   #'Message'{status = client, type=T1}-> Mc#'Message'{type= lists:flatten([T1]),status = []};_-> Mc end,
         Mf2 = case Mf of #'Message'{status = muc} -> Mf#'Message'{status = [], type = [sys]};
                   #'Message'{status = internal} -> Mf#'Message'{type = [sys]};
                   #'Message'{status = client, type=T2} -> Mf#'Message'{type=lists:flatten([T2]), status = []};_ -> Mf end,
         kvs:put(W#writer{cache = Mc2, first = Mf2})
     end||#writer{cache = Mc, first = Mf}=W<-kvs:all(writer)],
    [kvs:put(M#'Message'{type = [sys], status=[]})|| #'Message'{status = internal} = M<-kvs:all('Message')],
    [kvs:put(M#'Message'{type = [sys], status=[]})|| #'Message'{status = sys} = M<-kvs:all('Message')],
    [kvs:put(M#'Message'{type = [Atom]})|| #'Message'{type = Atom} = M<-kvs:all('Message'), is_atom(Atom)],
    [kvs:put(M#'Message'{status = [], type = [sys]})||#'Message'{status = muc}=M<-kvs:all('Message')],
    [kvs:put(M#'Message'{status = []})||#'Message'{status = client}=M<-kvs:all('Message')],
    [kvs:put(M#'Message'{type = []})|| #'Message'{status = ''} = M<-kvs:all('Message')],
    [kvs:delete('Message', Id) || #'Message'{id = Id, to = []} <- kvs:all('Message')],
    ok.

down() ->
    ok.
