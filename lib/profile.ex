defmodule Chat.Profile do
  @moduledoc "Profile Protocol"
  require Record

  Record.defrecord(:profile, Record.extract(:Profile, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:io, Record.extract(:IO, from_lib: "chat/include/CHAT.hrl"))
  Record.defrecord(:cx, Record.extract(:cx, from_lib: "chat/include/roster.hrl"))
  Record.defrecord(:pi, Record.extract(:pi, from_lib: "chat/include/roster.hrl"))

  def info(profile(status: :patch) = _data, req, cx(params: _client_id) = state) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(profile(status: :delete, roster: _roster) = _data, req,
           cx(params: _client_id, client_pid: _c) = state) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(profile(status: :remove), req, cx(params: _client_id, client_pid: _c) = state) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(profile(status: :get, update: _last_sync, settings: _settings), req,
           cx(params: _client_id, client_pid: _c) = state) do
    {:reply, {:bert, io()}, req, state}
  end

  def info(profile(status: :init) = data, req, state) do
    {:reply, {:bert, data}, req, state}
  end

  def info(profile() = data, req, state) do
    {:reply, {:bert, data}, req, state}
  end

  def info(msg, req, state) do
    {:unknown, msg, req, state}
  end

  def proc(:init, pi(name: __MODULE__) = async) do
    {:ok, async}
  end

  def proc({:restart, _m}, pi(state: {_c, _proc}) = h) do
    {:reply, [], h}
  end

  def proc(_msg, state) do
    {:noreply, state}
  end
end
