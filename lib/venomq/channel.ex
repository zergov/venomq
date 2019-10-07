defmodule Venomq.Channel do

  @moduledoc"""
  Process that handle a stream of communications between two AMQP peers.

  Channels are multiplexed so that a single network connection can carry multiple channels.
  Channels are independent of each other and can perform different functions simultaneously
  """
  use GenServer

  import Venomq.Transport.Data

  alias Venomq.Transport.Frame

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
  defp do_handle_frame(%Frame{type: :method, payload: payload}, state), do: handle_method(payload, state)

  # queue.declare
  defp handle_method(%{class: :queue, method: :declare, payload: payload}, state) do
    Logger.info(inspect(payload))

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

  #Generate a method frame for this Channel.
  defp create_method_frame(method_payload, %{ channel_id: channel_id }) do
    <<1, channel_id::16, byte_size(method_payload)::32 >> <> method_payload <> << 0xce >>
  end
end
