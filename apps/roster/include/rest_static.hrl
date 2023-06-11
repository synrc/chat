%% ------------------------------------------------------------------
%% Static Variables, Errors and Info messages for REST API feature
%% ------------------------------------------------------------------

-ifndef(CHANNEL_TEXT_HRL).
-define(CHANNEL_TEXT_HRL, true).

-define(ROOM_LINK_KEY, "link").
-define(QUERY_PARAM_NOT_FOUND, <<"Query Parameter Not Found, Check your request">>).
-define(CHANNEL_NOT_FOUND, <<"Channel not found">>).

%% GET ROOM BY ID RESPONSE FIELDS
-define(FOUND_ROOM_ID, <<"id">>).
-define(FOUND_ROOM_NAME, <<"name">>).
-define(FOUND_ROOM_AVATAR, <<"avatar">>).
-define(FOUND_ROOM_DESCRIPTION, <<"description">>).

-define(AWS_ACCESS_KEY_ID, proplists:get_value(access_key_id, application:get_env(roster, amazon_api, []))).
-define(AWS_SECRET_ACCESS_KEY, proplists:get_value(secret_access_key, application:get_env(roster, amazon_api, []))).


%% TODO replace it to separate hrl module
-record('CallBubbleJSON', {
    feed_id      = [] :: [] | binary(),
    call_id      = [] :: [] | binary(),
    type         = [] :: [] | binary(),
    recipients   = [] :: [] | list(),
    duration     = 0  :: [] | integer(),
    start_time   = 0  :: [] | integer(),
    status       = [] :: [] | binary(),
    content_type = [] :: [] | binary(),
    ended_by     = [] :: [] | binary(),
    count        = 0  :: [] | integer()}).

-endif.