defmodule CHAT do
  use Application
  require Record

  Enum.each(Record.extract_all(from_lib: "chat/include/CHAT-v2.hrl"),
            fn {name, definition} -> Record.defrecord(name, definition) end)

  def init([]), do: {:ok, { {:one_for_one, 5, 10}, []} }

  @p1_port 17001
  @p3_port 17002
  @p7_port 17003
  @c1_port 17004

  def start(_type, _args) do
      :logger.add_handlers(:chat)
      Supervisor.start_link([
         { Task.Supervisor, name: CHAT.TaskSupervisor},
         CHAT.Registry,
         { MAIL.X420.P1, port: @p1_port}, # MMHS P1 SPEC: MTA-to-MTA transfer (relay).
         { MAIL.X420.P3, port: @p3_port}, # MMHS P3 SPEC: UA-to-MTA submission and MTA-to-UA delivery.
         { MAIL.X420.P7, port: @p7_port}, # MMHS P7 SPEC: UA-to-MS retrieval (with MTA delivering to MS via P3-like internal mechanism).
         { CHAT.X509,    port: @c1_port}  # CHAT C1 SPEC: Instant Messaging and Command and Control
      ], strategy: :one_for_one, name: CHAT.Supervisor)
  end

end
