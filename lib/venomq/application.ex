defmodule Venomq.Application do
  use Application

  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Task, fn -> Venomq.start_server end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Venomq.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
