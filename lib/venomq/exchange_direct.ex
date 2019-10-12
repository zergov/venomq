defmodule Venomq.ExchangeDirect do
  use GenServer

  alias Venomq.Queue

  require Logger

  def start_link(exchange_name: exchange_name, name: name) do
    GenServer.start_link(__MODULE__, exchange_name, name: name)
  end

  def publish(pid, %{routing_key: routing_key, body: body}) do
    GenServer.call(pid, {:publish, routing_key, body})
  end

  def bind(pid, queue_pid, routing_key) do
    GenServer.call(pid, {:bind, queue_pid, routing_key})
  end

  # genserver callbacks

  def init(exchange_name) do
    {:ok,
      %{
        exchange_name: exchange_name,
        queues: %{},
      }
    }
  end

  def handle_call({:publish, routing_key, body}, _from, state) do
    Logger.info("exchange: \"#{state.exchange_name}\" | publishing #{body} with routing key: #{routing_key}")
    state.queues
    |> Map.get(routing_key, MapSet.new)
    |> Enum.each(&Queue.deliver(&1, body, state.exchange_name))

    {:reply, :ok, state}
  end

  def handle_call({:bind, queue_pid, routing_key}, _from, state) do
    Logger.info("exchange: \"#{state.exchange_name}\" | queue #{inspect(queue_pid)} bound")
    matching_queues =
      state.queues
      |> Map.get(routing_key, MapSet.new)
      |> MapSet.put(queue_pid)

    {:reply, :ok, %{state | queues: Map.put(state.queues, routing_key, matching_queues)}}
  end
end
