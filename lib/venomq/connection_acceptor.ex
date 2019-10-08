defmodule Venomq.ConnectionAcceptor do
  alias Venomq.ExchangeSupervisor

  require Logger

  @default_port 5672

  def start_server do
    opts = [:binary, packet: :raw, active: true, reuseaddr: true]

    # Start default exchanges
    ExchangeSupervisor.start_exchange("")
    ExchangeSupervisor.start_exchange("amq.direct")

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
