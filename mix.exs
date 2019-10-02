defmodule Venomq.MixProject do
  use Mix.Project

  def project do
    [
      app: :venomq,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Venomq.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
