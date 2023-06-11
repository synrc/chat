%% ------------------------------------------------------------------
%% Errors and info messages for rest modules
%% ------------------------------------------------------------------

-define(TEST_API_ENDPOINT, "/test").

-define(RESPONSE_200, <<"Success">>).

-define(ERROR_400, <<"Bad Request">>).
-define(ERROR_401, <<"Unauthorized">>).
-define(ERROR_403, <<"Forbidden">>).
-define(ERROR_404, <<"Not Found">>).
-define(ERROR_405, <<"Method Not Allowed">>).
-define(ERROR_INVALID_JSON, <<"Invalid Request Json">>).
-define(ERROR_MISSING_PARAM, <<"Missing Request Parameter(s)">>).
-define(ERROR_INVALID_REQUEST_PARAM, <<"Invalid Request Parameter(s)">>).
-define(ERROR_MISSING_HEADER, <<"Missing Request Header(s)">>).
-define(ERROR_PERMISSION_DENIED, <<"Permission Denied">>).

%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Rest Publish Module
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(ERROR_INVALID_QOS_PARAM, <<"Invalid 'qos' Param. Valid Values: 0, 1, 2">>).
-define(ERROR_INVALID_MESSAGE_PARAM, <<"Invalid 'message' Param. Should be base64 encoded bytearray">>).

%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%% Call Room Interface Module
%% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

-define(ERROR_USER_404, <<"User Not Found">>).
-define(IS_MEMBER_FLAG, <<"is_member">>).
-define(ROOM_TYPE_VALUE, <<"type">>).

-define(CALL_TYPE_P2P, <<"p2p">>).
-define(CALL_TYPE_CONFERENCE, <<"conference">>).

-define(CONTENT_TYPE_VIDEOCALL, <<"videoCall">>).
-define(CONTENT_TYPE_AUDIOCALL, <<"audioCall">>).

%% feature object for call bubbles
-define(CALL_FG_CALL_DATA, <<"CALL_DATA">>).
-define(CALL_FK_DURATION, <<"DURATION">>).
-define(CALL_FK_START_TIME, <<"START_TIME">>).
-define(CALL_FK_CONFERENCE_ID, <<"CONFERENCE_ID">>).
-define(CALL_FK_ENDED_BY, <<"ENDED_BY">>).
-define(CALL_FK_COUNT, <<"COUNT">>).