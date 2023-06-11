-module('20190513165642_link').
-behavior(db_migration).
-export([up/0, down/0]).

-record('Link',         {id         = [] :: [] | binary(),  %% link value
    name       = [] :: [] | binary(),  %% unused atm
    room_id    = [] :: [] | binary(),  %% parent Room id
    created    = [] :: [] | integer(),
    type       = [] :: [] | group | channel,
    status     = [] :: [] | gen | check | add %% old unused fields
    | get | join |  update | delete}). %% new fields

-record('OldLink',         {id         = [] :: [] | binary(),  %% actually the link
    name       = [] :: [] | binary(),  %% Room id etc
    type       = [] :: [] | group | channel,
    status     = [] :: [] | get | join | update | delete }).

-record('Room',         {id          = [] :: [] | binary(),
    name        = [] :: [] | binary(),
    links       = [] :: [] | list(#'Link'{}),
    description = [] :: [] | binary(),
    settings    = [],
    members     = [],
    admins      = [],
    data        = [],
    type        = [] :: [] | group | channel | call,
    tos         = [] :: [] | binary(),
    tos_update  = 0  :: [] | integer(),
    unread      = 0  :: [] | integer(),
    mentions    = [] :: list(integer()),
    readers     = [] :: list(integer()),
    last_msg    = [],
    update      = 0  :: [] | integer(),
    created     = 0  :: [] | integer(),
    status      = [] :: [] | create | leave| add | remove | removed | join | info
    | patch | get | delete | last_msg | mute | unmute}).

-record('Roster',       {id       = [] :: [] | binary() | integer(),
    names    = [] :: [] | binary(),
    surnames = [] :: [] | binary(),
    email    = [] :: [] | binary(),
    nick     = [] :: [] | binary(),
    userlist = [],
    roomlist = [],
    favorite = [],
    tags     = [],
    phone    = [] :: [] | binary(),
    avatar   = [] :: [] | binary(),
    update   = 0  :: [] | integer(),
    status   = [] :: [] | get | create | del | remove | nick
    | add | update | list | patch | last_msg }).

upd({'Link', _, _, _, _} = Link) ->
    roster:upd_record(roster:upd_record(setelement(5,Link,[]), #'Link'.name, roster:now_msec()), #'Link'.id, []);

upd(#'Room'{links = Links} = R) ->
           R#'Room'{links = []};
upd(#'Roster'{roomlist = Rooms} = R) ->
           R#'Roster'{roomlist = [upd(Room)|| Room=#'Room'{} <- Rooms]};

upd(Link) -> Link.

transform() ->
    mnesia:transform_table('Link', fun upd/1, record_info(fields, 'Link')),
    ok.

up() ->
    roster:up_table('Link', record_info(size, 'OldLink'), record_info(size, 'Link'), fun transform/0),
    [case L of
                [] -> Link=roster_link:gen_link(RID,T), kvs:put(Link);
                 _ -> kvs:put(Room#'Room'{links = []})
     end || #'Room'{id =RID, links= L, type=T}=Room<-kvs:all('Room')],
    [kvs:put(upd(Roster))|| Roster <-kvs:all('Roster')],
    ok.
down() ->
    ok.
