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
    write_socket(state.socket, "channel.open_ok")
    {:noreply, state.socket}
  end

  def handle_info({:tcp, _socket, data}, state) do
    Logger.info(inspect(to_string(data)))
    # :gen_tcp.send(socket, data)
    # :gen_tcp.send(socket, )
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Logger.info("#{inspect(self())} | connection closed.")
    Process.exit(self(), :normal)
  end

  defp write_socket(socket, data) do
    :gen_tcp.send(socket, data)
  end
end
