defmodule Venomq.Channel do
  use GenServer

  require Logger

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    Logger.info("Spawned a channel with pid: #{inspect(self())}")
    {:ok, %{ socket: socket }}
  end

  # TCP callbacks

  def handle_info({:tcp, socket, data}, state) do
    Logger.info("#{inspect(self())} | message received: #{String.trim(data)}")
    :gen_tcp.send(socket, data)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Logger.info("#{inspect(self())} | connection closed.")
    Process.exit(self(), :normal)
  end
end
