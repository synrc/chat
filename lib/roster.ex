defmodule Chat.Roster do
  require Record

  Record.defrecord(:roster, Record.extract(:Roster, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:contact, Record.extract(:Contact, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:io, Record.extract(:IO, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))
  Record.defrecord(:pi, Record.extract(:pi, from_lib: "chat/include/roster.hrl"))

  def info(roster(status: :list), req, cx(params: _client_id) = state) do
    {:reply, {:bert, io()}, req, cx(state, state: [])}
  end

  def info(roster(status: :add, id: _roster_id, contacts: _roster_list), req,
           cx(params: _client_id, session: _token) = state) do
    {:reply, {:bert, io()}, req, cx(state, state: [])}
  end

  def info(roster(status: :del, id: _roster_id), req,
           cx(params: _client_id, session: _token) = state) do
    {:reply, {:bert, io()}, req, cx(state, state: [])}
  end

  def info(roster(status: :patch, id: _roster_id0), req, cx(params: _client_id) = state) do
    {:reply, {:bert, io()}, req, cx(state, state: [])}
  end

  def info(roster(status: :nicknameid, id: _roster_id, nickname: _nickname_to_be_validated), req,
           cx(params: _client_id, client_pid: _c) = state) do
    {:reply, {:bert, io()}, req, cx(state, state: [])}
  end

  def info(roster(status: :get, id: _roster_id), req, cx(params: _client_id) = state) do
    {:reply, {:bert, io()}, req, cx(state, state: [])}
  end

  def info(roster(status: _status, id: _roster_id), req, cx(params: _client_id) = state) do
    {:reply, {:bert, io()}, req, cx(state, state: [])}
  end

  def info(msg, req, state) do
    {:unknown, msg, req, state}
  end

  def proc(:init, pi(name: __MODULE__) = async) do
    {:ok, async}
  end

  def proc({:update_contact, contact(phone: _phone_id)}, pi() = h) do
    {:reply, [], h}
  end

  def proc({:update_roster, roster(id: _roster_id, nickname: _nickname)}, pi() = h) do
    {:reply, [], h}
  end

  def proc({:delete_roster, roster(id: _roster_id, nickname: _nickname)}, pi() = h) do
    {:reply, [], h}
  end

  def proc(_msg, state) do
    {:noreply, state}
  end
end
