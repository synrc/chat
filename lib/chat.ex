defmodule Chat do
  use Application
  require Record

  Enum.each(Record.extract_all(from_lib: "chat/include/CHAT.hrl"),
            fn {name, definition} -> Record.defrecord(name, definition) end)

  def init([]), do: {:ok, { {:one_for_one, 5, 10}, []} }

  def start(_type, _args) do
      :logger.add_handlers(:chat)
      Supervisor.start_link([
         { Chat.Proto,  port: 8830 },
      ], strategy: :one_for_one, name: CHAT.Supervisor)
  end

end
