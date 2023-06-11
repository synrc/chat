-module('20180710150211_update_channel_settings_feature_key_1738').
-behavior(db_migration).
-include_lib("roster/static/room_channel_var.hrl").
-export([up/0, down/0]).

%% Models to use

-record(muc,       {name = [] :: [] | binary() }).

-record('Feature', {id    = [] :: [] | binary(),
                   key   = [] :: [] | binary(),
                   value = [] :: [] | binary(),
                   group = [] :: [] | binary() }).

-record('Room',    {id          = [] :: [] | binary(),
                   name        = [] :: [] | binary(),
                   links       = [] :: [] | list(),
                   description = [] :: [] | binary(),
                   settings    = [] :: list(#'Feature'{}),
                   members     = [] :: list(),
                   admins      = [] :: list(),
                   data        = [] :: [] | list(),
                   type        = [] :: [] | atom() | group | channel,
                   tos         = [] :: [] | binary(),
                   tos_update  = 0  :: [] | integer(),
                   unread      = 0  :: [] | integer(),
                   mentions    = [] :: [] | list(integer()),
                   readers     = [] :: list(integer()),
                   last_msg    = [] :: [],
                   update      = 0  :: [] | integer(),
                   created     = 0  :: [] | integer(),
                   status      = [] :: [] | atom()}).

-record('Roster',  {id       = [] :: [] | integer(),
                   names    = [] :: [] | binary(),
                   surnames = [] :: [] | binary(),
                   email    = [] :: [] | binary(),
                   nick     = [] :: [] | binary(),
                   userlist = [] :: list(),
                   roomlist = [] :: list(#'Room'{}),
                   favorite = [] :: list(),
                   tags     = [] :: list(),
                   phone    = [] :: [] | binary(),
                   avatar   = [] :: [] | binary(),
                   update   = 0  :: [] | integer(),
                   status   = [] :: [] | atom()}).

%% Old Feature.key Names

-define(OLD_FKC_SUBSCRIBERS_COUNT, <<"SubscribersCount">>).
-define(OLD_FKC_ADMINS_COUNT, <<"AdminsCount">>).

update_feature_key(Features) ->
  lists:foldl(fun(#'Feature'{key = ExistingKey} = ExistingFeature, Acc) ->
    case ExistingKey of
      ?OLD_FKC_SUBSCRIBERS_COUNT -> Acc ++ [ExistingFeature#'Feature'{key = ?FKC_SUBSCRIBERS_COUNT}];
      ?OLD_FKC_ADMINS_COUNT -> Acc ++ [ExistingFeature#'Feature'{key = ?FKC_ADMINS_COUNT}];
      _ -> Acc ++ [ExistingFeature]
    end
  end, [], Features).

update_room_object(#'Room'{id = RoomId, settings = RoomFeatures} = Room) ->
  case roster_channel_helper:is_channel(#muc{name = RoomId}) of
    false -> Room;
    true -> Room#'Room'{settings = update_feature_key(RoomFeatures)}
  end.

update_roster_rooms(#'Roster'{roomlist = UserRooms}) ->
  lists:flatten([update_room_object(UserRoom) || UserRoom <- UserRooms]).

proceed_with_progress(Fun, ListToProceed) ->
  TotalLength = length(ListToProceed),
  [begin
     io:format("Element ~p of ~p~n", [ElNumber, TotalLength]),
     Fun(El)
   end || {El, ElNumber} <- lists:zip(ListToProceed, lists:seq(1, TotalLength))].

up() ->
%%   get all channels and update features there
  io:format("Room objects updating ~n"),
  proceed_with_progress(fun(El) -> kvs:put(update_room_object(El)) end, kvs:all('Room')),
%%   get all channels in Rosters and update features there
  io:format("Roster.roomlist objects updating ~n"),
  proceed_with_progress(fun(El) -> kvs:put(El#'Roster'{roomlist = update_roster_rooms(El)}) end, kvs:all('Roster')),
  ok.

down() ->
  ok.