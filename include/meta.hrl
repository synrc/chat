-ifndef(CHAT_META_HRL).
-define(CHAT_META_HRL, true).

% client x-forms

-type icons() :: bin | heart | update | more | search | export | toggle | read | qr | user | users | add | edit | avatar.
-record(header, { name = [], icons = []}).
-record(footer, { modules = []}).
-record(section, { name = [], rows = []}).
-record(row, { no = [], lico = [], rico = [], desc = [] }).
-record(screen, { no = [], name = [], hd = [], ft = [], sections = []}).

-endif.
