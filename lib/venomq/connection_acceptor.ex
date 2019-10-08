defmodule Venomq.ConnectionAcceptor do
  require Logger

  @default_port 5672

  def start_server do
    opts = [:binary, packet: :raw, active: true, reuseaddr: true]
    {:ok, socket} = :gen_tcp.listen(@default_port, opts)
    Logger.info("Accepting connections on port #{@default_port}")
    accept_connection(socket)
  end

  defp accept_connection(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Venomq.Connection.start_link(client)
    :ok = :gen_tcp.controlling_process(client, pid)

    accept_connection(socket)
  end
end
