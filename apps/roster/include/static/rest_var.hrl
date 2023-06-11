%% ------------------------------------------------------------------
%% Static Variables for REST modules
%% ------------------------------------------------------------------

%% Endpoints
-define(SESSIONS_ENDPOINT, "/sessions").

-define(WHITELIST_ENDPOINT, "/whitelist").
-define(ADMIN_WHITELIST_ENDPOINT, "/admin_whitelist").

%% FN is for Fake Numbers
-define(ADMIN_FN_ENDPOINT, "/fake_numbers").
-define(FN_ENDPOINT, "/fn").

-define(MSG_PUSH_ENDPOINT, "/push/message").
-define(ROOM_ENDPOINT, "/room").
-define(PUBLISH_ENDPOINT, "/publish").
-define(USERS_ENDPOINT, "/users").
-define(METRICS_ENDPOINT, "/metrics").

-define(RCI_ROOM_TYPE_ENDPOINT, "/cri/rooms/type").
-define(RCI_ROOM_ENDPOINT, "/cri/rooms").
-define(RCI_ROOM_MEMBERS_ENDPOINT, "/cri/rooms/members").
-define(RCI_BUBBLE_ENDPOINT, "/cri/bubbles").

%% Request Query and Body Param Names
-define(PHONE_ID_HEADER, "PhoneId").

-define(ROOM_ID_PARAM, "room_id").
-define(PHONE_IDS_PARAM, "phone_ids").
-define(PHONE_ID_PARAM, "phone_id").
-define(JOIN_FLAG_PARAM, "join").

%% sessions module
-define(PHONE_PARAM, "phone").



%% HTTP Status Codes
-define(HTTP_CODE_200, 200).
-define(HTTP_CODE_400, 400).
-define(HTTP_CODE_401, 401).
-define(HTTP_CODE_403, 403).
-define(HTTP_CODE_404, 404).
-define(HTTP_CODE_405, 405).