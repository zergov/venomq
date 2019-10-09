defmodule Venomq do
  use Application

  alias Venomq.ConnectionAcceptor

  def start(_type, _args) do
    children = [
      Venomq.ChannelSupervisor,
      Venomq.ExchangeSupervisor,
      Venomq.QueueSupervisor,
      {Registry, [keys: :unique, name: Registry.Exchange]},
      {Registry, [keys: :unique, name: Registry.Queue]},
      Supervisor.child_spec({Task, fn -> ConnectionAcceptor.start_server end}, restart: :permanent),
    ]

    opts = [strategy: :one_for_one, name: Venomq.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
