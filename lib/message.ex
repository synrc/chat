defmodule CHAT.Message do
  require Record

  Record.defrecord(:activity, Record.extract(:Activity, from_lib: "chat/include/CHAT-v2.hrl"))
  Record.defrecord(:message, Record.extract(:Message, from_lib: "chat/include/CHAT-v2.hrl"))
  Record.defrecord(:ack, Record.extract(:Ack, from_lib: "chat/include/CHAT-v2.hrl"))
  Record.defrecord(:file_desc, Record.extract(:File, from_lib: "chat/include/CHAT-v2.hrl"))

  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))

  def init(:ok), do: {:ok, %{}}

  def info(activity(nickname: _phone, comments: _comments), req, cx() = state) do
    {:reply, {:bert, <<>>}, req, state}
  end

  # New message: register sender, forward to recipient, ack back to sender
  def info(message(id: msg_id, from: from, to: feed, status: status), req, cx(state: []) = state)
      when msg_id != [] and status != :update do
    CHAT.Registry.register(from, self())
    {_no, _headers, encoded} = req
    forward(feed, encoded)
    ack = ack(id: msg_id)
    {:reply, {:bert, ack}, req, cx(state, params: from)}
  end

  def info(message(
        status: [],
        id: [],
        from: from,
        to: feed,
        files: [file_desc(payload: _payload) | _] = _descs
      ), req, cx(client_pid: _c, params: _client_id, state: :ack) = state) do
    CHAT.Registry.register(from, self())
    {_no, _headers, encoded} = req
    forward(feed, encoded)
    {:reply, {:bert, <<>>}, req, cx(state, params: from)}
  end

  def info(message(
        status: :edit,
        id: _id,
        from: from,
        to: feed,
        mentioned: _mentioned,
        files: [file_desc(payload: _payload) | _] = _descs
      ), req, cx(params: _client_id, client_pid: _c, state: :ack) = state) do
    CHAT.Registry.register(from, self())
    {_no, _headers, encoded} = req
    forward(feed, encoded)
    {:reply, {:bert, <<>>}, req, cx(state, params: from)}
  end

  def info(message(id: id, from: from, to: feed, seenby: _seen, status: :delete), req,
           cx(params: _client_id, client_pid: _c, state: :ack) = state) when is_integer(id) do
    CHAT.Registry.register(from, self())
    {_no, _headers, encoded} = req
    forward(feed, encoded)
    {:reply, {:bert, <<>>}, req, cx(state, params: from)}
  end

  def info(message(from: _from, to: _to), req, state) do
    {:reply, {:bert, {:error, :invalid_data}}, req, state}
  end

  def info(msg, req, state), do: {:unknown, msg, req, state}

  # Resolve the destination id from a MessageFeed CHOICE and forward
  defp forward(feed, encoded) do
    case feed_id(feed) do
      nil -> :ok
      to_id ->
        case CHAT.Registry.lookup(to_id) do
          {:ok, pid} -> send(pid, {:forward, encoded})
          :error -> :ok
        end
    end
  end

  defp feed_id({:private,  {:'Privatebox', address}}), do: address
  defp feed_id({:chan,     {:'Streambox',  channel}}),  do: channel
  defp feed_id({:mailbox,  {:'Mailbox',    channel}}),  do: channel
  defp feed_id({:group,    {:'Groupbox',   channel}}),  do: channel
  defp feed_id(_), do: nil
end
