-module(chat_proto).
-include_lib("chat/include/chat.hrl").
-include_lib("n2o/include/n2o.hrl").
-export([info/3]).

info(#'Typing'{}       = Typing,       Req, #cx{params = <<"emqttd_",_/binary>>} = State) -> roster_message         :info(Typing,       Req, State);
info(#'Message'{}      = Message,      Req, #cx{params = <<"emqttd_",_/binary>>} = State) -> roster_message         :info(Message,      Req, State);
info(#'Message'{}      = Message,      Req, #cx{params = <<"sys_"   ,_/binary>>} = State) -> roster_message         :info(Message,      Req, State);
info(#'History'{}      = History,      Req, #cx{params = <<"emqttd_",_/binary>>} = State) -> roster_history         :info(History,      Req, State);
info(#'Profile'{}      = Profile,      Req, #cx{params = <<"sys_"   ,_/binary>>} = State) -> roster_profile         :info(Profile,      Req, State);
info(#'Profile'{}      = Profile,      Req, #cx{params = <<"emqttd_",_/binary>>} = State) -> roster_profile         :info(Profile,      Req, State);
info(#'Roster'{}       = Roster,       Req, #cx{params = <<"emqttd_",_/binary>>} = State) -> roster_roster          :info(Roster,       Req, State);
info(#'Search'{}       = Search,       Req, #cx{params = <<"emqttd_",_/binary>>} = State) -> roster_search          :info(Search,       Req, State);
info(#'Auth'{}         = Auth,         Req,                                        State) -> roster_auth            :info(Auth,         Req, State);
info(Message, Req, State)                                                                 -> {unknown, Message, Req, State}.
