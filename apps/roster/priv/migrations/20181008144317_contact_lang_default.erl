-module('20181008144317_contact_lang_default').
-behavior(db_migration).
-export([up/0, down/0]).

-include_lib("../../include/roster.hrl").

id(PhoneId, Key) -> <<PhoneId/binary, "_", Key/binary>>.

default(#'Contact'{phone_id = PhoneId}, FriendId) ->
    {ok, #'Profile'{settings = Settings} = Profile} = kvs:get('Profile', roster:phone(PhoneId)),
    LangSetting = #'Feature'{value = DefaultLang} =
        case lists:keyfind(K = <<"DEFAULT_LANGUAGE">>, #'Feature'.key, Settings) of
            false ->
                F = #'Feature'{id = id(FriendId, K), key = K, value = <<"English:en">>, group = <<"LANGUAGE_SETTING">>},
                kvs:put(Profile#'Profile'{settings = [F | Settings]}), F;
            F -> F end,

    Fs = [{<<"AUTO_TRANSLATE">>           , <<"false">>},
        {<<"AUTO_OUTGOING_TRANSLATE">>    , <<"Off">>},
        {<<"AUTO_TRANSLATE_TRANSCRIBE">>  , <<"false">>},
        {<<"AUTO_TRANSCRIBE">>            , <<"true">>},
        {<<"TRANSCRIBE_LANGUAGE">>        , DefaultLang}],
    lists:ukeysort(#'Feature'.key, lists:flatten([LangSetting|
        [#'Feature'{id = id(FriendId, Key), key = Key, value = Default, group = <<"LANGUAGE_SETTING">>}
            || {Key, Default}<-Fs]])).

feature(Key, #'Feature'{} = F, PhoneId) ->
    F#'Feature'{id = id(PhoneId, Key), key = Key, group = <<"LANGUAGE_SETTING">>}.

upd(F = #'Feature'{key = <<"AUTO_TRANSLATE">>}, _FriendId) ->
    F#'Feature'{value = <<"false">>};
upd(F = #'Feature'{key = <<"AUTO_TRANSLATE_TRANSCRIBE">>}, _FriendId) ->
    F#'Feature'{value = <<"false">>};
upd(F = #'Feature'{key = <<"AUTO_TRANSCRIBE">>}, _FriendId) ->
    F#'Feature'{value = <<"true">>};
upd(F = #'Feature'{key = <<"CHAT_LANGUAGE">>}, _FriendId) -> F;
upd(F = #'Feature'{key = <<"AUTO_LANGUAGE_IN_CHAT">>}, FriendId) -> feature(<<"AUTO_TRANSLATE">>, F, FriendId);
upd(F = #'Feature'{key = <<"AUTO_TRANSLATE_LANGUAGE">>}, FriendId) ->
    feature(<<"AUTO_OUTGOING_TRANSLATE">>, F#'Feature'{value = <<"Off">>}, FriendId);
upd(F = #'Feature'{key = <<"TRANSLATE_LANGUAGE">>, value  = <<"None:none">>}, FriendId) ->
    upd(F#'Feature'{value = <<"English:en">>}, FriendId);
upd(F = #'Feature'{key = <<"TRANSLATE_LANGUAGE">>}, FriendId) ->
    feature(<<"OUTGOING_TRANSLATE_LANGUAGE">>, F, FriendId);
upd(#'Feature'{} = F, _Id) -> F;

upd(#'Contact'{settings = Settings} = C, FriendId) ->
    NewSettings = lists:ukeymerge(#'Feature'.key,
        lists:ukeysort(#'Feature'.key, lists:flatten([upd(F, FriendId)||F<-Settings])),
        default(C, FriendId)),
    C#'Contact'{settings = NewSettings}.
upd(#'Roster'{id = RosterId, phone = Phone, userlist = Contacts, roomlist = Rooms} = Roster) ->
    Roster#'Roster'{userlist = [upd(C, roster:phone_id(Phone, RosterId)) || #'Contact'{} = C <-Contacts],
        roomlist = [Room || #'Room'{} = Room<-Rooms]};
upd(#'Member'{phone_id = PhoneId, settings = []} = Member) ->
    case kvs:get('Profile', roster:phone(PhoneId)) of
        {ok, #'Profile'{settings = Settings}} ->  Member#'Member'{settings = Settings};
        _ -> Member end;
upd(#'Member'{} = Member) -> Member.

up() ->
    [kvs:put(upd(R))||#'Roster'{} = R <- kvs:all('Roster')],
%%    [] = [R||#'Roster'{userlist = Contacts} = R <- kvs:all('Roster'),
%%        #'Contact'{settings = Settings}<-Contacts,
%%        #'Feature'{key = <<"CHAT_LANGUAGE">>}<-Settings],

    [] = [[]||#'Profile'{settings = []}<-kvs:all('Profile')],
    [kvs:put(upd(Member))||Member<-kvs:all('Member')],
    ok.

down() ->
    ok.