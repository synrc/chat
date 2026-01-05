defmodule CHAT.Proto do
  require Record

  Record.defrecord(:io, Record.extract(:IO, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:ack, Record.extract(:Ack, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:error, Record.extract(:ERROR, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))

  def start_link(port: port), do: {:ok, :erlang.spawn_link(fn -> listen(port) end)}
  def child_spec(opt) do
      %{
        id: CHAT.Proto,
        start: {CHAT.Proto, :start_link, [opt]},
        type: :supervisor,
        restart: :permanent,
        shutdown: 500
      }
  end

  def listen(port) do
      :logger.info ~c"Running CHAT.Application at 0.0.0.0:~p (tcp)", [port]
      {:ok, socket} = :gen_tcp.listen(port, [:binary, {:active, false}, {:reuseaddr, true}])
      accept(socket)
  end

  def accept(socket) do
      {:ok, fd} = :gen_tcp.accept(socket)
      {:ok, _pid} = Task.Supervisor.start_child(CHAT.TaskSupervisor, fn -> loop(fd,[]) end, restart: :temporary)
      accept(socket)
  end

  def loop(socket,ca) do
      case :gen_tcp.recv(socket, 0) do
           {:error, _} -> :exit
           {:ok, stage1} ->
               try do
                 [_headers|body] = :string.split stage1, "\r\n\r\n", :all
                 case body do
                    [""] -> case :gen_tcp.recv(socket, 0) do
                                 {:error, _} -> :exit
                                 {:ok, stage2} -> handleMessage(socket,stage2) end
                       _ -> handleMessage(socket,body)
                 end
                 __MODULE__.loop(socket,ca)
               catch _ ->
                 __MODULE__.loop(socket,ca)
               end
      end
  end

  def handleMessage(_socket, body) do
      {:ok, dec} = :'CHAT'.decode(:'CHATMessage', body)
      {:CHATMessage, _no, _headers, {_tag, body}} = dec
      __MODULE__.info(body, [], cx())
  end

  for name <- [ :Typing, :Message, :History, :Profile, :Roster, :Search, :Auth, :Presence, :Room, :Member, :FileDesc] do
    Record.defrecord(name, Record.extract(name, from_lib: "chat/include/CHAT.hrl"))
  end

  def info(typing = {:Typing, _, _, _}, req, cx() = state) do
    CHAT.Message.info(typing, req, state)
  end

  def info(message = {:Message, _, _, _, _, _, _, _, _, _, _, _, _, _}, req, cx() = state) do
    CHAT.Message.info(message, req, state)
  end

  def info(history = {:History, _, _, _, _, _, _, _}, req, cx() = state) do
    CHAT.History.info(history, req, state)
  end

  def info(profile = {:Profile, _, _, _, _, _, _, _, _, _, _, _}, req, cx() = state) do
    CHAT.Profile.info(profile, req, state)
  end

  def info(roster = {:Roster, _, _, _, _, _, _}, req, cx() = state) do
    CHAT.Roster.info(roster, req, state)
  end

  def info(auth = {:Auth, _, _, _, _, _, _, _, _, _, _, _}, req, state) do
    CHAT.Auth.info(auth, req, state)
  end

  def info(message, req, state) do
    {:unknown, message, req, state}
  end
end
