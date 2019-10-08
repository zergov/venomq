defmodule Venomq.ExchangeDirect do
  use GenServer

  require Logger

  def start_link(exchange_name: exchange_name, name: name) do
    GenServer.start_link(__MODULE__, exchange_name, name: name)
  end

  def publish(pid, %{routing_key: routing_key, body: body}) do
    GenServer.cast(pid, {:publish, routing_key, body})
  end

  # genserver callbacks

  def init(exchange_name) do
    {:ok, %{exchange_name: exchange_name}}
  end

  def handle_cast({:publish, routing_key, body}, state) do
    Logger.info("#{state.exchange_name} | publishing #{body} with routing key: #{routing_key}")
    # TODO: route message to appropriate queues
    {:noreply, state}
  end
end
