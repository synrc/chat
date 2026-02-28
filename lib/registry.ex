defmodule CHAT.Registry do
  use GenServer

  @table :chat_clients

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table, [:named_table, :public, read_concurrency: true])
    {:ok, []}
  end

  def register(client_id, pid) when is_binary(client_id) and byte_size(client_id) > 0 do
    :ets.insert(@table, {client_id, pid})
  end

  def register(_, _), do: :ok

  def unregister(client_id) when is_binary(client_id) do
    :ets.delete(@table, client_id)
  end

  def unregister(_), do: :ok

  def lookup(client_id) when is_binary(client_id) do
    case :ets.lookup(@table, client_id) do
      [{^client_id, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  def lookup(_), do: :error
end
