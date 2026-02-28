defmodule CHAT.X509 do
  @moduledoc """
  High-performance TCP сервер для CHAT-протоколу v2 на базі Thousand Island.
  """

  use ThousandIsland.Handler
  require Record
  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))
  for name <- [:'Feature', :'Authority', :'File', :'Message', :'Privatebox', :'Streambox', :'Groupbox', :'Mailbox', :'Inbox', :'Ack',
               :'Activity', :'Search', :'Subscription', :'Person', :'Server', :'Roster', :'Member', :'Conference', :'CHATMessage'] do
      Record.defrecord(name, Record.extract(name, from_lib: "chat/include/CHAT-v2.hrl"))
  end

  def start_link(port: port) do
    :logger.info(~c"Starting CHAT.X590 (Thousand Island) on 0.0.0.0:~p", [port])

    ThousandIsland.start_link(
      handler_module: __MODULE__,
      port: port,
      num_acceptors: System.schedulers_online() * 4,
      num_connections: :infinity,
      num_listen_sockets: 1,
      read_timeout: :infinity,
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
      id: CHAT.X509,
      start: {CHAT.X509, :start_link, [opt]},
      type: :supervisor,
      restart: :permanent,
      shutdown: :infinity
    }
  end

  # State: {buffer, expecting_body, client_id}
  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
    {:continue, {<<>>, false, nil}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, {buffer, expecting_body, client_id}) do
    new_buffer = buffer <> data
    process(new_buffer, socket, expecting_body, client_id)
  end

  def process(buffer, socket, true, client_id) do
    new_client_id = handle_message(buffer, socket, client_id)
    {:continue, {<<>>, false, new_client_id}}
  end

  def process(buffer, socket, false, client_id) do
    case :binary.split(buffer, "\r\n\r\n") do
      [_, ""] ->
        {:continue, {buffer, true, client_id}}
      [_, body | _] when byte_size(body) > 0 ->
        new_client_id = handle_message(body, socket, client_id)
        {:continue, {<<>>, false, new_client_id}}
      _ ->
        {:continue, {buffer, false, client_id}}
    end
  end

  def handle_message(<<>>, _socket, client_id), do: client_id

  def handle_message(body, socket, client_id) do
    try do
      {:ok, dec} = :'CHAT-v2'.decode(:'CHATMessage', body)
      {:'CHATMessage', no, headers, {tag, msg_body}} = dec
      cx_state = cx(params: client_id)
      case info(tag, msg_body, {no, headers, body}, cx_state) do
        {:reply, reply_body, _req, new_state} ->
          send_reply(socket, no, headers, reply_body)
          cx(params: new_client_id) = new_state
          new_client_id || client_id
        _ ->
          client_id
      end
    catch
      _kind, _reason ->
        client_id
    end
  end

  defp send_reply(_socket, _no, _headers, {:bert, <<>>}), do: :ok

  defp send_reply(socket, no, headers, {:bert, record}) do
    body = {choice_tag(elem(record, 0)), record}
    case :'CHAT-v2'.encode(:'CHATMessage', {:'CHATMessage', no, headers, body}) do
      {:ok, encoded} -> ThousandIsland.Socket.send(socket, encoded <> "\r\n\r\n")
      _ -> :ok
    end
  end

  defp choice_tag(:'Ack'),          do: :ack
  defp choice_tag(:'Message'),      do: :message
  defp choice_tag(:'Inbox'),        do: :inbox
  defp choice_tag(:'Roster'),       do: :roster
  defp choice_tag(:'Authority'),    do: :authority
  defp choice_tag(:'Activity'),     do: :activity
  defp choice_tag(:'Subscription'), do: :subscription
  defp choice_tag(:'Search'),       do: :search
  defp choice_tag(:'Conference'),   do: :conference

  # Dispatch by CHOICE tag from CHATProtocol
  def info(:activity,  msg_body, req, cx() = state), do: CHAT.Message.info(msg_body, req, state)
  def info(:message,   msg_body, req, cx() = state), do: CHAT.Message.info(msg_body, req, state)
  def info(:inbox,     msg_body, req, cx() = state), do: CHAT.Inbox.info(msg_body, req, state)
  def info(:roster,    msg_body, req, cx() = state), do: CHAT.Roster.info(msg_body, req, state)
  def info(:authority, msg_body, req,          state), do: CHAT.Auth.info(msg_body, req, state)
  def info(_tag,       msg_body, req,          state), do: {:unknown, msg_body, req, state}

  # Receive forwarded messages from other client connections
  def handle_info({:forward, encoded}, socket, state) do
    ThousandIsland.Socket.send(socket, encoded <> "\r\n\r\n")
    {:continue, state}
  end

  @impl ThousandIsland.Handler
  def handle_close(_socket, {_buffer, _expecting_body, client_id}) do
    CHAT.Registry.unregister(client_id)
  end

  @impl ThousandIsland.Handler
  def handle_error(reason, _socket, _state) do
    :logger.debug("CHAT connection error: ~p", [reason])
  end
end
