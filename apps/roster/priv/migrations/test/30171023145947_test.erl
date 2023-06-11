-module('30171023145947_test').
-behavior(db_migration).
-export([up/0, down/0]).

-record('MigresiaTest', {id, field1, field2, field3}).

up() ->
    roster:stop_vnodes(),
    roster:recompile_roster([roster_test]),
    mnesia:transform_table('MigresiaTest',
        fun({'MigresiaTest', Id, F1, F2}) ->
            #'MigresiaTest'{id = Id, field1 = F1, field2 = F2, field3 = F2+1}
        end, record_info(fields, 'MigresiaTest')),
    kvs:put({'MigresiaTest', 101, 101, 101, 102}),
    roster:start_vnodes(), ok.

down() -> ok.
