-module('20181012141608_link_desc_re').
-behavior(db_migration).
-export([up/0, down/0]).

-include_lib("../../include/roster.hrl").

upd(#'Message'{files = Descs} = Msg) ->
    Msg#'Message'{files = lists:flatten([roster:parse_desc(Desc)|| #'Desc'{} = Desc<-Descs])}.

up() ->
    [case upd(M) of
         #'Message'{files = Descs2} when length(Descs) == length(Descs2) -> [];
         Msg -> kvs:put(Msg)
     end || M = #'Message'{files = Descs, type = Type} <- kvs:all('Message'), Type /= [sys]],
    ok.

down() ->
    ok.
