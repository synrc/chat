defmodule CHAT.Auth do
  require Record

  Record.defrecord(:auth,      Record.extract(:Authority, from_lib: "chat/include/CHAT-v2.hrl"))
  Record.defrecord(:cx,        Record.extract(:cx, from_lib: "chat/include/roster.hrl"))
  Record.defrecord(:pi,        Record.extract(:pi, from_lib: "chat/include/roster.hrl"))

  def info(auth(), req, cx(params: _client_id) = state) do
    {:reply, {:bert, <<>>}, req, state}
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
