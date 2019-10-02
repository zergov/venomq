defmodule Venomq.ConnectionAcceptor do
  require Logger

  def start_server do
    {:ok, socket} = :gen_tcp.listen(4000, [:binary, packet: :line, active: true, reuseaddr: true])
    Logger.info("Accepting connections on port 4000")
    accept_connection(socket)
  end

  defp accept_connection(socket) do
    # create a channel responsible to handle the new TCP connection
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Venomq.Channel.start_link(client)
    :ok = :gen_tcp.controlling_process(client, pid)

    accept_connection(socket)
  end
end
