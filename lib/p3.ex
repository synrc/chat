defmodule MAIL.X420.P3 do
  @moduledoc """
  Basic Thousand Island handler for X.400-style protocols (P1/P3/P7).

  Real X.400 protocols are built on:
  - ACSE (association control) for bind/unbind
  - ROSE (Remote Operations) for invoke/result/error
  - Presentation/Session layers (often collapsed over TCP today)
  - ASN.1 BER encoding

  This is a **minimal skeleton**:
  - Accepts connections
  - Accumulates incoming bytes (X.400 PDUs can be large)
  - Logs raw hex for debugging
  - Echoes a simple "accept" response on first data (simulating A-ASSOCIATE.rsp)
  - Keeps connection open for streaming PDUs

  To make it functional you must add:
  - ASN.1 BER decoding (e.g., using :asn1 or a library like ex_asn)
  - ACSE parsing (A-ASSOCIATE, A-RELEASE)
  - ROSE dispatch (invoke → operation handling)
  - Protocol-specific logic (P1 transfer, P3 submission/delivery, P7 fetch/list)

  This handler treats all three protocols the same for demonstration.
  In production, you would have separate handler modules or dispatch based on port.
  """

  use ThousandIsland.Handler

  def start_link(port: port) do
    :logger.info(~c"Starting MAIL.X420 (Thousand Island) on 0.0.0.0:~p", [port])

    ThousandIsland.start_link(
      handler_module: __MODULE__,
      port: port,
      num_acceptors: System.schedulers_online() * 4,   # масштабується з кількістю ядер
      num_connections: :infinity,                      # знімаємо обмеження (контроль через OS ulimit)
      num_listen_sockets: 1,
      read_timeout: :infinity,                         # persistent chat-з'єднання
      shutdown_timeout: 30_000,
      transport_module: ThousandIsland.Transports.TCP,
      transport_options: [
        :binary,
        reuseaddr: true,
        nodelay: true,
        keepalive: true,
        backlog: 16_384,
        sndbuf: 1_048_576,
        recbuf: 1_048_576
      ]
    )
  end

  def child_spec(opt) do
    %{
      id: MAIL.X420.P3,
      start: {MAIL.X420.P3, :start_link, [opt]},
      type: :supervisor,
      restart: :permanent,
      shutdown: :infinity
    }
  end

  @impl true
  def handle_connection(socket, state) do
    # Extract which protocol this connection belongs to (by transport info)
    {:ok, {_, port}} = :inet.port(socket.transport_socket)
    protocol = case port do
      17001 -> "P1 (MTA transfer)"
      17002 -> "P3 (UA submission/delivery)"
      17003 -> "P7 (MS access)"
      _     -> "Unknown"
    end

    IO.puts("[#{protocol}] New connection from #{inspect(socket.remote_address)}")

    # Store buffer and protocol in handler state
    {:ok, %{buffer: <<>>, protocol: protocol, socket: socket}}
  end

  @impl true
  def handle_data(data, %{buffer: buffer, protocol: protocol, socket: socket} = state) do
    new_buffer = buffer <> data

    IO.puts("[#{protocol}] Received #{byte_size(data)} bytes:")
    IO.puts(:io_lib.format("~.16B~n", [new_buffer |> :binary.bin_to_list() |> Enum.chunk_every(16)]))

    # Very naive "first packet" detection – real code would parse ACSE A-ASSOCIATE.req
    if buffer == <<>> do
      # Simulate accepting the association (send a minimal A-ASSOCIATE.rsp placeholder)
      accept_response = <<0x61, 0x80, 0x80, 0x00>>  # Dummy BER-encoded accept (not real!)
      ThousandIsland.Socket.send(socket, accept_response)
      IO.puts("[#{protocol}] Sent dummy association accept")
    end

    # Placeholder for real protocol handling
    # case parse_pdu(new_buffer) do
    #   {:ok, pdu, rest} -> handle_pdu(pdu, socket, protocol); {:continue, %{state | buffer: rest}}
    #   :incomplete -> {:continue, state}
    # end

    # For this basic version: keep connection open, continue accumulating
    {:continue, %{state | buffer: new_buffer}}
  end

  @impl true
  def handle_close(_socket, state) do
    IO.puts("[#{state.protocol}] Connection closed")
    :ok
  end

  @impl true
  def handle_error(reason, state) do
    IO.puts("[#{state.protocol}] Error: #{inspect(reason)}")
    :ok
  end
end
