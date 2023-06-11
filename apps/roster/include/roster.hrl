-ifndef(ROSTER_HRL).
-define(ROSTER_HRL, true).
-include_lib("kvs/include/feed.hrl").
-include_lib("kvs/include/kvs.hrl").
-include_lib("bpe/include/bpe.hrl").

-define(SYS_BPE_CLIENT,     <<"sys_bpe">>).
-define(SYS_REST_CLIENT,    <<"sys_rest">>).

-define(HIST_LIMIT, 1000).
-define(MAX_UNREAD, 100).
-define(MAX_PROFILE_OBJS, 5).
-define(MAX_LAST_ROOMS, 5).
-define(RECENT_ITEMS_COUNT, 5).
-define(VERSION, "11").

%% #'Feature'{} group
-define(FILE_GROUP, <<"FILE_DATA">>).
-define(LANG_GROUP, <<"LANGUAGE_SETTINGS">>).
-define(DUMMY_GROUP, <<"DUMMY_GROUP">>).

%% #'Feature'{} file group keys
-define(SIZE_KEY            , <<"SIZE">>).
-define(INFO_KEY            , <<"INFO">>).
-define(FILENAME_KEY        , <<"FILENAME">>).
-define(RESOLUTION_KEY      , <<"RESOLUTION">>).
-define(DURATION_KEY        , <<"DURATION">>).
-define(SMILE_KEY           , <<"SMILE">>).
-define(NAME_KEY            , <<"NAME">>).
-define(SURNAME_KEY         , <<"SURNAME">>).
-define(ALIAS_KEY           , <<"ALIAS">>).
-define(AVATAR_KEY          , <<"AVATAR">>).
-define(ADRESS_KEY          , <<"ADRESS">>).
-define(PLACED_KEY          , <<"PLACED">>).
-define(LANG_KEY            , <<"LANGUAGE">>).
-define(TRANSLATION_KEY     , <<"TRANSLATION">>).
-define(USERS_KEY           , <<"USERS">>).

%% #'Feature'{} language group keys
-define(DEFAULT_LANGUAGE_KEY, <<"DEFAULT_LANGUAGE">>).

-define(IP_KEY      , <<"IP">>).
-define(COUNTRY     , <<"Country">>).
-define(CITY        , <<"City">>).
-define(REGION      , <<"Region">>).
-define(TIME_ZONE   , <<"TimeZone">>).
-define(GEO_URL     , "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz").
-define(AUTH_GROUP  , <<"AUTH_DATA">>).

-record(chain,          {?CONTAINER, aclver = [], unread = {[],[]}}).

-record(push,           {model = [] :: [] | term(),
                         type  = [] :: [] | binary(),
                         title = [] :: [] | binary(),
                         alert = [] :: [] | binary(),
                         badge = [] :: [] | integer(),
                         sound = [] :: [] | binary()}).

-record('Search',       {id     = [] :: integer(),
                         ref    = [] :: binary(),
                         field  = [] :: binary(),
                         type   = [] :: '==' | '!=' | 'like',
                         value  = [] :: list(term()),
                         status = [] :: profile | roster | contact | member | room }).

-record(p2p,            {from = [] :: binary(),
                         to   = [] :: binary() }).

-record(muc,            {name = [] :: binary() }).

%% member query info
-record(mqi,            {feed_id = [] :: #muc{},
                         query   = [] :: [] | binary(), %% search item, [] - members without search
                         status  = [] :: [] | admin | member | removed}). %% [] - all members, admin - admins and owners

-record('Feature',      {id    = [] :: [] | binary(),
                         key   = [] :: binary(),
                         value = <<>> :: [] | binary() | true,
                         group = ?DUMMY_GROUP :: [] | binary()}).

-record('Service',      {id        = [] :: [] | binary(),
                        type       = [] :: email | vox | aws | wallet,
                        data       = [] :: term(),
                        login      = [] :: [] | binary(),
                        password   = [] :: [] | binary(),
                        expiration = [] :: [] | integer(),
                        status     = [] :: [] | verified | added | add | remove}).

-record('Member',       {id        = [] :: [] | integer(),
                         container = chain :: chain | cur | [],
                         feed_id   = [] :: #muc{} | #p2p{} | [] ,
                         prev      = [] :: [] | integer(),
                         next      = [] :: [] | integer(),
                         feeds     = [] :: list(),
                         phone_id  = [] :: [] | binary(),
                         avatar    = [] :: [] | binary(),
                         names     = [] :: [] | binary(),
                         surnames  = [] :: [] | binary(),
                         alias     = [] :: [] | binary(),
                         reader    = 0  :: [] | integer() | #reader{},
                         update    = 0  :: [] | integer(),
                         settings  = [] :: [] | list(#'Feature'{}),
                         services  = [] :: [] | list(#'Service'{}),
                         presence  = [] :: [] | online | offline,
                         status    = [] :: [] | admin | member | removed | patch | owner }).

-record('Desc',         {id       = [] :: [] | binary(),
                         mime     = <<"text">> :: [] | binary(),
                         payload  = [] :: [] | binary(),
                         parentid = [] :: [] | binary(),
                         data     = [] :: list(#'Feature'{})}).

-record('StickerPack',  {id          = [] :: [] | integer(),
                         name        = [] :: [] | binary(),
                         keywords    = [] :: list(binary()),
                         description = [] :: [] | binary(),
                         author      = [] :: [] | binary(),
                         stickers    = [] :: list(#'Desc'{}),
                         created     = 0 :: integer(),
                         updated     = 0 :: integer(),
                         downloaded  = 0 :: integer()}).

-record('Message',      {id        = [] :: [] | integer(),
                         container = chain :: chain | cur | [],
                         feed_id   = [] :: [] | #muc{} | #p2p{},
                         prev      = [] :: [] | integer(),
                         next      = [] :: [] | integer(),
                         msg_id    = [] :: [] | binary(),
                         from      = [] :: [] | binary(),
                         to        = [] :: [] | binary(),
                         created   = [] :: [] | integer(),
                         files     = [] :: list(#'Desc'{}),
                         type      = [] :: [sys | reply | forward | read | edited | cursor ],
                         link      = [] :: [] | integer() | #'Message'{},
                         seenby    = [] :: [] | list(binary() | integer()),
                         repliedby = [] :: [] | list(integer()),
                         mentioned = [] :: [] | list(integer()),
                         status    = [] :: [] | async | delete | clear| update | edit}).

-record('Link',         {id         = [] :: [] | binary(),  %% link value
                         name       = [] :: [] | binary(),  %% unused atm
                         room_id    = [] :: [] | binary(),  %% parent Room id
                         created    = [] :: [] | integer(), 
                         type       = [] :: [] | group | channel,
                         status     = [] :: [] | gen | check | add %% old unused fields
                                               | get | join |  update | delete}). %% new fields

-record('Room',         {id          = [] :: [] | binary(),
                         name        = [] :: [] | binary(),
                         links       = [] :: [] | list(#'Link'{}),
                         description = [] :: [] | binary(),
                         settings    = [] :: list(#'Feature'{}),
                         members     = [] :: list(#'Member'{}),
                         admins      = [] :: list(#'Member'{}),
                         data        = [] :: list(#'Desc'{}),
                         type        = [] :: [] | group | channel | call,
                         tos         = [] :: [] | binary(),
                         tos_update  = 0  :: [] | integer(),
                         unread      = 0  :: [] | integer(),
                         mentions    = [] :: list(integer()),
                         readers     = [] :: list(integer()),
                         last_msg    = [] :: [] | integer() | #'Message'{},
                         update      = 0  :: [] | integer(),
                         created     = 0  :: [] | integer(),
                         status      = [] :: [] | create | leave| add | remove | removed | join | joined | info
                                                | patch | get | delete | last_msg | mute | unmute}).

-record('Tag',          {roster_id = [] :: [] | binary(),
                         name      = [] :: binary(),
                         color     = [] :: binary(),
                         status    = [] :: [] | create | remove | edit}).

-record('Star',         {id        = [] :: [] | integer(),
                         client_id = [] :: [] | binary(),
                         roster_id = [] :: [] | integer(),
                         message   = [] :: [] |#'Message'{},
                         tags      = [] :: list(#'Tag'{}),
                         status    = [] :: [] | add | remove}).

-record('Typing',       {phone_id = [] :: binary(),
                         comments = [] :: term()}).

-record('Contact',      {phone_id = [] :: [] | binary(),
                         avatar   = [] :: [] | binary(),
                         names    = [] :: [] | binary(),
                         surnames = [] :: [] | binary(),
                         nick     = [] :: [] | binary(),
                         reader   = [] :: [] | integer() | list(integer()),
                         unread   = 0  :: [] | integer(),
                         last_msg = [] :: [] | #'Message'{},
                         update   = 0  :: [] | integer(),
                         created  = 0  :: [] | integer(),
                         settings = [] :: list(#'Feature'{}),
                         services = [] :: list(#'Service'{}),
                         presence = [] :: [] | online | offline | binary(),
                         status   = [] :: [] | request | authorization | ignore | internal
                                             | friend | last_msg | ban | banned | deleted | not_existence}).

-record('ExtendedStar', {star      = [] :: #'Star'{} | [],
                         from      = [] :: #'Contact'{} | #'Room'{} | []}).

-record('Auth',         {client_id   = [] :: [] | binary(),
                         dev_key     = [] :: [] | binary(),
                         user_id     = [] :: [] | binary(),
                         phone       = [] :: [] | binary() | {fake, binary()},
                         token       = [] :: [] | binary(),
                         type        = [] :: [] | update | clear | delete | deleted | logout
                                                | verify | verified | expired | reg | resend 
                                                | voice | push | get | {ver | reg, string()},
                         sms_code    = [] :: [] | binary(),
                         attempts    = [] :: [] | integer(),
                         services    = [] :: list(term()),
                         settings    = [] :: [] | binary() | list(#'Feature'{}),
                         push        = [] :: [] | binary(),
                         os          = [] :: [] | ios | android | web,
                         created     = [] :: [] | integer(),
                         last_online = [] :: [] | integer() }).

-record('Roster',       {id       = [] :: [] | binary() | integer(),
                         names    = [] :: [] | binary(),
                         surnames = [] :: [] | binary(),
                         email    = [] :: [] | binary(),
                         nick     = [] :: [] | binary(),
                         userlist = [] :: list(#'Contact'{} | integer()),
                         roomlist = [] :: list(#'Room'{}),
                         favorite = [] :: list(#'Star'{}),
                         tags     = [] :: list(#'Tag'{}),
                         phone    = [] :: [] | binary(),
                         avatar   = [] :: [] | binary(),
                         update   = 0  :: [] | integer(),
                         status   = [] :: [] | get | create | del | remove | nick
                                             | search | contact | add | update 
                                             | list | patch | last_msg }).

-record('Profile',      {phone    = [] :: [] | binary(),
                         services = [] :: [] | list(#'Service'{}),
                         rosters  = [] :: [] | list(#'Roster'{} | binary() | integer()), 
                         settings = [] :: [] | list(#'Feature'{}),
                         update   = 0  :: integer(),
                         balance  = 0  :: integer(),
                         presence = [] :: [] | offline | online | binary(),
                         status   = [] :: [] | remove | get | patch | update| delete | create | init}).

-record('Presence',       {uid    = <<>> :: binary(),
                           status = [] :: [] | offline | online | binary()}).

-record('Friend',       {phone_id  = [] :: binary(),
                         friend_id = [] :: binary(),
                         settings  = [] :: [] | list(#'Feature'{}),
                         status    = [] :: ban | unban | request | confirm | update | ignore}).

-record(act,            {name= <<"publish">> :: [] | binary(), data=[]:: binary() | integer() | list(term())}).


-record('Job',          {id        = [] :: [] | integer(),
                         container = chain :: chain | [],
                         feed_id   = [] :: #act{},
                         prev      = [] :: [] | integer(),
                         next      = [] :: [] | integer(),
                         context   = [] :: [] | integer() | binary(),
                         proc      = [] :: [] | integer() | #process{},
                         time      = [] :: [] | integer(),
                         data      = [] :: [] | binary() | list(term() | #'Message'{}),
                         events    = [] :: [] | list(#messageEvent{}),
                         settings  = [] :: [] | list(#'Feature'{}),
                         status    = [] :: [] | init | update | delete | pending | stop | complete | restart}).

-record('History',      {roster_id = [] :: binary(),
                         feed      = [] :: #p2p{} | #muc{} | #act{} | #'StickerPack'{} | [],
                         size      = 0  :: [] | integer(),
                         entity_id = 0  :: [] | integer(),
                         data      = [] :: [] | list(#'Message'{} | #'Job'{} | #'StickerPack'{}),
                         status    = [] :: updated | get | update | last_loaded | last_msg | get_reply | double_get | delete |
                                           image | video | file | link | audio | contact | location | text}).

-record('Schedule', {id   = [] :: [] | integer() | {integer(), {integer(),integer(),integer()}},
                     proc = [] :: [] | integer() | binary(),
                     data = [] :: binary() | list(term()),
                     state =[] :: [] | term()}).

%% Index.id - term for indexing in format {keyword_atom, value_binary}
%% Index.roster - entity id, list of Parent elements' id. Unique for Nick and Link indexing.
%%      | Index.id                 | Index.roster
%% --------------------------------------------------
%% Nick | {nick, <<"NickBinary">>} | [Roster.id]
%% Link | {link, <<"LinkBinary">>} | [Room.id]
-record('Index',        {id     = [] :: [] | term(),
                         roster = [] :: list(term())}).

-record('Whitelist',    {phone    = [] :: [] | integer() | binary(),
                         created  = 0  :: [] | integer()}).

-record(error,          {code = [] :: [] | atom()}).
-record(ok,             {code = [] :: [] | sms_sent | call_in_progress | push | cleared | logout | binary()}).

-record(error2,         {code = [] :: [] | atom(), src=[] :: [] | binary() | integer() }).
-record(ok2,            {code = [] :: [] | atom(), src=[] :: [] | {binary(), binary()} | binary() }).

-record(io,             {code = []   :: [] | #ok{} | #error{} | #ok2{} | #error2{},
                         data = <<>> :: [] | <<>> | binary() | #'Roster'{} | { atom(), binary() | integer() }}).

-record('Ack',          {table = 'Message' :: atom(),
                         id    = [] :: [] | binary()}).

%% Server response with error
%% code - list of binary status codes
%% data - requested erlang model
%% Example:
%% {errors, [permissions_denied],
%%   {'Member',1178,chain,[],[],[],[],[],[],[],[],[],[],[],0,0,[{'Feature',<<"1178_1518034698522">>,<<"Notifications">>,<<"true">>,<<"GROUP_NOTIFICATIONS">>}],[],patch}}
-record(errors,         {code = [] :: [] | list(binary()),
                         data = [] :: [] | term()}).

-record('PushService', {recipients = [] :: list(binary()),
                        id         = [] :: [] | binary(),
                        ttl        = 0  :: [] | integer(),
                        module     = [] :: [] | binary(),
                        priority   = [] :: [] | binary(),
                        payload    = [] :: [] | binary()}).

-record('PublishService', {message = [] :: [] | binary(),
                           topic   = [] :: [] | binary(),
                           qos     = 0  :: [] | integer()}).

-record('FakeNumbers', {phone    = [] :: [] | integer() | binary(),
                        created  = 0  :: [] | integer() | list()}).

-endif.