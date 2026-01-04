-ifndef(CHAT_IO_HRL).
-define(CHAT_IO_HRL, true).

-record(io,             {code=[], data=[]}).
-record(ok,             {code = [] :: [] | atom(), src=[] :: [] | {binary(), binary()} | binary() }).
-record(error ,         {code = [] :: [] | atom(), src=[] :: [] | binary() | integer() }).
-record(errors,         {code = [] :: [] | list(binary()), data = [] :: [] | term()}).
-record(cx, { handlers  = [] :: list({atom(),atom()}),
              actions   = [] :: list(tuple()),
              req       = [] :: [] | term(),
              module    = [] :: [] | atom() | list(),
              lang      = [] :: [] | atom(),
              path      = [] :: [] | binary(),
              session   = [] :: [] | binary(),
              token     = [] :: [] | binary(),
              formatter = bert :: bert | json | atom(),
              params    = [] :: [] | list(tuple()) | binary() | list(),
              node      = [] :: [] | atom() | list(),
              client_pid= [] :: [] | term(),
              state     = [] :: [] | term(),
              from      = [] :: [] | binary(),
              vsn       = [] :: [] | binary() }).

-record(pi, { name     :: term(),
              table    :: atom(),
              sup      :: atom(),
              module   :: atom(),
              timeout   = 5000 :: integer(),
              restart   = transient :: atom(),
              state    :: term()  }).

-endif.
