-module('20180605155329_add_links_field_to_room_model').
-behavior(db_migration).
-export([up/0, down/0]).


-record('Room',         {id          = [] :: [] | binary(),
                         name        = [] :: [] | binary(),
                         links       = [] :: [] | list(),
                         description = [] :: [] | binary(),
                         settings    = [] :: list(),
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
                         status      = [] :: [] | create | join | leave
                                                | ban | unban | add | remove | mute | unmute
                                                | patch | get | delete | settings
                                                | voice | video }).


-record('RoomOld',      {id          = [] :: [] | binary(),
                         name        = [] :: [] | binary(),
                         description = [] :: [] | binary(),
                         settings    = [] :: list(),
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
                         status      = [] :: [] | create | join | leave
                                                | ban | unban | add | remove | mute | unmute
                                                | patch | get | delete | settings
                                                | voice | video }).

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

%%   add Room.link field and leave it empty
update_room(Room) ->
  roster:upd_record(Room, #'Room'.name, []).

update_roster_room(Room) ->
  OldSize = record_info(size, 'RoomOld'),
  case tuple_size(Room) of
    OldSize -> update_room(Room);
    _ -> Room
  end.

%%   add Room.link field and leave it empty
update_roster(#'Roster'{roomlist = Rooms} = Roster) ->
  UpdRooms = [ update_roster_room(R) || R <- Rooms],
  kvs:put(Roster#'Roster'{roomlist = UpdRooms}).

transform() ->
  mnesia:transform_table('Room', fun update_room/1, record_info(fields, 'Room')),
  ok.

up() ->
  roster:up_table('Room', record_info(size, 'RoomOld'), record_info(size, 'Room'), fun transform/0),
%%   update roster.roomlist
  [update_roster(Roster) || Roster <- kvs:all('Roster')],
  ok.

down() ->
  ok.