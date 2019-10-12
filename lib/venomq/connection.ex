defmodule Venomq.Connection do
  @moduledoc"""
  Process that handles a connection between a client and the broker.

  This process handles connection initialization, parse incoming TCP packet and
  forward AMQP frames to channels.
  """
  use GenServer

  import Venomq.Transport.Data

  alias Venomq.Channel
  alias Venomq.ChannelSupervisor
  alias Venomq.Transport.Frame

  require Logger

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    {:ok, %{
      socket: socket,
      channels: %{},
    }}
  end

  # TCP callbacks

  # connection initialization | protocol header
  def handle_info({:tcp, socket, "AMQP" <> <<0, 0, 9, 1>>}, state) do
    class_id = 10
    method_id = 10
    major = 0
    minor = 9
    server_properties = <<0::32>>
    mechanism = "PLAIN"
    locales = "en_US"

    # respond with Connection.start
    method_payload = <<class_id::16, method_id::16>>
    method_payload = method_payload <> <<major, minor>> <> server_properties
    method_payload = method_payload <> encode_long_string(mechanism)
    method_payload = method_payload <> encode_long_string(locales)

    :gen_tcp.send(socket, Frame.create_method_frame(method_payload, 0))

    # Changing packet setting to: line", with 0xce delimiter
    :inet.setopts(socket, [{:packet, :line}, {:line_delimiter, 0xce}])
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    frame = Frame.parse_frame(data)
    {:noreply, handle_frame(frame, state)}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Logger.info("connection #{inspect(self())} | connection closed.")
    #TODO: kill channels of this connection
    Process.exit(self(), :normal)
  end

  # Handle frames related to connection establishment
  def handle_frame(%Frame{type: :method, channel_id: 0} = frame, state) do
    handle_method(frame.payload, state)
  end

  # handle channel.open method
  #
  # This Method call is special because the channel_id is specified, but the
  # channel process is not yet opened. So this method call is handled at the
  # connection level, instead of the channel leve.
  def handle_frame(%Frame{type: :method, channel_id: channel_id, payload: %{class: :channel, method: :open}}, state) do
    {:ok, channel_pid} = ChannelSupervisor.start_child(state.socket, channel_id)

    state = put_in(state[:channels][channel_id], channel_pid)

    # answer client with channel.open_ok
    method_payload = <<20::16, 11::16>> <> encode_long_string("#{channel_id}")

    :gen_tcp.send(state.socket, Frame.create_method_frame(method_payload, channel_id))
    state
  end

  # Forward frame to corresponding channel
  def handle_frame(%Frame{channel_id: channel_id} = frame, state) do
    case Map.fetch(state.channels, channel_id) do
      {:ok, channel_pid} ->
        Channel.handle_frame(channel_pid, frame)
      :error ->
        Logger.info("connection #{inspect(self())} | cannot find channel: #{channel_id}")
    end
    state
  end

  defp handle_method(%{class: :connection, method: :start_ok}, state) do
    # NOTE: Here we assume the mechanism is PLAIN, and that the response has
    # already been provided.
    #
    # We also set very flexible and simple to implement settings. For example:
    #   - unlimited channels
    #   - unlimited frame size
    #   - no heartbeat
    #
    # build and send connection.tune
    class_id = 10
    method_id = 30
    channel_max = 0
    frame_max = 0
    heartbeat = 0
    method_payload = <<class_id::16, method_id::16, channel_max::16, frame_max::32, heartbeat::16>>

    :gen_tcp.send(state.socket, Frame.create_method_frame(method_payload, 0))
    state
  end

  defp handle_method(%{class: :connection, method: :tune_ok, payload: payload}, state) do
    Logger.info("connection #{inspect(self())} | Setting socket buffer size to: #{payload.frame_max}")
    :inet.setopts(state.socket, [{:buffer, payload.frame_max}])
    state
  end

  defp handle_method(%{class: :connection, method: :open, payload: payload}, state) do
    # answer with connection.open_ok
    method_payload = <<10::16, 41::16>> <> encode_short_string(payload.virtual_host)
    :gen_tcp.send(state.socket, Frame.create_method_frame(method_payload, 0))

    state
  end
end
