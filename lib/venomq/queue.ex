defmodule Venomq.Queue do
  use GenServer

  require Logger

  def start_link(config: config, name: name) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  # GenServer callbacks

  def init(config) do
    Logger.info("queue: \"#{config.queue_name}\" | queue declared with config: ")
    IO.inspect(config)
    {:ok, config}
  end
end
