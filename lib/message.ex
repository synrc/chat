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

  def info(message(id: msg_id, status: status), req, cx(state: []) = state)
      when msg_id != [] and status != :update do
    ack = ack(id: msg_id)
    {:reply, {:bert, ack}, req, state}
  end

  def info(message(
        status: [],
        id: [],
        to: _feed,
        from: _from0,
        to: _to,
        type: _type,
        files: [file_desc(payload: _payload) | _] = _descs
      ), req, cx(client_pid: _c, params: _client_id, state: :ack) = state) do
    {:reply, {:bert, <<>>}, req, state}
  end

  def info(message(
        status: :edit,
        id: _id,
        to: _feed,
        from: _from,
        to: _to,
        mentioned: _mentioned,
        files: [file_desc(payload: _payload) | _] = _descs
      ), req, cx(params: _client_id, client_pid: _c, state: :ack) = state) do
    {:reply, {:bert, <<>>}, req, state}
  end

  def info(message(id: id, to: _feed, from: _from0, seenby: _seen, status: :delete), req,
           cx(params: _client_id, client_pid: _c, state: :ack) = state) when is_integer(id) do
    {:reply, {:bert, <<>>}, req, state}
  end

  def info(message(from: _from, to: _to), req, state) do
      {:reply, {:bert, {:error, :invalid_data}}, req, state}
  end

  def info(msg, req, state), do: {:unknown, msg, req, state}
end
