defmodule Venomq.Channel do
  use GenServer

  import Venomq.AMQP.Data

  require Logger

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def handle_frame(pid, frame) do
    GenServer.cast(pid, {:handle_frame, frame})
  end

  # genserver callbacks

  def init(socket: socket, channel_id: channel_id) do
    Logger.info("Created channel: #{channel_id} at #{inspect(self())}")
    {:ok, %{
      socket: socket,
      channel_id: channel_id,
    }}
  end

  def handle_cast({:handle_frame, frame}, state) do
    state = do_handle_frame(frame, state)
    {:noreply, state}
  end

  # handle method frame
  defp do_handle_frame(<<1, _channel_id::16, size::32, payload::binary-size(size)>>, state) do
    handle_method(payload, state)
  end

  # handle content header frame
  defp do_handle_frame(<<2, _channel_id::16, size::32, payload::binary-size(size)>>, state) do
    Logger.info("parsing content header frame")
    # handle_content_header(payload, state)
  end

  # handle content body frame
  defp do_handle_frame(<<3, _channel_id::16, size::32, payload::binary-size(size)>>, state) do
    Logger.info("parsing content body frame")
    # handle_content_header(payload, state)
  end

  # queue.declare
  defp handle_method(<<50::16, 10::16, arguments::binary>>, state) do
    Logger.info("parsing Queue.declare method")
    {reserved_1, _, arguments} = decode_short_int(arguments)
    {queue_name, _, arguments} = decode_short_string(arguments)
    <<passive, durable, exclusive, auto_delete, no_wait, _arguments::binary>> = arguments

    Logger.info("=========== chid: #{state.channel_id} queue.declare ==============")
    Logger.info("reserved_1: #{reserved_1}")
    Logger.info("queue_name: #{queue_name}")
    Logger.info("passive: #{passive}")
    Logger.info("durable: #{durable}")
    Logger.info("exclusive: #{exclusive}")
    Logger.info("auto_delete: #{auto_delete}")
    Logger.info("no_wait: #{no_wait}")
    Logger.info("==========================================")

    #TODO: create the actual queue process

    # answer client with queue.declare_ok
    method_payload = <<50::16, 11::16>> <> encode_short_string(queue_name)
    message_count = 0
    consumer_count = 0
    method_payload = method_payload <> << message_count::32, consumer_count::32 >>

    :gen_tcp.send(state.socket, create_method_frame(method_payload, state))
    state
  end

  # unknown method
  defp handle_method(<<class_id::16, method_id::16, arguments::binary>>, state) do
    Logger.info("========= channel_id: #{state.channel_id} | unknown method ===================")
    Logger.info("class_id: #{class_id}")
    Logger.info("method_id: #{method_id}")
    Logger.info(inspect(arguments))
    Logger.info("========================================================================")
    state
  end

  #Generate a method frame for this Channel.
  defp create_method_frame(method_payload, %{ channel_id: channel_id }) do
    <<1, channel_id::16, byte_size(method_payload)::32 >> <> method_payload <> << 0xce >>
  end
end
