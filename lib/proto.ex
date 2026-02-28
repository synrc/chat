defmodule CHAT.Proto do
  @moduledoc """
  High-performance TCP сервер для CHAT-протоколу v2 на базі Thousand Island.
  """

  use ThousandIsland.Handler

  require Record

  Record.defrecord(:io, Record.extract(:IO, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:ack, Record.extract(:Ack, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:error, Record.extract(:ERROR, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))

  for name <- [:Typing, :Message, :History, :Profile, :Roster, :Search, :Auth, :Presence, :Room, :Member, :FileDesc] do
    Record.defrecord(name, Record.extract(name, from_lib: "chat/include/CHAT.hrl"))
  end

  def start_link(port: port) do
    :logger.info(~c"Starting CHAT.Proto (Thousand Island) on 0.0.0.0:~p", [port])

    ThousandIsland.start_link(
      handler_module: __MODULE__,
      port: port,
      num_acceptors: System.schedulers_online() * 4,   # масштабується з кількістю ядер
      num_connections: :infinity,                      # знімаємо обмеження (контроль через OS ulimit)
      num_listen_sockets: 1,
      read_timeout: :infinity,                         # persistent chat-з'єднання
      shutdown_timeout: 30_000,
      transport_module: ThousandIsland.Transports.TCP,
      transport_options: [
        :binary,
        reuseaddr: true,
        nodelay: true,
        keepalive: true,
        backlog: 16_384,
        sndbuf: 1_048_576,
        recbuf: 1_048_576
      ]
    )
  end

  def child_spec(opt) do
    %{
      id: CHAT.Proto,
      start: {CHAT.Proto, :start_link, [opt]},
      type: :supervisor,
      restart: :permanent,
      shutdown: :infinity
    }
  end

  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
      {:continue, {<<>>, false}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, {buffer, expecting_body}) do
      new_buffer = buffer <> data
      process(new_buffer, socket, expecting_body)
  end

  def process(buffer, socket, true) do
      handle_message(buffer)
      {:continue, {<<>>, false}}
  end

  def process(buffer, socket, false) do
    case :binary.split(buffer, "\r\n\r\n") do
         [_, ""] -> {:continue, {buffer, true}}
         [_, body | _] when byte_size(body) > 0 -> handle_message(body) ; {:continue, {<<>>, false}}
          _ -> {:continue, {buffer, false}}
    end
  end

  def handle_message(<<>>), do: :ok

  def handle_message(body) do
    try do
      {:ok, dec} = :chat.decode(:'CHATMessage', body)
      {:CHATMessage, _no, _headers, {_tag, msg_body}} = dec
      info(msg_body, [], cx())
    catch
      _kind, _reason ->
        :ok
    end
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

  def info(roster = {:Roster, _, _, _, _, _, _}, req, cx() = state) do
    CHAT.Roster.info(roster, req, state)
  end

  def info(auth = {:Auth, _, _, _, _, _, _, _, _, _, _, _}, req, state) do
    CHAT.Auth.info(auth, req, state)
  end

  def info(message, req, state) do
    {:unknown, message, req, state}
  end

  @impl ThousandIsland.Handler
  def handle_close(_socket, _state), do: :ok

  @impl ThousandIsland.Handler
  def handle_error(reason, _socket, _state) do
    :logger.debug("CHAT connection error: ~p", [reason])
  end
end
