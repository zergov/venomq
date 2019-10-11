defmodule Venomq.Queue do
  use GenServer

  require Logger

  def start_link(config: config, name: name) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def enqueue(pid, message) do
    GenServer.call(pid, {:enqueue, message})
  end

  # GenServer callbacks

  def init(config) do
    Logger.info("queue: \"#{config.queue_name}\" | queue declared with config: ")
    IO.inspect(config)
    {:ok,
      %{
        config: config,
        message_queue: :queue.new,
      }
    }
  end

  def handle_call({:enqueue, message}, _from, %{message_queue: message_queue} = state) do
    Logger.info("queue: \"#{state.config.queue_name}\" | enqueing message.")
    message_queue = :queue.in(message, message_queue)
    state = %{state | message_queue: message_queue}
    {:reply, :ok, state}
  end
end
