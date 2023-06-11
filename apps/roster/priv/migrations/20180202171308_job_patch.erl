-module('20180202171308_job_patch').
-behavior(db_migration).
-export([up/0, down/0]).

-include_lib("bpe/include/bpe.hrl").
-include_lib("kvs/include/kvs.hrl").

-record(action, {name= <<"publish">> :: [] | binary(), data=[]:: binary() | integer() | list(term())}).
-record('Job', { id   = [] :: [] | integer(),
    container=chain :: atom() | chain,
    feed_id = [],
    prev = [] :: [] | integer(),
    next = [] :: [] | integer(),
    context= [] :: [] | integer() | binary(),
    proc =  [],
    time=[] :: [] | integer(),
    data=[],
    events=[],
    settings = [],
    status=[] :: [] | init | update | delete | pending | stop | complete}).


-record(feed, {?CONTAINER, aclver=[]}).

up() ->
    S=case kvs:get(feed, process) of
          {ok,#feed{top=Top}=Feed} ->
              ProcIDs=kvs:fold(fun(#process{name=Name}=A,Acc) -> [element(2,A)|Acc] end,[],
                  process, Feed#feed.top,undefined, #iterator.prev,#kvs{mod=store_mnesia}),
              [ case bpe:find_pid(P) of undefined -> bpe:cleanup(P), P; _ -> [] end|| P<-ProcIDs];
          _ -> [] end,
    roster:recompile(roster),
    [kvs:delete(writer, Act)|| #writer{id=#action{}=Act}<-kvs:all(writer)],
    [kvs:delete(reader, Id)|| #'Job'{context=Id}<-kvs:all('Job'), Id/=[]],
    mnesia:delete_table('Shedule'),
    mnesia:delete_table('Job'),
    kvs:init(mnesia,roster),
    ok.

down() ->
    ok.
