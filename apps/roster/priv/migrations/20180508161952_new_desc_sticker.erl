-module('20180508161952_new_desc_sticker').
-behavior(db_migration).
-export([up/0, down/0]).


-define(GROUP, <<"FILE_DATA">>).

-define(SIZE_KEY,       <<"SIZE">>).
-define(INFO_KEY,       <<"INFO">>).
-define(FILENAME_KEY,   <<"FILENAME">>).
-define(RESOLUTION_KEY, <<"RESOLUTION">>).
-define(DURATION_KEY,   <<"DURATION">>).
-define(SMILE_KEY,      <<"SMILE">>).
-define(NAME_KEY,       <<"NAME">>).
-define(SURNAME_KEY,    <<"SURNAME">>).
-define(ALIAS_KEY,      <<"ALIAS">>).
-define(AVATAR_KEY,     <<"AVATAR">>).
-define(ADRESS_KEY,     <<"ADRESS">>).
-define(PLACE_KEY,      <<"PLACEID">>).
-define(LANG_KEY,       <<"LANGUAGE">>).
-define(TRANSLATION_KEY,<<"TRANSLATION">>).
-define(USERS_KEY,      <<"USERS">>).

-record('Star',         {id        = [] :: [] | integer(),
	client_id = [] :: [] | binary(),
	roster_id = [] :: [] | integer(),
	message   = [],
	tags      = [] :: list(),
	status    = [] :: [] | add | remove }).

-record('Feature',      {id    = [] :: [] | binary(),
    key   = [] :: [] | binary(),
    value = [] :: [] | binary(),
    group = ?GROUP }).

%%-record('Desc',         {id       = [] :: [] | binary(),
%%                         mime     = <<"text">> :: [] | binary(),
%%                         payload  = [] :: [] | binary(),
%%                         size     = 0  :: integer(),
%%                         filename = [] :: [] | binary(),
%%                         info     = [] :: [] | binary()}).

-record('Desc',         {id       = [] :: binary(),
    mime     = <<"text">> :: binary(),
    payload  = [] :: binary(),
    parentid = [] :: binary(),
    data     = [] :: list(#'Feature'{})}).

-record('Message',      {id        = [] :: [] | integer(),
    container = chain :: atom() | chain | cur,
    feed_id   = [],
    prev      = [] :: [] | integer(),
    next      = [] :: [] | integer(),
    msg_id    = [] :: [] | binary(),
    from      = [] :: [] | binary(),
    to        = [] :: [] | binary(),
    created   = [] :: [] | integer() | binary(),
    files     = [] :: [] | list(#'Desc'{}),
    type      = [] :: [] | [atom() | sys | reply | forward | read | edited],
    link      = [] :: [] | integer(),
    seenby    = [] :: [] |  list(binary() | integer()),
    repliedby = [] :: [] | list(integer()),
    mentioned = [] :: [] | list(integer()),
    status    = [] :: [] | async | delete | clear| update | edit }).

-record(act,         {name= <<"publish">> :: [] | binary(), data=[]:: binary() | integer() | list(term())}).

-record('Job',          {id   = [] :: [] | integer(),
    container=chain :: atom() | chain,
    feed_id = [] :: #act{},
    prev = [] :: [] | integer(),
    next = [] :: [] | integer(),
    context= [] :: [] | integer() | binary(),
    proc =  [] :: []  | integer(),
    time=[] :: [] | integer(),
    data=[] :: [] | list( #'Message'{}),
    events=[] :: list(),
    settings = [] :: [] | list(#'Feature'{}),
    status=[] :: [] | init | update | delete | pending | stop | complete}).

-record('StickerPack',  {id          = [] :: [] | integer(),
    name        = [] :: [] | binary(),
    keywords    = [] :: list(binary()),
    description = [] :: [] | binary(),
    author      = [] :: [] | binary(),
    stickers    = [] :: list(#'Desc'{}),
    created     = [] :: integer(),
    updated     = [] :: integer(),
    downloaded  = 0 :: integer()}).

-record('Room',         {id          = [] :: [] | binary(),
    name        = [] :: [] | binary(),
    description = [] :: [] | binary(),
    settings    = [] :: list(),
    members     = [] :: list(),
    admins      = [] :: list(),
    data        = [] :: [] | list(#'Desc'{}),
    type        = [] :: [] | atom() | group | channel,
    tos         = [] :: [] | binary(),
    tos_update  = 0  :: [] | integer(),
    unread      = 0  :: [] | integer(),
    mentions    = [] :: [] | list(integer()),
    readers     = [] :: list(integer()),
    last_msg    = [] :: [] | #'Message'{},
    update      = 0  :: [] | integer(),
    created     = 0  :: [] | integer(),
    status      = [] :: [] | create | leave| add | remove
    | patch | get | delete | last_msg}).

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

-record(writer,  {id    = [] :: term(), % {p2p,_,_} | {muc,_}
    count =  0 :: integer(),
    cache = [] :: [] | tuple(),
    args  = [] :: term(),
    first = [] :: [] | tuple()}).

id({'Desc',Id,_Mime,_Payload,_Size,_Filename,_Info}, Key) -><<Id/binary, "_", (string:lowercase(Key))/binary>>.

data({'Desc',_Id,<<"text">>,_Payload,_Size,_Filename,_Info}) -> [];
data({'Desc',_Id,_Mime,_Payload,Size,_Filename,_Info}=D) ->
    [#'Feature'{id = id(D, ?SIZE_KEY), key = ?SIZE_KEY,
        value = case Size of _ when is_integer(Size) -> integer_to_binary(Size);[]->[] end}].

nth(I, L) -> case length(L)<I of true -> <<>>; _->lists:nth(I, L) end.
split([], <<":">>) -> [<<>>, <<>>];
split(S, P) -> binary:split(S, P).

int_to_binary([]) -> [];
int_to_binary(I) -> integer_to_binary(I).

upd([]) -> [];
upd(#'Desc'{} = D) -> D;
upd({'Desc',Id,<<"audio">> =Mime,Payload,Size,_Filename,Info} = D) ->
    #'Desc'{id = Id, mime = Mime, payload = Payload,
        data = [#'Feature'{id = id(D, ?INFO_KEY), key = ?INFO_KEY, value = Info},
                #'Feature'{id = id(D, ?DURATION_KEY), key = ?DURATION_KEY, value = int_to_binary(Size)}]};
upd({'Desc',Id,<<"image">> =Mime,Payload,_Size,Filename,Info} = D) ->
    #'Desc'{id = Id, mime = Mime, payload = Payload,
        data = data(D)++[#'Feature'{id = id(D, ?INFO_KEY), key = ?FILENAME_KEY, value = Filename},
                #'Feature'{id = id(D, ?RESOLUTION_KEY), key = ?RESOLUTION_KEY, value = Info}]};
upd({'Desc',Id,<<"file">> =Mime,Payload,_Size,Filename,Info} = D) ->
    #'Desc'{id = Id, mime = Mime, payload = Payload,
        data = data(D)++[#'Feature'{id = id(D, ?INFO_KEY), key = ?FILENAME_KEY, value = Filename}]};
upd({'Desc',Id,<<"video">> =Mime,Payload,_Size,Filename,Info} = D) ->
    #'Desc'{id = Id, mime = Mime, payload = Payload,
        data = data(D)++[#'Feature'{id = id(D, ?INFO_KEY), key = ?FILENAME_KEY, value = Filename},
            #'Feature'{id = id(D, ?DURATION_KEY), key = ?DURATION_KEY, value = Info}]};
upd({'Desc',Id,<<"sticker">> =Mime,Payload,_Size,Filename,Info} = D) ->
    #'Desc'{id = Id, mime = Mime, payload = Payload,
        data = data(D)++[#'Feature'{id = id(D, ?SMILE_KEY), key = ?SMILE_KEY, value = Info}]};
upd({'Desc',Id,<<"thumb">> =Mime,Payload,Size,Filename,Info}) ->
    D = upd({'Desc',Id,<<"image">>,Payload,Size,Filename,Info}),
    D#'Desc'{mime = Mime};
upd({'Desc',Id,<<"contact">> =Mime,Payload,_Size,Filename,Info} = D) ->
    [NS, AA] = [split(F, <<":">>)||F<-[Filename, Info]],
    [Name, Surname]=[http_uri:decode(nth(I, NS))||I<-[1,2]],
    [Alias, Avatar]=[http_uri:decode(nth(I, AA))||I<-[1,2]],
    Fs = lists:zip([?NAME_KEY, ?SURNAME_KEY, ?ALIAS_KEY, ?AVATAR_KEY],
                   [Name, Surname, Alias, Avatar]),
    #'Desc'{id = Id, mime = Mime, payload = Payload,
        data = [#'Feature'{id = id(D, K), key = K, value = V}||{K, V}<-Fs]};
upd({'Desc',Id,<<"place">> =Mime,Payload,_Size,Filename,Info} = D) ->
    NA = split(Filename, <<":">>),
    [Name, Address]=[http_uri:decode(nth(I, NA))||I<-[1,2]],
    Fs = lists:zip([?NAME_KEY, ?ADRESS_KEY, ?PLACE_KEY], [Name, Address, Info]),
    #'Desc'{id = Id, mime = Mime, payload = Payload,
        data = [#'Feature'{id = id(D, K), key = K, value = V}||{K, V}<-Fs]};
upd({'Desc',Id,Mime,Payload,_Size,Lang,Users} = D) when Mime == <<"translate">>; Mime == <<"posttranslate">> ->
    LT = split(Payload, <<":">>),
    [P, Trans]=[http_uri:decode(nth(I, LT))||I<-[1,2]],
    Fs = lists:zip([?LANG_KEY, ?TRANSLATION_KEY, ?USERS_KEY], [Lang, Trans, Users]),
    #'Desc'{id = Id, mime = Mime, payload = P,
        data = [#'Feature'{id = id(D, K), key = K, value = V}||{K, V}<-Fs]};
upd({'Desc',Id,<<"transcribe">> =Mime,Payload,_Size,Lang,Users} = D) ->
    Fs = lists:zip([?LANG_KEY, ?USERS_KEY], [Lang, Users]),
    #'Desc'{id = Id, mime = Mime, payload = Payload,
        data = [#'Feature'{id = id(D, K), key = K, value = V}||{K, V}<-Fs]};
upd({'Desc',Id,Mime,Payload,_Size,_Filename,_Info}) ->
    #'Desc'{id = Id, mime = Mime, payload = Payload};
upd(#'Message'{files = Descs}=M) ->
    M#'Message'{files = [upd(D)||D<-Descs]};
upd(#'Job'{data = Data}=J) -> J#'Job'{data = [upd(D)||D<-Data]};
upd(#'Star'{message = #'Message'{} = Msg}=S) -> S#'Star'{message = upd(Msg)};
upd(#'Star'{}) -> [];
upd(#'Roster'{favorite = Stars, roomlist = Rooms}=Roster) ->
	Roster#'Roster'{favorite = lists:flatten([upd(S)||S<-Stars]), roomlist = [upd(R)||R<-Rooms]};
upd(#writer{cache = MC, first = FC} = W) ->
    W#writer{cache = upd(MC), first = upd(FC)};
upd(#'Room'{data = Descs} = Room) ->
	Room#'Room'{data = [upd(D)||D<-Descs]}.

up() ->
    kvs:init(mnesia, roster), %% create StikerPack table
    mnesia:wait_for_tables(['StickerPack'], 1000),
    case kvs:all('StickerPack') of
        [] -> stickers_api:upload_pack();
        _ -> ok end,
	[kvs:put(upd(Record))|| Table<-['Room', 'Message', 'Job', 'Roster', writer], Record<-kvs:all(Table)],

    [kvs:put(M#'Message'{status = []})||#'Message'{status = internal}=M<-kvs:all('Message')],
    [case Desc of
	     #'Desc'{} -> ok;
		 _ -> false = M
     end || #'Message'{files = Descs} = M<-kvs:all('Message'), Desc <- Descs],
    ok.

down() ->
    ok.