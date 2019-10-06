defmodule Venomq do
  use Application

  alias Venomq.ConnectionAcceptor

  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Task, fn -> ConnectionAcceptor.start_server end}, restart: :permanent),
      Venomq.ChannelSupervisor,
    ]

    opts = [strategy: :one_for_one, name: Venomq.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
