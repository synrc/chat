-module('20180206174350_add_server_id_to_star_model').
-behavior(db_migration).
-export([up/0, down/0]).

%% actual DB structure

-record(p2p,            {from = [] :: [] | binary(),
                         to   = [] :: [] | binary() }).

-record(muc,            {name = [] :: [] | binary() }).

-record('Desc',         {id       = [] :: [] | binary(),
                         mime     = <<"text">> :: [] | binary(),
                         payload  = [] :: [] | binary(),
                         size     = 0  :: integer(),
                         filename = [] :: [] | binary(),
                         info     = [] :: [] | binary()}).

-record('Message',      {id        = [] :: [] | integer(),
                         container = chain :: atom() | chain | cur,
                         feed_id   = [] :: #muc{} | #p2p{},
                         prev      = [] :: [] | integer(),
                         next      = [] :: [] | integer(),
                         msg_id    = [] :: [] | binary(),
                         from      = [] :: [] | binary(),
                         to        = [] :: [] | binary(),
                         created   = [] :: [] | integer() | binary(),
                         files     = [] :: [] | list(#'Desc'{}),
                         type      = [] :: [] | atom() | reply | forward | sched | read
                                              | online | offline | join | leave | add | clear,
                         link      = [] :: [] | integer(),
                         seenby    = [] :: [] |  list(binary() | integer()),
                         repliedby = [] :: [] | list(integer()),
                         status    = [] :: [] | client | async | delete
                                              | sent | internal | update | edit | muc }).

-record('Tag',          {roster_id = [] :: [] | integer(),
                         name      = [] :: binary(),
                         color     = [] :: binary(),
                         status    = [] :: [] | create | remove | edit }).

-record('Star',         {id        = [] :: [] | integer(),
                         client_id = [] :: [] | binary(),
                         roster_id = [] :: [] | integer(),
                         message   = [] :: #'Message'{},
                         tags      = [] :: list(#'Tag'{}),
                         status    = [] :: [] | add | remove }).

-record('Feature',      {id    = [] :: [] | binary(),
                         key   = [] :: [] | binary(),
                         value = [] :: [] | binary(),
                         group = [] :: [] | binary() }).

-record('Member',       {id        = [] :: [] | integer(),
                         container = chain :: atom() | chain | cur,
                         feed_id   = [] :: #muc{} | #p2p{},
                         prev      = [] :: [] | integer(),
                         next      = [] :: [] | integer(),
                         feeds     = [] :: list(),
                         phone_id  = [] :: [] | binary(),
                         avatar    = [] :: [] | binary(),
                         names     = [] :: [] | binary(),
                         surnames  = [] :: [] | binary(),
                         alias     = [] :: [] | binary(),
                         email     = [] :: [] | binary(),
                         vox_id    = [] :: [] | binary(),
                         reader    = 0  :: [] | integer(),
                         update    = 0  :: [] | integer(),
                         settings  = [] :: [] | list(#'Feature'{}),
                         presence  = [] :: [] | online | offline,
                         status    = [] :: [] | admin | member | removed | patch }).

-record('Room',         {id          = [] :: [] | binary(),
                         name        = [] :: [] | binary(),
                         description = [] :: [] | binary(),
                         settings    = [] :: list(),
                         members     = [] :: list(#'Member'{}),
                         admins      = [] :: list(#'Member'{}),
                         data        = [] :: [] | list(#'Desc'{}),
                         type        = [] :: [] | atom() | group | channel,
                         tos         = [] :: [] | binary(),
                         tos_update  = 0  :: [] | integer(),
                         unread      = 0  :: [] | integer(),
                         readers     = [] :: list(integer()),
                         last_msg    = [] :: [] | #'Message'{},
                         update      = 0  :: [] | integer(),
                         created     = 0  :: [] | integer(),
                         status      = [] :: [] | create | join | leave
                                                | ban | unban | add | remove | mute | unmute
                                                | patch | get | delete | settings
                                                | voice | video }).

-record('Contact',      {phone_id = [] :: [] | binary(),
                         avatar   = [] :: [] | binary(),
                         names    = [] :: [] | binary(),
                         surnames = [] :: [] | binary(),
                         nick     = [] :: [] | binary(),
                         email    = [] :: [] | binary(),
                         vox_id   = [] :: [] | binary(),
                         reader   = 0  :: [] | integer(),
                         unread   = 0  :: [] | integer(),
                         last_msg = [] :: [] | #'Message'{},
                         update   = 0  :: [] | integer(),
                         created  = 0  :: [] | integer(),
                         settings = [] :: [] | list(#'Feature'{}),
                         presence = [] :: [] | atom(),
                         status   = [] :: [] | request | authorization | internal
                                             | friend | last_msg | ban | banned | deleted }).

-record('Roster',       {id       = [] :: [] | integer(),
                         names    = [] :: [] | binary(),
                         surnames = [] :: [] | binary(),
                         email    = [] :: [] | binary(),
                         nick     = [] :: [] | binary(),
                         userlist = [] :: list(#'Contact'{}),
                         roomlist = [] :: list(#'Room'{}),
                         favorite = [] :: list(#'Star'{}),
                         tags     = [] :: list(#'Tag'{}),
                         phone    = [] :: [] | binary(),
                         avatar   = [] :: [] | binary(),
                         update   = 0  :: [] | integer(),
                         status   = [] :: [] | get | create | del | remove | nick
                                             | add | update | list | patch | last_msg }).

up() ->
%%     stop server nodes
    roster:stop_vnodes(),
    roster:recompile(roster),
    timer:sleep(1000),
%%     add Star.id and fill it with next Star.id value
    [begin
         UpdFavMsgs = lists:flatten([begin
                                         roster:upd_record(FavMsg, 1,  kvs:next_id('Star', 1))
                                     end || FavMsg <- FavMsgs]),
         kvs:put(R#'Roster'{favorite = UpdFavMsgs})
     end || #'Roster'{favorite = FavMsgs} = R <- kvs:all('Roster')],
%%     start server nodes
    roster:start_vnodes(),
    ok.

down() ->
    ok.
