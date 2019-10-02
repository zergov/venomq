defmodule VenomqTest do
  use ExUnit.Case
  doctest Venomq

  test "greets the world" do
    assert Venomq.hello() == :world
  end
end
