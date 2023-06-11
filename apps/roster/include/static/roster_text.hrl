%% ------------------------------------------------------------------
%% Errors and Info messages for Channel feature
%% ------------------------------------------------------------------

%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Room stuff (Common for Group and Channel)
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(SYS_MSG_UPDATE_ROOM_NAME, <<" is renamed to">>).
-define(SYS_MSG_UPDATE_ROOM_AVATAR, <<" avatar is updated">>).

-define(ERROR_ROOM_NOT_FOUND, <<"Room not found">>).


%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Group stuff
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(ROOM_AVATAR_MIME, <<"image">>).
-define(SYS_MSG_UPDATE_GROUP_NAME, iolist_to_binary(["Group", ?SYS_MSG_UPDATE_ROOM_NAME])).
-define(SYS_MSG_UPDATE_GROUP_AVATAR, iolist_to_binary(["Group", ?SYS_MSG_UPDATE_ROOM_AVATAR])).


%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Channel stuff
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(SYS_MSG_CREATE_CHANNEL, <<"Channel created">>).
-define(SYS_MSG_UPDATE_CHANNEL_NAME, iolist_to_binary(["Channel", ?SYS_MSG_UPDATE_ROOM_NAME])).
-define(SYS_MSG_UPDATE_CHANNEL_AVATAR, iolist_to_binary(["Channel", ?SYS_MSG_UPDATE_ROOM_AVATAR])).


-define(ERROR_CREATE_EXISTING_CHANNEL, <<"RCHIE1">>).
-define(ERROR_CHANNEL_NOT_FOUND, <<"RCHIE2">>).

-define(LINK_INVALID_FORMAT, <<"LNKIE1">>).
-define(LINK_NOT_AVAILABLE, <<"LNKIE2">>).
-define(MAX_LINKS_NUM_REACHED, <<"LNKIE3">>).
-define(ERROR_LINK_NOT_FOUND, <<"LNKIE4">>).

%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Member stuff
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(ERROR_MEMBER_NOT_FOUND, <<"MMBRIE1">>).