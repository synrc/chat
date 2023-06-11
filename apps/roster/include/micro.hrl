-ifndef(MICRO_HRL).
-define(MICRO_HRL, true).

-define(SYS_BRIDGE_TEST_CLIENT,    <<"sys_micro_bridge_test">>).

-define(IS_UUID, <<_/integer,_/integer,_/integer,_/integer,_/integer,_/integer,_/integer,_/integer,"-",
    _/integer,_/integer,_/integer,_/integer, "-", _/integer,_/integer,_/integer,_/integer, "-",
    _/integer,_/integer,_/integer,_/integer, "-",
    _/integer,_/integer,_/integer,_/integer,_/integer,_/integer,_/integer,_/integer,_/integer,_/integer,_/integer,_/integer>>).


-record('LinkRoster', {id = [] :: binary(),
                  phone_id = [] :: binary()}).

-record('LinkProfile', {id = [] :: binary(),
                       phone = [] :: binary()}).

-endif.