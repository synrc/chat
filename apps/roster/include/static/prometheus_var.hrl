%% ------------------------------------------------------------------
%% Static Variables for Prometheus modules
%% ------------------------------------------------------------------

%% -define(METRIC_P2P_TOTAL, enc_private_chats_count).
%% -define(METRIC_GROUP_TOTAL, enc_group_chats_count).
-define(METRIC_CHATS_TOTAL, nynja_chats_total).
-define(METRIC_USERS_PER_COUNTRY, nynja_users_total).
-define(METRIC_USERS_PER_COUNTRY_ONLINE, nynja_active_users_total).
-define(METRIC_MSGS_BY_TYPE_NMBR, nynja_messages_total).
-define(METRIC_SESSIONS_PER_COUNTRY_ONLINE, enc_sessions_total).


-define(METRIC_LABEL_COUNTRY, country).
-define(METRIC_LABEL_MIMETYPE, mimetype).
-define(METRIC_LABEL_TYPE, type).

-define(METRIC_LABEL_P2P_CHAT, p2p).
-define(METRIC_LABEL_GROUP_CHAT, group).