defmodule Venomq.QueueSupervisor do
  use DynamicSupervisor

  alias Venomq.ExchangeSupervisor
  alias Venomq.ExchangeDirect

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @doc"""
  Return existing queue pid or create and return the newly created queue pid.
  """
  def declare_queue(%{queue_name: queue_name} = config) do
    # TODO:
    # Check existing queue config and raise an error if the queue config
    # is different from the existing queue.
    case Registry.lookup(Registry.Queue, queue_name) do
      [{queue_id, _}] ->
        {:ok, queue_id}
      [] ->
        start_queue(config)
    end
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_queue(%{queue_name: queue_name} = config) do
    name  = {:via, Registry, {Registry.Queue, queue_name}}
    {:ok, queue_pid} = DynamicSupervisor.start_child(__MODULE__, {Venomq.Queue, config: config, name: name})

    # bind queue to default direct exchanges
    # with routing key equal to the queue_name
    :ok = ExchangeSupervisor.lookup("")
          |> ExchangeDirect.bind(queue_pid, queue_name)

    {:ok, queue_pid}
  end
end

