-ifndef(ROSTER_HRL).
-define(ROSTER_HRL, true).

-define(ROOT, application:get_env(roster, upload, code:priv_dir(roster))).
-define(NEXT, 250 * 1024).
-define(STOP, 0).
-define(MAX_ROOM_LENGTH, 32).
-define(MIN_ROOM_LENGTH, 1).
-define(MAX_NAME_LENGTH, 32).
-define(MIN_NAME_LENGTH, 2).
-define(MIN_SURNAME_LENGTH, 1).

-include_lib("kvs/include/kvs.hrl").


% TIER-0 User

-record('Auth',         {client_id = [] :: [] | binary(),dev_key = [] :: [] | binary(), user_id = [] :: [] | binary(), phone = [] :: [] | binary() | {fake, binary()},
                         token = [] :: [] | binary(), type = [] :: [] | update | clear | delete | deleted | logout | verify | verified | expired | reg | resend  | voice | push | get | ver | reg},
                         sms_code = [] :: [] | binary(), attempts = [] :: [] | integer(), services = [] :: list(term()), settings = [] :: [] | binary() | list(#'Feature'{}),
                         push = [] :: [] | binary(), os = [] :: [] | ios | android | web, created = [] :: [] | integer(), last_online = [] :: [] | integer() }).

-record('Profile',      {phone = [] :: [] | binary(), services = [] :: [] | list(#'Service'{}), rosters  = [] :: [] | list(#'Roster'{} | binary() | integer()), 
                         settings = [] :: [] | list(#'Feature'{}), date   = 0  :: integer(), balance  = 0  :: integer(), presence = [] :: [] | offline | online | binary(),
                         status = [] :: [] | remove | get | patch | update| delete | create | init}).

-record('Roster',       {id = [] :: [] | binary() | integer(), names    = [] :: [] | binary(), surnames = [] :: [] | binary(), email = [] :: [] | binary(),
                         nick = [] :: [] | binary(), serlist = [] :: list(#'Contact'{} | integer()), roomlist = [] :: list(#'Room'{}), favorite = [] :: list(#'Star'{}),
                         tags = [] :: list(#'Tag'{}), hone = [] :: [] | binary(),  vatar = [] :: [] | binary(), update   = 0  :: [] | integer(),
                         status = [] :: [] | get | create | del | remove | nick  search | contact | add | update | list | patch | last_msg }).

-record('Contact',      {phone_id = [] :: [] | binary(), avatar = [] :: [] | binary(), names = [] :: [] | binary(),  urnames = [] :: [] | binary(),
                         nick = [] :: [] | binary(), reader = [] :: [] | integer() | list(integer()), nread   = 0  :: [] | integer(), last_msg = [] :: [] | #'Message'{},
                         update   = 0  :: [] | integer(), created  = 0  :: [] | integer(), settings = [] :: list(#'Feature'{}), services = [] :: list(#'Service'{}), presence = [] :: [] | online | offline | binary(),
                         status = [] :: [] | request | authorization | ignore | internal | friend | last_msg | ban | banned | deleted | nonexised }).

-record('Message',      {id = [] :: [] | integer(),container = chain :: chain | cur | [],feed_id  = [] :: [] | #muc{} | #p2p{},prev   = [] :: [] | integer(),next   = [] :: [] | integer(),
                         msg_id = [] :: [] | binary(),from = [] :: [] | binary(),to = [] :: [] | binary(),created = [] :: [] | integer(),files = [] :: list(#'Desc'{}),
                         type = [] :: [sys | reply | forward | read | edited | cursor ],link   = [] :: [] | integer() | #'Message'{},seenby  = [] :: [] | list(binary() | integer()),
                         repliedby = [] :: [] | list(integer()),mentioned = [] :: [] | list(integer()),status    = [] :: [] | async | delete | clear| update | edit}).

-record('History',      {roster_id = [] :: binary(), feed = [] :: #p2p{} | #muc{} | #act{} | #'StickerPack'{} | [], size = 0  :: [] | integer(), entity_id = 0  :: [] | integer(), data = [] :: [] | list(#'Message'{} | #'StickerPack'{}),
                         status = [] :: updated | get | update | last_loaded | last_msg | get_reply | double_get | delete | image | video | file | link | audio | contact | location | text}).

-record('Index',        {id = [] :: [] | term(), roster = [] :: list(term())}). % User | {user, <<"Title">>} | [Roster.id]
-record('Typing',       {phone_id = [] :: binary(), comments = [] :: term()}).
-record('Search',       {id = [] :: integer(), ref = [] :: binary(),field  = [] :: binary(),type = [] :: '==' | '!=' | 'like',value  = [] :: list(term()),status = [] :: profile | roster | contact | member | room }).
-record('Feature',      {id = [] :: [] | binary(), key = [] :: binary(), value = <<>> :: [] | binary() | true,group = [] :: [] | binary()}).
-record('Service',      {id = [] :: [] | binary(), type = [] :: synrc | aws | gcp | azure, data = [] :: term(), login = [] :: [] | binary(), password  = [] :: [] | binary(),expiration = [] :: [] | integer(), status = [] :: [] | verified | added | add | remove}).
-record('Desc',         {id = [] :: [] | binary(), mime = <<"text">> :: [] | binary(),payload  = [] :: [] | binary(),parentid = [] :: [] | binary(), data = [] :: list(#'Feature'{})}).
-record('Ack',          {table = 'Message' :: atom(), id = [] :: [] | binary()}).
-record('Whitelist',    {phone = [] :: [] | integer() | binary(), created  = 0  :: [] | integer()}).
-record('Presence',     {uid = <<>> :: binary(), status = [] :: [] | offline | online | binary()}).
-record('Friend',       {phone_id  = [] :: binary(), friend_id = [] :: binary(), settings  = [] :: [] | list(#'Feature'{}), status = [] :: ban | unban | request | confirm | update | ignore}).

% TIER-1 Room Service

-record('Room',         {id          = [] :: [] | binary(),name        = [] :: [] | binary(), links       = [] :: [] | list(#'Link'{}),description = [] :: [] | binary(),
                         settings    = [] :: list(#'Feature'{}),members     = [] :: list(#'Member'{}),admins      = [] :: list(#'Member'{}),data        = [] :: list(#'Desc'{}),
                         type        = [] :: [] | group | channel | call,tos         = [] :: [] | binary(),tos_update  = 0  :: [] | integer(), unread      = 0  :: [] | integer(),
                         mentions    = [] :: list(integer()),readers     = [] :: list(integer()), last_msg    = [] :: [] | integer() | #'Message'{}, update      = 0  :: [] | integer(),
                         created     = 0  :: [] | integer(), status      = [] :: [] | create | leave| add | remove | removed | join | joined | info | patch | get | delete | last_msg | mute | unmute}).

-record('Member',       {id = [] :: [] | integer(),container = chain :: chain | cur | [],feed_id  = [] :: #muc{} | #p2p{} | [] ,prev  = [] :: [] | integer(),
                         next = [] :: [] | integer(),feeds = [] :: list(),phone_id = [] :: [] | binary(),avatar = [] :: [] | binary(),names = [] :: [] | binary(),surnames = [] :: [] | binary(),
                         alias = [] :: [] | binary(),reader = 0 :: [] | integer() | #reader{},update  = 0 :: [] | integer(),settings = [] :: [] | list(#'Feature'{}),services = [] :: [] | list(#'Service'{}),
                         presence = [] :: [] | online | offline,status = [] :: [] | admin | member | removed | patch | owner }).

-record('Tag',          {roster_id = [] :: [] | binary(),name = [] :: binary(),color = [] :: binary(),status = [] :: [] | create | remove | edit}).
-record('Link',         {id = [] :: [] | binary(),name = [] :: [] | binary(),room_id = [] :: [] | binary(),created = [] :: [] | integer(), type = [] :: [] | broadcast | channel, status = [] :: [] | check | add | get | join | update | delete}).
-record('RoomStar',     {star      = [] :: #'Star'{} | [], from      = [] :: #'Contact'{} | #'Room'{} | []}).
-record('Star',         {id = [] :: [] | integer(),client_id = [] :: [] | binary(),roster_id = [] :: [] | integer(), message = [] :: [] |#'Message'{},tags  = [] :: list(#'Tag'{}), status = [] :: [] | add | remove}).
-record('StickerPack',  {id = [] :: [] | integer(),name = [] :: [] | binary(),keywords = [] :: list(binary()),description = [] :: [] | binary(),author = [] :: [] | binary(),stickers = [] :: list(#'Desc'{}),
                         created = 0 :: integer(),updated = 0 :: integer(),downloaded = 0 :: integer()}).

% TIER-2 BPMN Scripting

-record('Schedule',     {id   = [] :: [] | integer() | {integer(), {integer(),integer(),integer()}}, proc = [] :: [] | integer() | binary(), data = [] :: binary() | list(term()), state =[] :: [] | term()}).

% System

-record(ok,             {code = [] :: [] | atom(), src=[] :: [] | {binary(), binary()} | binary() }).
-record(error ,         {code = [] :: [] | atom(), src=[] :: [] | binary() | integer() }).
-record(errors,         {code = [] :: [] | list(binary()), data = [] :: [] | term()}).
-record(io,             {code = [] :: [] | #ok{} | #error{}, data = [] :: [] | <<>> | binary() | #'Roster'{} | { atom(), binary() | integer() }}).

-record(pushService,    {recipients = [] :: list(binary()), id = [] :: [] | binary(), t tl = 0 :: [] | integer(), module = [] :: [] | binary(), priority = [] :: [] | binary(), payload = [] :: [] | binary()}).
-record(publishService, {message = [] :: [] | binary(), topic = [] :: [] | binary(), qos = 0 :: [] | integer()}).
-record(push,           {model = [] :: [] | term(),type  = [] :: [] | binary(),title = [] :: [] | binary(),alert = [] :: [] | binary(),badge = [] :: [] | integer(),sound = [] :: [] | binary()}).


-endif.