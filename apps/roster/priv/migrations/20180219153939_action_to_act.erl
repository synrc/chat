-module('20180219153939_action_to_act').
-behavior(db_migration).
-export([up/0, down/0]).

-record(writer,  {id    = [] :: term(), % {p2p,_,_} | {muc,_}
    count =  0 :: integer(),
    cache = [] :: [] | tuple(),
    args  = [] :: term(),
    first = [] :: [] | tuple()}).

-record(reader,  {id    = [] :: term(), % phone_id | {p2p,_,_} | {muc,_,_}
    pos   = 0 :: [] | integer(),
    cache = [] :: [] | integer(),
    args  = [] :: term(),
    feed  = [] :: term(), % {p2p,_,_} | {muc,_} -- link to writer
    dir   =  0 :: 0 | 1}).

-record(kvs,       {mod,cx}).

-define(CONTAINER, id=[] :: [] | integer(),
                    top=[] :: [] | integer(),
                    rear=[] :: [] | integer(),
                    count=0 :: integer()).

-define(ITERATOR(Container), id=[] :: [] | integer(),
                            container=Container :: atom(),
                            feed_id=[] :: term(),
                            prev=[] :: [] | integer(),
                            next=[] :: [] | integer(),
                            feeds=[] :: list()).

-record(iterator,  {?ITERATOR([])}).

-record(feed, {?CONTAINER, aclver=[]}).
-record(action,   {name= <<"publish">> :: [] | binary(), data=[]:: binary() | integer() | list(term())}).
-record(act,   {name= <<"publish">> :: [] | binary(), data=[]:: binary() | integer() | list(term())}).
%%
-record('Job',          {id   = [] :: [] | integer(),
    container=chain :: atom() | chain,
    feed_id = [] :: #act{},
    prev = [] :: [] | integer(),
    next = [] :: [] | integer(),
    context= [] :: [] | integer() | binary(),
    proc =  [] :: []  | integer(),
    time=[] :: [] | integer(),
    data=[] :: [] | list( ),
    events=[] :: list(),
    settings = [] :: [] | list(),
    status=[] :: [] | init | update | delete | pending | stop | complete}).

-record(process,      { ?ITERATOR(feed), name=[] :: [] | binary(),
    roles=[] :: list(),
    tasks=[] :: list(),
    events=[] :: list(),
    hist=[] :: [],
    flows=[] :: list(),
    rules=[] :: [],
    docs=[] :: list(tuple()),
    options=[] :: term(),
    task=[] :: [] | atom(),
    timer=[] :: [] | binary(),
    notifications=[] :: [] | term(),
    result=[] :: [] | binary(),
    started=[] :: [] | binary(),
    beginEvent=[] :: [] | atom(),
    endEvent=[] :: [] | atom()}).

up() ->
    S=case kvs:get(feed, process) of
          {ok,#feed{top=Top}=Feed} ->
              ProcIDs=kvs:fold(fun(#process{name=Name}=A,Acc) -> [element(2,A)|Acc] end,[],
                  process, Feed#feed.top,undefined, #iterator.prev,#kvs{mod=store_mnesia}),
              [ case bpe:find_pid(P) of undefined -> bpe:cleanup(P), P; _ -> [] end|| P<-ProcIDs];
          _ -> [] end,
    roster:recompile(roster),
    [kvs:put(W#writer{id=#act{name=N, data=D}, cache=J1#'Job'{feed_id=#act{name=N, data=D}},
     first=J0#'Job'{feed_id=#act{name=N, data=D}}})||
        #writer{id=#action{name=N, data=D}, cache=#'Job'{}=J1, first=#'Job'{}=J0}=W<-kvs:all(writer)],
    [kvs:delete(writer,#action{name=N, data=D})||
        #writer{id=#action{name=N, data=D}}=W<-kvs:all(writer)],
    [begin A=#act{name=N, data=D}, kvs:put(J#'Job'{feed_id =A}),
           case C of [] -> ok; C-> case kvs:get(reader, C) of
                                   {ok,#reader{ }=R} -> kvs:put(R#reader{feed =A});
                                                 __  -> ok
           end end end || #'Job'{feed_id =#action{name=N, data=D}, id=Id, context=C}=J<-kvs:all('Job')],
    [kvs:delete(reader,Id)||
        #reader{id=Id, feed = #action{}}<-kvs:all(reader)],
    ok.

down() ->
    ok.
