defmodule Venomq.Channel do
  @moduledoc"""
  Process that handle a stream of communications between two AMQP peers.

  Channels are multiplexed so that a single network connection can carry multiple channels.
  Channels are independent of each other and can perform different functions simultaneously
  """
  use GenServer

  import Venomq.Transport.Data

  alias Venomq.Transport.Frame
  alias Venomq.ExchangeSupervisor
  alias Venomq.ExchangeDirect

  require Logger

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  def handle_frame(pid, frame) do
    GenServer.cast(pid, {:handle_frame, frame})
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
    }}
  end

  def handle_cast({:handle_frame, frame}, state) do
    {:noreply, do_handle_frame(frame, state)}
  end

  # handle method frame
  defp do_handle_frame(%Frame{type: :method, payload: payload}, state), do: handle_method(payload, state)
  defp do_handle_frame(%Frame{type: :content_header, payload: payload}, state), do: handle_content_header(payload, state)
  defp do_handle_frame(%Frame{type: :content_body, size: size, payload: payload}, state) do
    handle_content_body(payload, size, state)
  end

  # queue.declare
  defp handle_method(%{class: :queue, method: :declare, payload: payload}, state) do
    #TODO: create the actual queue process
    #
    # answer client with queue.declare_ok
    method_payload = <<50::16, 11::16>> <> encode_short_string(payload.queue_name)
    message_count = 0
    consumer_count = 0
    method_payload = method_payload <> << message_count::32, consumer_count::32 >>

    :gen_tcp.send(state.socket, create_method_frame(method_payload, state))
    state
  end

  defp handle_method(%{class: :basic, method: :publish, payload: payload} = method, state) do
    %{state | content_method: method}
  end

  defp handle_content_header(payload, state) do
    %{state | content_header: payload}
  end

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
    case ExchangeSupervisor.lookup(payload.exchange_name) do
      nil ->
        Logger.info("cannot find exchange: #{payload.exchange_name}")
      exchange ->
        ExchangeDirect.publish(exchange, %{routing_key: payload.routing_key, body: body})
    end

    state
  end

  #Generate a method frame for this Channel.
  defp create_method_frame(method_payload, %{ channel_id: channel_id }) do
    <<1, channel_id::16, byte_size(method_payload)::32 >> <> method_payload <> << 0xce >>
  end
end
