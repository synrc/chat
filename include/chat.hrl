-ifndef(CHAT_HRL).
-define(CHAT_HRL, true).

% client x-forms

-type icons() :: bin | heart | update | more | search | export |
                 toggle | read | qr | user | users | add | edit | avatar.

-record('header', { name = [], icons = []}).
-record('footer', { modules = []}).
-record('section', { name = [], rows = []}).
-record('row', { no = [], lico = [], rico = [], desc = [] }).
-record('screen', { no = [], name = [], hd = [], ft = [], sections = []}).

% client protocol

-record(p2p, { from = [] :: binary(), to = [] :: binary() }).
-record(muc, { name = [] :: binary() }).
-record(act, { name = [] :: binary(), data=[]:: binary() | integer() | list(term())}).

-type criteria() :: '==' | '!=' | 'like'.
-type scope() :: profile | folder | contact | member | room | chat | message.
-type presense() :: online | offline.
-type friendship() :: request | confirm | update | ignore | ban | unban.

-record('Feature', { id = [] :: [] | binary(), key = [] :: binary(), value = <<>> :: [] | binary() | true,group = [] :: [] | binary()}).
-record('Service', { id = [] :: [] | binary(), type = [] :: synrc | aws | gcp | azure, data = [] :: term(), login = [] :: [] | binary(), password  = [] :: [] | binary(),expiration = [] :: [] | integer(), status = [] :: [] | verified | added | add | remove}).
-record('Register', { nickname = [], csr = [], password = [] }). % KDF
-record('Profile', { nickname = [], phone = [], session = [], chats = [], contacts = [], keys = [], servers = [], settings, update, status, roster }).
-record('Auth', { session = [], type = [], sms_code = [], cert = [], challange = [], push, os, nickname, settings, token, dev_key, phone }).
-record('Search', { dn = [], id = [], field = [], value = [], criteria :: criteria(), type :: scope(), status }).
-record('Typing', { session = [], nickname= [], comments = [] }).
-record('Friend', { nickname = [], friend = [], type :: friendship()  }).
-record('Presence', { nickname = [], status :: presense()  }).
-record('Ack', { table = 'Message' :: atom(), id = [] :: [] | binary() }).
-record('Desc', { id = [] :: [] | binary(), mime = <<"text">> :: [] | binary(),
                  payload  = [] :: [] | binary(), parentid = [] :: [] | binary(),
                  data = [] :: list(#'Feature'{})}).

-record('Message', {
    id = [] :: [] | integer(), feed_id  = [] :: [] | #muc{} | #p2p{}, signature = [] :: [] | binary(),
    from = [] :: [] | binary(), to = [] :: [] | binary(), created = [] :: [] | integer(),
    files = [] :: list(#'Desc'{}), type = [] :: [sys | reply | forward | read | edited | cursor ],
    link = [] :: [] | integer() | #'Message'{}, seenby  = [] :: [] | list(binary()),
    repliedby = [] :: [] | list(integer()), mentioned = [] :: [] | list(binary()),
    status = [] :: [] | async | delete | clear| update | edit}).

-record('Contact', {
    nickname = [] :: [] | binary(), avatar = [] :: [] | binary(), names = [] :: [] | binary(), phone_id,
    surnames = [] :: [] | binary(), nick = [] :: [] | binary(), reader = [] :: [] | integer() | list(integer()),
    nread = 0  :: [] | integer(), last_msg = [] :: [] | #'Message'{}, presence = [] :: [] | online | offline | binary(),
    update   = 0  :: [] | integer(), created  = 0  :: [] | integer(), settings = [] :: list(#'Feature'{}), services = [] :: list(#'Service'{}),
    status = [] :: [] | request | authorization | ignore | internal | friend | last_msg | ban | banned | deleted | nonexised }).

-record('History', {
    nickname = [] :: binary(), feed = [] :: #p2p{} | #muc{} | [], roster,
    size = 0 :: [] | integer(), entity_id = 0 :: [] | integer(), data = [] :: [] | list(#'Message'{}),
    status = [] :: updated | get | update | last_loaded | last_msg | get_reply | double_get | delete | image | video | file | link | audio | contact | location | text}).

-record('Member', {
    id = [] :: [] | integer(),
    feed_id = [] :: #muc{} | #p2p{} | [],
    feeds = [] :: list(), phone_id = [] :: [] | binary(),
    avatar = [] :: [] | binary(), names = [] :: [] | binary(), surnames = [] :: [] | binary(),
    alias = [] :: [] | binary(), reader = 0 :: [] | integer(),
    update  = 0 :: [] | integer(),settings = [] :: [] | list(#'Feature'{}),
    services = [] :: [] | list(#'Service'{}), presence = [] :: [] | online | offline,
    status = [] :: [] | admin | member | removed | patch | owner }).

-record('Room', {
    id = [] :: [] | binary(), name = [] :: [] | binary(), links,
    description = [] :: [] | binary(), settings = [] :: list(#'Feature'{}),
    members = [] :: list(#'Member'{}), admins = [] :: list(#'Member'{}), data = [] :: list(#'Desc'{}),
    type = [] :: [] | group | channel | call, tos = [] :: [] | binary(), tos_update  = 0 :: [] | integer(),
    unread = 0 :: [] | integer(), mentions = [] :: list(integer()), readers = [] :: list(integer()),
    last_msg = [] :: [] | integer() | #'Message'{}, update = 0  :: [] | integer(), created = 0  :: [] | integer(),
    status = [] :: [] | create | leave| add | remove | removed | join | joined | info | patch | get | delete | last_msg | mute | unmute}).


-record('Roster', {
    id = [] :: [] | binary(), nickname = [] :: [] | binary(), update = 0  :: [] | integer(),
    contacts = [] :: list(#'Contact'{} | integer()), topics = [] :: list(#'Room'{}),
    status = [] :: [] | get | create | del | remove | nick | search | contact | add | update | list | patch | last_msg }).

-type protocol() :: #'Register'{} | #'Auth'{} | #'Feature'{} | #'Service'{} | #'Message'{}
                  | #'Profile'{} | #'Room'{} | #'Member'{} | #'Search'{} | #'Desc'{}
                  | #'Typing'{} | #'Friend'{} | #'Presence'{} | #'History'{} | #'Roster'{}.

-record('CHATMessage', { no = [], headers = [], body :: protocol() }).

% system records

-record(io,             {code=[], data=[]}).
-record(ok,             {code = [] :: [] | atom(), src=[] :: [] | {binary(), binary()} | binary() }).
-record(error ,         {code = [] :: [] | atom(), src=[] :: [] | binary() | integer() }).
-record(errors,         {code = [] :: [] | list(binary()), data = [] :: [] | term()}).

-record(pushService,    {recipients = [] :: list(binary()), id = [] :: [] | binary(), ttl = 0 :: [] | integer(), module = [] :: [] | binary(), priority = [] :: [] | binary(), payload = [] :: [] | binary()}).
-record(publishService, {message = [] :: [] | binary(), topic = [] :: [] | binary(), qos = 0 :: [] | integer()}).
-record(push,           {model = [] :: [] | term(),type  = [] :: [] | binary(),title = [] :: [] | binary(),alert = [] :: [] | binary(),badge = [] :: [] | integer(),sound = [] :: [] | binary()}).

-endif.
