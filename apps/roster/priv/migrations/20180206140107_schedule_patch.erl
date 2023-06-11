-module('20180206140107_schedule_patch').
-behavior(db_migration).
-export([up/0, down/0]).

-include_lib("bpe/include/bpe.hrl").
-include_lib("kvs/include/kvs.hrl").

-record('Schedule', { id =[] ::[] | integer(),
    proc=[]::[] | integer(),
    data=[]::[] | list(term()),
    state=[] :: [] | term()}).

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
    roster:recompile(roster),
    S=case kvs:get(feed, process) of
                {ok,#feed{top=Top}=Feed} ->
                    ProcIDs=kvs:fold(fun(#process{name=Name}=A,Acc) -> [element(2,A)|Acc] end,[],
                        process, Feed#feed.top,undefined, #iterator.prev,#kvs{mod=store_mnesia}),
                    [ case bpe:find_pid(P) of undefined -> bpe:cleanup(P), P; PID -> PID ! {'DOWN', <<>>, <<>>, <<>>, <<>>},
                                                                                    timer:sleep(4000),
                                                                                    bpe:cleanup(P),P  end|| P<-ProcIDs];
                _ -> [] end,
   [kvs:put(J#'Job'{status=delete})|| J<-kvs:all('Job')],
   kvs:delete(config, 'Shedule'),
   kvs:delete(id_seq, "Shedule.tables"),
   mnesia:delete_table('Shedule'),
   kvs:init(mnesia,roster),
   ok.

down() ->
    ok.
