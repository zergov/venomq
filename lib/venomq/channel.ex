defmodule Venomq.Channel do
  @moduledoc"""
  Process that handle a stream of communications between two AMQP peers.

  Channels are multiplexed so that a single network connection can carry multiple channels.
  Channels are independent of each other and can perform different functions simultaneously
  """
  use GenServer

  import Venomq.Transport.Data

  alias Venomq.Transport.Frame
  alias Venomq.ExchangeDirect
  alias Venomq.ExchangeSupervisor
  alias Venomq.Queue
  alias Venomq.QueueSupervisor

  require Logger

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def handle_frame(pid, frame) do
    GenServer.cast(pid, {:handle_frame, frame})
  end

  def deliver(pid, consumer_tag, message, exchange_name, routing_key) do
    GenServer.call(pid, {:deliver, consumer_tag, message, exchange_name, routing_key})
  end

  def destroy(pid) do
    GenServer.cast(pid, :destroy)
  end

  # genserver callbacks

  def init(socket: socket, channel_id: channel_id) do
    {:ok, %{
      socket: socket,
      channel_id: channel_id,

      # content-body frame parsing
      content_method: %{},
      content_header: %{},
      content_body: <<>>,
      body_size: 0,

      consuming: %{},
      delivery_tag: 1,
    }}
  end

  def handle_call({:deliver, consumer_tag, message, exchange_name, routing_key}, _from, state) do
    Logger.info("sending #{message}, #{exchange_name} #{consumer_tag} to client.")

    # send basic.deliver
    method_payload = <<60::16, 60::16>> <> encode_short_string(consumer_tag)
    method_payload = method_payload <> <<state.delivery_tag::64, 0>>
    method_payload = method_payload <> encode_short_string(exchange_name)
    method_payload = method_payload <> encode_short_string(routing_key)
    :gen_tcp.send(state.socket, Frame.create_method_frame(method_payload, state.channel_id))

    # send content-header and content-body containing the message
    content_header = <<60::16, 0::16, byte_size(message)::64, 0::16>>
    :gen_tcp.send(state.socket, Frame.create_content_header_frame(content_header, state.channel_id))
    :gen_tcp.send(state.socket, Frame.create_content_body_frame(message, state.channel_id))

    {:reply, :ok, %{state | delivery_tag: state.delivery_tag + 1}}
  end

  def handle_cast({:handle_frame, frame}, state) do
    {:noreply, do_handle_frame(frame, state)}
  end

  def handle_cast(:destroy, state) do
    # remove all consumers of this channel
    state.consuming
    |> Enum.each(fn {consumer_tag, queue_pid} -> Queue.remove_consumer(queue_pid, consumer_tag) end)

    Process.exit(self(), :normal)
  end

  # handle frames
  defp do_handle_frame(%Frame{type: :method, payload: payload}, state), do: handle_method(payload, state)
  defp do_handle_frame(%Frame{type: :content_header, payload: payload}, state), do: handle_content_header(payload, state)
  defp do_handle_frame(%Frame{type: :content_body, size: size, payload: payload}, state) do
    handle_content_body(payload, size, state)
  end

  # queue.declare
  defp handle_method(%{class: :queue, method: :declare, payload: payload}, state) do
    {:ok, _pid} = QueueSupervisor.declare_queue(payload)

    # answer client with queue.declare_ok
    # TODO: this should be contained inside Frame or Method module
    method_payload = <<50::16, 11::16>> <> encode_short_string(payload.queue_name)
    message_count = 0
    consumer_count = 0
    method_payload = method_payload <> << message_count::32, consumer_count::32 >>
    # TODO: no-wait flag if it exists

    :gen_tcp.send(state.socket, Frame.create_method_frame(method_payload, state.channel_id))
    state
  end

  defp handle_method(%{class: :basic, method: :consume, payload: payload}, state) do
    case QueueSupervisor.lookup(payload.queue) do
      nil ->
        Logger.info("cannot find queue: #{payload.queue}")
        state
      pid ->
        Logger.info("channel #{inspect(self())} | asking for consumer subscription")
        :ok = Queue.add_consumer(pid, payload.consumer_tag)

        method_payload = <<60::16, 21::16>> <> encode_short_string(payload.consumer_tag)
        :gen_tcp.send(state.socket, Frame.create_method_frame(method_payload, state.channel_id))

        # keep track of the relation between the consumer and the queue
        %{state | consuming: state.consuming |> Map.put(payload.consumer_tag, pid)}
    end
  end

  defp handle_method(%{class: :basic, method: :publish} = method, state), do: %{state | content_method: method}
  defp handle_content_header(payload, state), do: %{state | content_header: payload}
  defp handle_content_body(payload, size, state) do
    content_body = state.content_body <> payload
    body_size = state.body_size + size

    # If there is no more content-body frame to accumulate, execute the method with
    # the constructed body.
    if body_size == state.content_header.body_size do
      state = execute_method(state.content_method, content_body, state)
      %{state | content_method: %{}, content_header: %{}, content_body: <<>>, body_size: 0}
    else
      %{state | content_body: content_body, body_size: body_size}
    end
  end

  defp execute_method(%{class: :basic, method: :publish, payload: payload}, body, state) do
    %{exchange_name: exchange_name, routing_key: routing_key} = payload
    case ExchangeSupervisor.lookup(exchange_name) do
      nil ->
        Logger.info("cannot find exchange: #{exchange_name}")
        :error
      pid ->
        :ok = ExchangeDirect.publish(pid, %{routing_key: routing_key, body: body})
    end
    state
  end
end
