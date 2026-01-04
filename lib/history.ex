defmodule Chat.History do
  @moduledoc "History Protocol"
  require Record

  Record.defrecord(:history, Record.extract(:History, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:message, Record.extract(:Message, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:io, Record.extract(:IO, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))

  def info(history(status: :get_reply, entity: id) = history_rec, req, cx(params: _client_id) = state)
      when id != [] and id != <<>> do
    reply_data = history(history_rec, data: [])
    {:reply, {:bert, reply_data}, req, state}
  end

  def info(history(status: :get) = history_rec, req, cx(state: []) = state) do
    info(history_rec, req, cx(state, state: {:status, :get}))
  end

  def info(
        history(status: :get, data: [message(feed: feed) | _]) = history_rec,
        req,
        state
      )
      when feed != [] and feed != <<>> do
    updated_history = history(history_rec, feed: feed)
    info(updated_history, req, state)
  end

  def info(
        history(
          status: :get,
          roster: _roster0,
          feed: _feed,
          size: _n,
          entity: _m_id,
          data: _msg_data
        ) = _history_rec,
        req,
        cx(params: _client_id, state: {:status, _initial_status}) = state
      ) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(
        history(status: :update, feed: _feed, entity: _m_id),
        req,
        cx(client_pid: _c, params: _client_id, state: :verified) = state
      ) do
    {:reply, {:bert, io()}, req, cx(state, state: [])}
  end

  def info(
        history(status: :update, entity: m_id) = history_rec,
        req,
        cx() = state
      )
      when m_id == 0 or m_id == [] or m_id == <<>> do
    info(history_rec, req, cx(state, state: :verified))
  end

  def info(
        history(status: :delete, feed: _feed),
        req,
        cx(client_pid: _c, params: _client_id) = state
      ) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(
        history(roster: _roster_id, size: _n, status: :get) = data,
        req,
        cx(params: _client_id) = state
      ) do
    reply_data = history(data, data: [])
    {:reply, {:bert, reply_data}, req, state}
  end

  def info(history() = _data, req, state) do
    {:reply, {:bert, <<>>}, req, state}
  end

  def info(msg, req, state) do
    {:unknown, msg, req, state}
  end
end
