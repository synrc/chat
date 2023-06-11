-module('20180507171752_mention').
-behavior(db_migration).
-export([up/0, down/0]).

-record('Roster',       {id       = [] :: [] | integer(),
    names    = [] :: [] | binary(),
    surnames = [] :: [] | binary(),
    email    = [] :: [] | binary(),
    nick     = [] :: [] | binary(),
    userlist = [] :: list(),
    roomlist = [] :: list(),
    favorite = [] :: list(),
    tags     = [] :: list(),
    phone    = [] :: [] | binary(),
    avatar   = [] :: [] | binary(),
    update   = 0  :: [] | integer(),
    status   = [] :: [] | get | create | del | remove | nick
    | add | update | list | patch | last_msg }).


-record('Message',      {id        = [] :: [] | integer(),
    container = chain :: atom() | chain | cur,
    feed_id   = [] ,
    prev      = [] :: [] | integer(),
    next      = [] :: [] | integer(),
    msg_id    = [] :: [] | binary(),
    from      = [] :: [] | binary(),
    to        = [] :: [] | binary(),
    created   = [] :: [] | integer() | binary(),
    files     = [] :: [] | list(),
    type      = [] :: [] | [atom() | sys | reply | forward | sched | read | edited],
    link      = [] :: [] | integer(),
    seenby    = [] :: [] |  list(binary() | integer()),
    repliedby = [] :: [] | list(integer()),
    mentioned = [] :: [] | list(integer()),
    status    = [] :: [] | client | async | delete | clear
    | sent | update | edit }).

-record('Room',         {id          = [] :: [] | binary(),
    name        = [] :: [] | binary(),
    description = [] :: [] | binary(),
    settings    = [] :: list(),
    members     = [],
    admins      = [],
    data        = [] :: [] | list(),
    type        = [] :: [] | atom() | group | channel,
    tos         = [] :: [] | binary(),
    tos_update  = 0  :: [] | integer(),
    unread      = 0  :: [] | integer(),
    mentions    = [] :: [] | list(integer()),
    readers     = [] :: list(integer()),
    last_msg    = [] :: [] | #'Message'{},
    update      = 0  :: [] | integer(),
    created     = 0  :: [] | integer(),
    status      = [] :: [] | create | join | leave
    | ban | unban | add | remove | mute | unmute
    | patch | get | delete | settings
    | voice | video }).

-record(writer,  {id    = [] :: term(), % {p2p,_,_} | {muc,_}
    count =  0 :: integer(),
    cache = [] :: [] | tuple(),
    args  = [] :: term(),
    first = [] :: [] | tuple()}).

-record(act,         {name= <<"publish">> :: [] | binary(), data=[]:: binary() | integer() | list(term())}).
-record('Job',          {id   = [] :: [] | integer(),
    container=chain :: atom() | chain,
    feed_id = [] :: #act{},
    prev = [] :: [] | integer(),
    next = [] :: [] | integer(),
    context= [] :: [] | integer() | binary(),
    proc =  [] :: []  | integer(),
    time=[] :: [] | integer(),
    data=[] :: [] | list( #'Message'{}),
    events=[] :: list(),
    settings = [] :: [] | list(),
    status=[] :: [] | init | update | delete | pending | stop | complete}).

upd_rec([]) -> [];
upd_rec(M) when element(1, M) == 'Message', not is_record(M, 'Message') ->
    roster:upd_record(M, #'Message'.repliedby, []);
upd_rec(#'Job'{data = Msgs}=Job) -> Job#'Job'{data = lists:map(fun upd_rec/1, Msgs)};
upd_rec(R)  when element(1, R) == 'Room', not is_record(R, 'Room')->
    roster:upd_record(R, #'Room'.unread, []);
upd_rec(M) -> M.

transform() ->
    mnesia:transform_table('Message', fun upd_rec/1, record_info(fields, 'Message')),
    mnesia:transform_table('Room', fun upd_rec/1, record_info(fields, 'Room')),
    [kvs:put(W#writer{cache = upd_rec(C), first = upd_rec(F)})
        ||#writer{cache = C, first = F}=W<-kvs:all(writer)],
    [kvs:put(upd_rec(J)) ||#'Job'{}=J<-kvs:all('Job')],
    [kvs:put(R#'Roster'{roomlist = [upd_rec(Room)||Room<-Rooms]})
        || #'Roster'{roomlist = Rooms}=R<-kvs:all('Roster')], ok.

up() ->
    MsgSize = record_info(size, 'Message')-1,
    roster:up_table('Message', MsgSize, MsgSize+1, fun transform/0).

down() ->
    ok.
