defmodule Venomq.ConnectionAcceptor do
  require Logger

  @default_port 5672

  def start_server do
    {:ok, socket} = :gen_tcp.listen(@default_port, [:binary, packet: :raw, active: true, reuseaddr: true])
    Logger.info("Accepting connections on port #{@default_port}")
    accept_connection(socket)
  end

  defp accept_connection(socket) do
    # currently we are not supporting channel multiplexing, so we create a single channel per
    # TCP connection.
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Venomq.Connection.start_link(client)
    :ok = :gen_tcp.controlling_process(client, pid)

    accept_connection(socket)
  end
end
