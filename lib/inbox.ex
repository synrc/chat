defmodule CHAT.Inbox do
  require Record

  Record.defrecord(:inbox, Record.extract(:Inbox, from_lib: "chat/include/CHAT-v2.hrl"))
  Record.defrecord(:message, Record.extract(:Message, from_lib: "chat/include/CHAT-v2.hrl"))
  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))

  def info(inbox(type: :get_reply, id: id) = inbox_rec, req, cx(params: _client_id) = state)
      when id != [] and id != <<>> do
    reply_data = inbox(inbox_rec, messages: [])
    {:reply, {:bert, reply_data}, req, state}
  end

  def info(inbox(type: :get) = inbox_rec, req, cx(state: []) = state) do
    info(inbox_rec, req, cx(state, state: {:status, :get}))
  end

  def info(
        inbox(type: :get, messages: [message(to: feed) | _]) = inbox_rec,
        req,
        state
      )
      when feed != [] and feed != <<>> do
    updated_inbox = inbox(inbox_rec, feed: feed)
    info(updated_inbox, req, state)
  end

  def info(
        inbox(
          type: :get,
          feed: _feed,
          id: _m_id,
          messages: _msg_data
        ) = _inbox_rec,
        req,
        cx(params: _client_id, state: {:status, _initial_status}) = state
      ) do
    {:reply, {:bert, <<>>}, req, state}
  end

  def info(
        inbox(type: :update, feed: _feed, id: _m_id),
        req,
        cx(client_pid: _c, params: _client_id, state: :verified) = state
      ) do
    {:reply, {:bert, <<>>}, req, cx(state, state: [])}
  end

  def info(
        inbox(type: :update, id: m_id) = inbox_rec,
        req,
        cx() = state
      )
      when m_id == 0 or m_id == [] or m_id == <<>> do
    info(inbox_rec, req, cx(state, state: :verified))
  end

  def info(
        inbox(type: :delete, feed: _feed),
        req,
        cx(client_pid: _c, params: _client_id) = state
      ) do
    {:reply, {:bert, <<>>}, req, state}
  end

  def info(
        inbox(id: _roster_id, type: :get) = data,
        req,
        cx(params: _client_id) = state
      ) do
    reply_data = inbox(data, messages: [])
    {:reply, {:bert, reply_data}, req, state}
  end

  def info(inbox() = _data, req, state) do
    {:reply, {:bert, <<>>}, req, state}
  end

  def info(msg, req, state) do
    {:unknown, msg, req, state}
  end
end
