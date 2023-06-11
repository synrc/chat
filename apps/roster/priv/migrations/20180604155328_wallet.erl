-module('20180604155328_wallet').
-behavior(db_migration).
-export([up/0, down/0]).

-record('Contact',      {phone_id = [] :: [] | binary(),
	avatar   = [] :: [] | binary(),
	names    = [] :: [] | binary(),
	surnames = [] :: [] | binary(),
	nick     = [] :: [] | binary(),
%%                         email    = [] :: [] | binary(),
%%                         vox_id   = [] :: [] | binary(),
	reader   = 0  :: [] | integer(),
	unread   = 0  :: [] | integer(),
	last_msg = [],
	update   = 0  :: [] | integer(),
	created  = 0  :: [] | integer(),
	settings = [],
	services = [],
	presence = [] :: [] | atom(),
	status   = [] :: [] | request | authorization | ignore | internal
	| friend | last_msg | ban | banned | deleted }).

-record('Member',       {id        = [] :: [] | integer(),
	container = chain :: atom() | chain | cur,
	feed_id   = [],
	prev      = [] :: [] | integer(),
	next      = [] :: [] | integer(),
	feeds     = [] :: list(),
	phone_id  = [] :: [] | binary(),
	avatar    = [] :: [] | binary(),
	names     = [] :: [] | binary(),
	surnames  = [] :: [] | binary(),
	alias     = [] :: [] | binary(),
%%                         email     = [] :: [] | binary(),
%%                         vox_id    = [] :: [] | binary(),
	reader    = 0  :: [] | integer(),
	update    = 0  :: [] | integer(),
	settings  = [] :: [] | list(),
	services  = [] :: [] | list(),
	presence  = [] :: [] | online | offline,
	status    = [] :: [] | admin | member | removed | patch | owner }).

-record('Roster',       {id       = [] :: [] | integer(),
	names    = [] :: [] | binary(),
	surnames = [] :: [] | binary(),
	email    = [] :: [] | binary(),
	nick     = [] :: [] | binary(),
	userlist = [] :: list(#'Contact'{}),
	roomlist = [],
	favorite = [],
	tags     = [],
	phone    = [] :: [] | binary(),
	avatar   = [] :: [] | binary(),
	update   = 0  :: [] | integer(),
	status   = [] :: [] | get | create | del | remove | nick
	| add | update | list | patch | last_msg }).


upd(M) when element(1, M) == 'Member', not is_record(M, 'Member') ->
	{M1, [_,_|M2]} = lists:split(#'Member'.alias, tuple_to_list(M)),
	roster:upd_record(list_to_tuple(M1++M2), #'Member'.settings, []);
upd(C) when element(1, C) == 'Contact', not is_record(C, 'Contact') ->
	{C1, [_,_|C2]} = lists:split(#'Contact'.nick, tuple_to_list(C)),
	roster:upd_record(list_to_tuple(C1++C2), #'Contact'.settings, []).

transform() ->
	mnesia:transform_table('Member', fun upd/1, record_info(fields, 'Member')),
	[kvs:put(R#'Roster'{userlist = lists:map(fun upd/1, Contacts)})||#'Roster'{userlist = Contacts}=R<-kvs:all('Roster')].

up() ->
	MembSize = record_info(size, 'Member')+1,
    roster:up_table('Member', MembSize, MembSize-1, fun transform/0),
    ok.

down() ->
    ok.
