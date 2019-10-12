defmodule Venomq.Queue do
  use GenServer

  alias Venomq.Channel

  require Logger

  def start_link(config: config, name: name) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def deliver(pid, message, exchange_name, routing_key) do
    GenServer.call(pid, {:deliver, message, exchange_name, routing_key})
  end

  def add_consumer(pid, consumer_tag) do
    GenServer.call(pid, {:add_consumer, consumer_tag})
  end

  def remove_consumer(pid, consumer_tag) do
    GenServer.cast(pid, {:remove_consumer, consumer_tag})
  end

  # GenServer callbacks

  def init(config) do
    Logger.info("queue: \"#{config.queue_name}\" | queue declared with config: ")
    IO.inspect(config)
    {:ok,
      %{
        config: config,
        consumers: %{},
        consumers_queue: :queue.new,
      }
    }
  end

  def handle_call({:deliver, message, exchange_name, routing_key}, _from, state) do
    Logger.info("queue: \"#{state.config.queue_name}\" | delivering message.")

    case get_available_consumer(state.consumers, state.consumers_queue) do
      {consumer_tag, channel_pid, consumers_queue} ->

        # add the consumer back in the queue of consumers
        consumers_queue = :queue.in(consumer_tag, consumers_queue)

        Channel.deliver(channel_pid, consumer_tag, message, exchange_name, routing_key)
        {:reply, :ok, %{state | consumers_queue: consumers_queue}}

      {:error, consumers_queue} ->
        Logger.info("queue: \"#{state.config.queue_name}\" | no consumers available to receive message. Message dropped.")
        #TODO: implement backing queue. This way messages are persisted if no consumers are available.
        {:reply, :ok, state}
    end
  end

  def handle_call({:add_consumer, consumer_tag}, {channel_pid, _}, state) do
    Logger.info("queue: \"#{state.config.queue_name}\" | adding consumer #{consumer_tag} -> channel: #{inspect(channel_pid)}.")

    # add the new consumer the map and in the consumers queue.
    # The consumers queue is used to deliver messages to different queue consumers in a
    # round robin fashion.
    consumers = state.consumers |> Map.put(consumer_tag, channel_pid)
    consumers_queue = :queue.in(consumer_tag, state.consumers_queue)

    state = %{state | consumers: consumers, consumers_queue: consumers_queue}
    {:reply, :ok, state}
  end

  def handle_cast({:remove_consumer, consumer_tag}, state) do
    Logger.info("queue: \"#{state.config.queue_name}\" | removing consumer: #{consumer_tag}")
    {:noreply, %{state | consumers: Map.delete(state.consumers, consumer_tag)}}
  end

  @doc"""
  traverse the queue of consumers and attempt to find an available consumer.
  """
  defp get_available_consumer(consumers, {[], []}), do: {:error, :queue.new}
  defp get_available_consumer(consumers, consumers_queue) do
    {{:value, consumer}, consumers_queue} = :queue.out(consumers_queue)

    case Map.fetch(consumers, consumer) do
      {:ok, channel_pid} ->
        {consumer, channel_pid, consumers_queue}
      :error ->
        get_available_consumer(consumers, consumers_queue)
    end
  end
end
