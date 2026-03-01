defmodule CHAT do
  use Application
  require Record
  require KVS
  require CHAT.X509

  Enum.each(Record.extract_all(from_lib: "kvs/include/metainfo.hrl"),
            fn {name, definition} -> Record.defrecord(name, definition) end)

  def init([]), do: {:ok, { {:one_for_one, 5, 10}, []} }

  def metainfo() do
      KVS.schema(name: :"CHAT-v2", tables: [
       KVS.table(name: :Authority, fields: [
         :id,:vsn,:session,:type,:cert,:settings], instance: CHAT.X509."Authority"()),
       KVS.table(name: :Message,   fields: [
         :id,:vsn,:session,:inbox,:from,:to,:files,:type,:link,
         :seenby,:repliedby,:mentioned,:status], instance: CHAT.X509."Message"()),
      ])
  end

  @c1_port 17000
  @p1_port 17001
  @p3_port 17002
  @p7_port 17003

  def start(_type, _args) do
      :logger.add_handlers(:chat)
      Supervisor.start_link([
         { Task.Supervisor, name: CHAT.TaskSupervisor},
         { CHAT.X509,    port: @c1_port}, # CHAT C1 SPEC: Instant Messaging and Command and Control
         { MAIL.X420.P1, port: @p1_port}, # MMHS P1 SPEC: MTA-to-MTA transfer (relay).
         { MAIL.X420.P3, port: @p3_port}, # MMHS P3 SPEC: UA-to-MTA submission and MTA-to-UA delivery.
         { MAIL.X420.P7, port: @p7_port}, # MMHS P7 SPEC: UA-to-MS retrieval (with MTA delivering to MS via P3-like internal mechanism).
      ], strategy: :one_for_one, name: CHAT.Supervisor)
  end

end
