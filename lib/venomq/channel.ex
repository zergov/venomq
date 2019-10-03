defmodule Venomq.Channel do
  use GenServer

  require Logger

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    {:ok, %{socket: socket}, {:continue, :initialize}}
  end

  # TCP callbacks

  def handle_continue(:initialize, state) do
    Logger.info("Spawned a channel with pid: #{inspect(self())}")
    write_socket(state.socket, "channel.open_ok\n")
    {:noreply, state.socket}
  end

  def handle_info({:tcp, socket, data}, state) do
    Logger.info("#{inspect(self())} | message received: #{String.trim(data)}")
    parse_command(data, socket)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Logger.info("#{inspect(self())} | connection closed.")
    Process.exit(self(), :normal)
  end

  defp parse_command("exchange.declare" <> _args, socket) do
    Logger.info("declaring channel...")
    write_socket(socket, "exchange.declare_ok\n")
  end

  defp parse_command(data, socket) do
    Logger.info("cannot process message: #{data}")
    write_socket(socket, "channel.not_found\n")
  end

  defp write_socket(socket, data) do
    :gen_tcp.send(socket, data)
  end
end
