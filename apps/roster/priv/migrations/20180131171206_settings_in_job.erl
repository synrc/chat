-module('20180131171206_settings_in_job').
-behavior(db_migration).
-export([up/0, down/0]).

-include_lib("kvs/include/kvs.hrl").

-record(action, {name= <<"publish">> :: [] | binary(), data=[]:: binary() | integer() | list(term())}).
-record('Job', { id   = [] :: [] | integer(),
    container=chain :: atom() | chain,
    feed_id = [],
    next = [] :: [] | integer(),
    prev = [] :: [] | integer(),
    context= [] :: [] | integer() | binary(),
    proc =  [],
    time=[] :: [] | integer(),
    data=[],
    events=[],
    settings = [],
    status=[] :: [] | init | update | delete | pending | stop | complete}).

upd_job([]) -> [];
upd_job(Job) -> roster:upd_record(Job, #'Job'.events, []).

transform() ->
    mnesia:transform_table('Job', fun upd_job/1, record_info(fields, 'Job')),
    [begin [CJ2, FJ2] = [case J of #'Job'{}->J;_ -> upd_job(J) end||J<-[CJ, FJ]],
        kvs:put(W#writer{cache = CJ2, first = FJ2})
     end || #writer{id=#action{}, cache = CJ, first = FJ}=W<-kvs:all(writer)],
    [[case J of []->ok;_ -> #'Job'{} = J end||J<-[CJ, FJ]]|| #writer{id=#action{}, cache = CJ, first = FJ}<-kvs:all(writer)],
    ok.


up() -> roster:up_table('Job', 12, 13, fun transform/0).

down() ->
    ok.
