-module('20180507171751_roster_status').
-behavior(db_migration).
-export([up/0, down/0]).

-record('Message',      {id        = [] :: [] | integer(),
	container = chain :: atom() | chain | cur,
	feed_id   = [],
	prev      = [] :: [] | integer(),
	next      = [] :: [] | integer(),
	msg_id    = [] :: [] | binary(),
	from      = [] :: [] | binary(),
	to        = [] :: [] | binary(),
	created   = [] :: [] | integer() | binary(),
	files     = [] :: [] | list(),
	type      = [] :: [] | [atom() | sys | reply | forward | read | edited],
	link      = [] :: [] | integer(),
	seenby    = [] :: [] |  list(binary() | integer()),
	repliedby = [] :: [] | list(integer()),
	mentioned = [] :: [] | list(integer()),
	status    = [] :: [] | async | delete | clear| update | edit }).

-record('Roster',       {id       = [] :: [] | integer(),
    names    = [] :: [] | binary(),
    surnames = [] :: [] | binary(),
    email    = [] :: [] | binary(),
    nick     = [] :: [] | binary(),
    userlist = [] :: list(),
    roomlist = [] :: list(),
    favorite = [] :: list(),
    tags     = [] :: list(),
    phone    = [] :: [] | binary(),
    avatar   = [] :: [] | binary(),
    update   = 0  :: [] | integer(),
    status   = [] :: [] | get | create | del | remove | nick
    | add | update | list | patch | last_msg }).

-record('Desc',         {id       = [] :: [] | binary(),
	mime     = <<"text">> :: [] | binary(),
	payload  = [] :: [] | binary(),
	size     = 0  :: integer(),
	filename = [] :: [] | binary(),
	info     = [] :: [] | binary()}).

fix_msg_type() ->
	[kvs:put(M#'Message'{type = []})||#'Message'{type = ['']}=M<-kvs:all('Message')].
fix_translate() ->
	[kvs:put(M#'Message'{files = [D#'Desc'{info =
		case Info of
			_ when Info /=[], Mime == <<"translate">> ->
				roster:binary_join(sets:to_list(sets:from_list(binary:split(Info, <<",">>, [global]))), <<",">>);
			_-> Info end} || #'Desc'{info = Info, mime = Mime}=D<-Descs]})
	|| #'Message'{files = Descs}=M<-kvs:all('Message')].


up() ->
    [kvs:put(R#'Roster'{status = []})|| #'Roster'{status = S}=R<-kvs:all('Roster'),
        lists:member(S, [update, nick, patch])], ok.

down() ->
    ok.
