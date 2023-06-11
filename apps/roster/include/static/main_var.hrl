%% ------------------------------------------------------------------
%% Variables common for multiple modules
%% ------------------------------------------------------------------

-define(SYS_MSG_TYPE, [sys]).

%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Atom Statuses
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(CREATE_STATUS, create).
-define(ADD_STATUS, add).
-define(DELETE_STATUS, delete).
-define(REMOVE_STATUS, remove).
-define(JOIN_STATUS, join).

-define(VIDEO_THUMBNAIL_DEFAULT, <<"https://s3-us-west-2.amazonaws.com/nynja-defaults/ic_video_without_thumbnail.png">>).