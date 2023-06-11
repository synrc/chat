-ifndef(ROOM_HRL).
-define(ROOM_HRL, true).

-type roomType()      :: group | channel.
-type linkStatus()    :: lgen | lcheck | ladd | ldelete | lupdate.
-type memberStatus()  :: admin | member | removed | patch | owner.
-type roomStatus()    :: room_create | room_leave| room_add | room_remove | room_patch |
                         room_get | room_delete | room_last_msg.


-record('Member',       {id        = [] :: [] | integer(),
                         container = chain :: container(),
                         feed_id   = [] :: #muc{} | #p2p{},
                         prev      = [] :: [] | integer(),
                         next      = [] :: [] | integer(),
                         feeds     = [] :: list(),
                         phone_id  = [] :: [] | binary(),
                         avatar    = [] :: [] | binary(),
                         names     = [] :: [] | binary(),
                         surnames  = [] :: [] | binary(),
                         alias     = [] :: [] | binary(),
                         reader    = 0  :: [] | integer(),
                         update    = 0  :: [] | integer(),
                         settings  = [] :: list(#'Feature'{}),
                         services  = [] :: list(#'Service'{}),
                         presence  = offline :: presence(),
                         member_status    = member :: memberStatus()}).

-record('Link',         {id         = [] :: [] | binary(),  %% link value
                         name       = [] :: [] | binary(),  %% unused atm
                         room_id    = [] :: [] | binary(),  %% parent Room id
                         created    = [] :: [] | integer(), 
                         type       = [] :: [] | group | channel,
                         status     = [] :: [] | gen | check | add %% old unused fields
                                               | get | join |  update | delete}). %% new fields

-record('Room',         {id          = [] :: [] | binary(),
                        name        = [] :: [] | binary(),
                        links       = [] :: [] | binary(),
                        description = [] :: [] | binary(),
                        settings    = [] :: list(#'Feature'{}),
                        members     = [] :: list(#'Member'{}),
                        admins      = [] :: list(#'Member'{}),
                        data        = [] :: list(#'Desc'{}),
                        type        = [] :: [] | group | channel,
                        tos         = [] :: [] | binary(),
                        tos_update  = 0  :: [] | integer(),
                        unread      = 0  :: [] | integer(),
                        mentions    = [] :: list(integer()),
                        readers     = [] :: list(integer()),
                        last_msg    = [] :: [] | integer() | #'Message'{},
                        update      = 0  :: [] | integer(),
                        created     = 0  :: [] | integer(),
                        status      = [] :: [] | create | leave| add | remove | removed | join
                                               | patch | get | delete | last_msg | mute | unmute}).

-endif.
