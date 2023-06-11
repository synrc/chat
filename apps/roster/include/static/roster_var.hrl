%% ------------------------------------------------------------------
%% Static Variables for modules
%% ------------------------------------------------------------------
-define(LINK_URL, "https://link.nynja.net/").

%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Room stuff
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(CALL_ROOM, call).

%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Channel stuff
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(MAX_LINKS_NUM, 3).
-define(LINK_LEN_MIN, 2).
-define(LINK_LEN_MAX, 48).
-define(LINK_REGEXP, <<"^[a-zA-Z0-9_]{~w,~w}$">>).
-define(LINK_ALLOWED_CHARS, <<"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_">>).
-define(CHANNEL_UPDATE_EXCLUDED_FIELDS, [id, links, created, admins, members, tos_update, last_msg, unread, readers, settings]).

-define(LINK_INDEX_KEYWORD, link).

%% FGC - Feature Group for Channel
%% FKC - Feature Key for Channel

-define(FGC_INFO, <<"CHANNEL_DATA">>).
-define(FKC_SUBSCRIBERS_COUNT, <<"SUBSCRIBERS_COUNT">>).
-define(FKC_ADMINS_COUNT, <<"ADMINS_COUNT">>).

-define(FGC_ADMIN_PERMISSIONS, <<"ADMIN_PERMISSIONS_DATA">>).
-define(FKC_INFO_MNGT, <<"INFO_MNGT">>).
-define(FKC_POST_MSG, <<"POST_MSG">>).
-define(FKC_EDIT_MSG, <<"EDIT_MSG">>).
-define(FKC_DELETE_MSG, <<"DELETE_MSG">>).
-define(FKC_ADD_SUBSCR, <<"ADD_SUBSCR">>).
-define(FKC_SUBSCR_MNGT, <<"SUBSCR_MNGT">>).
-define(FKC_LINK_MNGT, <<"LINK_MNGT">>).
-define(FKC_HISTORY_MNGT, <<"HISTORY_MNGT">>).

%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Member stuff
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(CHANNEL_MEMBER_UPDATE_EXCLUDED_FIELDS, [id, container, feed_id, prev, next, feeds, phone_id, names, surnames, vox_id, reader, presence, status]).