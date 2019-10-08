defmodule Venomq.ExchangeSupervisor do
  use DynamicSupervisor

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def start_exchange(exchange_name) do
    name  = {:via, Registry, {Registry.Exchange, exchange_name}}
    spec = {Venomq.ExchangeDirect, exchange_name: exchange_name, name: name}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def lookup(exchange_name) do
    case Registry.lookup(Registry.Exchange, exchange_name) do
      [{exchange_pid, _}] ->
        exchange_pid
      [] ->
        nil
    end
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

