-module(roster_file).
-include_lib("chat/include/roster.hrl").
-include_lib("n2o/include/n2o.hrl").
-include_lib("kernel/include/file.hrl").
-compile(export_all).

start() -> n2o_pi:start(#pi{module = ?MODULE, table = system, sup = roster, name = <<"File Service">>, state = []}).

info(#ftp{status = {event, _}} = FTP, Req, State) -> {reply, {bert, #ftp{}}, Req, State};
info(#ftp{id = Link, status = <<"init">>, block = Block, offset = Offset} = FTP, Req, State) -> {reply, {bert, #ftp{}}, Req, State};
info(#ftp{id = Link, status = <<"send">>} = FTP, Req, State) -> {reply, {bert, #ftp{}}, Req, State};
info(Message, Req, State) -> {unknown, Message, Req, State}.

proc(init, #pi{state = #ftp{sid = Sid, meta = ClientId} = FTP} = Async) -> {ok, Async};
proc(#ftp{id=L, sid=S, data=D, status= <<"send">>, block=B,meta=C}=FTP, #pi{state=#ftp{size=TS,offset=O,filename=F}}=Async) when O+B >= TS -> {stop, normal, FTP, Async#pi{state = FTP}};
proc(#ftp{data=Data, block=B} = FTP, #pi{state = #ftp{offset=O, filename=F}} = Async) -> {reply, FTP#ftp{data = <<>>}, Async#pi{state = FTP#ftp{filename = F}}};
proc(_, Async) -> {reply, #ftpack{}, Async}.

