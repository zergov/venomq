defmodule Venomq.Connection do
  use GenServer

  import Venomq.AMQP.Data
  require Logger

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    {:ok, %{
      socket: socket,
      channel_count: 0,
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

    method_payload = <<class_id::16, method_id::16>>
    method_payload = method_payload <> <<major, minor>> <> server_properties
    method_payload = method_payload <> encode_long_string(mechanism)
    method_payload = method_payload <> encode_long_string(locales)

    # Frame
    frame = <<1, 0, 0, byte_size(method_payload)::32 >> <> method_payload <> << 0xce >>

    :gen_tcp.send(socket, frame)
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    state =
      data
      |> String.split(<< 0xce >>)
      |> Enum.reverse |> tl |> Enum.reverse # last item in the list is an empty string
      |> IO.inspect
      |> Enum.reduce(state, &handle_frame/2)

    Logger.info(inspect(state))
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Logger.info("#{inspect(self())} | connection closed.")
    Process.exit(self(), :normal)
  end

  # Handle Method Class frame from 00 channel
  def handle_frame(<<1, 0::16, size::32, method_payload::binary-size(size)>>, state) do
    handle_method(method_payload, state)
  end

  # Handle Method Class frame through an existing channel
  def handle_frame(<<1, _channel_id::16, size::32, method_payload::binary-size(size)>>, state) do
    # TODO: forward this method to a channel genserver
    # Channel.call(channel_id, {:method, method_payload, state.socket})
    handle_method(method_payload, state)
  end

  # connection.start_ok
  defp handle_method(<<10::16, 11::16, arguments::binary >>, state) do
    {_client_properties, _, arguments} = decode_table(arguments)
    {_mechanism, _, arguments} = decode_short_string(arguments)
    {_response, _, arguments} = decode_long_string(arguments)
    {_locale, _, _arguments} = decode_short_string(arguments)

    # NOTE: Here we assume the mechanism is PLAIN, and that the response has
    # already been provided.
    #
    # We also set very flexible and simple settings. For example:
    #   - only 1 channel
    #   - unlimited frame size
    #   - no heartbeat
    #
    # build and send connection.tune
    class_id = 10
    method_id = 30
    channel_max = 5
    frame_max = 131072
    heartbeat = 0

    method_payload = <<class_id::16, method_id::16, channel_max::16, frame_max::32, heartbeat::16>>
    frame = <<1, 0, 0, byte_size(method_payload)::32 >> <> method_payload <> << 0xce >>

    :gen_tcp.send(state.socket, frame)
    state
  end

  # connection.tune_ok
  defp handle_method(<<10::16, 31::16, arguments::binary >>, state) do
    {channel_max, _, arguments} = decode_short_int(arguments)
    {frame_max, _, arguments} = decode_long_int(arguments)
    {heartbeat, _, _} = decode_short_int(arguments)
    Logger.info("=========== connection.tune_ok ==============")
    Logger.info("channel_max: #{channel_max}")
    Logger.info("frame_max: #{frame_max}")
    Logger.info("heartbeat: #{heartbeat}")
    Logger.info("=============================================")
    state
  end

  # connection.open
  defp handle_method(<<10::16, 40::16, arguments::binary >>, state) do
    {virtual_host, _, arguments} = decode_short_string(arguments)
    {reserved_1, _, arguments} = decode_short_string(arguments)
    <<reserved_2, _arguments::binary>> = arguments
    Logger.info("=========== connection.open ==============")
    Logger.info("virtual_host: #{virtual_host}")
    Logger.info("reserved_1: #{reserved_1}")
    Logger.info("reserved_2: #{reserved_2}")
    Logger.info("==========================================")

    method_payload = <<10::16, 41::16>> <> encode_short_string(virtual_host)
    frame = <<1, 0, 0, byte_size(method_payload)::32 >> <> method_payload <> << 0xce >>

    :gen_tcp.send(state.socket, frame)
    state
  end

  # channel.open
  defp handle_method(<<20::16, 10::16, arguments::binary>>, state) do
    {reserved_1, _, _} = decode_short_string(arguments)
    Logger.info("=========== channel.open ==============")
    Logger.info("reserved_1: #{reserved_1}")
    Logger.info("==========================================")

    # Create a new channel, and answer in this channel
    # TODO: Create a new Channel genserver
    state = %{state | channel_count: state.channel_count + 1}
    channel_id = state.channel_count
    state = put_in(state[:channels][channel_id], nil)

    method_payload = <<20::16, 11::16>> <> encode_long_string("")
    frame = <<1, channel_id::16, byte_size(method_payload)::32 >> <> method_payload <> << 0xce >>

    :gen_tcp.send(state.socket, frame)
    state
  end

  defp handle_method(<<class_id::16, method_id::16, arguments::binary>>, state) do
    Logger.info("=========================== unknown method ==================================")
    Logger.info("class_id: #{class_id}")
    Logger.info("method_id: #{method_id}")
    Logger.info(inspect(arguments))
    Logger.info("=============================================================================")
    state
  end
end
