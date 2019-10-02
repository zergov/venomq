defmodule Venomq do
  require Logger

  def start_server do
    {:ok, socket} = :gen_tcp.listen(4000, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port 4000")
    accept_connection(socket)
  end

  def accept_connection(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    spawn fn -> serve(client) end
    accept_connection(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
