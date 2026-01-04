defmodule Chat.Message do
  require Record

  Record.defrecord(:typing, Record.extract(:Typing, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:message, Record.extract(:Message, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:ack, Record.extract(:Ack, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:io, Record.extract(:IO, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:error, Record.extract(:ERROR, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:file_desc, Record.extract(:FileDesc, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))

  def init(:ok), do: {:ok, %{}}

  def info(typing(nickname: _phone, comments: _comments), req, cx() = state) do
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
        feed: _feed,
        from: _from0,
        to: _to,
        type: _type,
        files: [file_desc(payload: _payload) | _] = _descs
      ), req, cx(client_pid: _c, params: _client_id, state: :ack) = state) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(message(
        status: :edit,
        id: _id,
        feed: _feed,
        from: _from,
        to: _to,
        mentioned: _mentioned,
        files: [file_desc(payload: _payload) | _] = _descs
      ), req, cx(params: _client_id, client_pid: _c, state: :ack) = state) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(message(id: id, feed: _feed, from: _from0, seenby: _seen, status: :delete), req,
           cx(params: _client_id, client_pid: _c, state: :ack) = state) when is_integer(id) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(message(from: _from, to: _to), req, state) do
    error_rec = error(code: :invalid_data)
    io_rec = io(code: error_rec)
    {:reply, {:bert, io_rec}, req, state}
  end

  def info(msg, req, state), do: {:unknown, msg, req, state}
end
