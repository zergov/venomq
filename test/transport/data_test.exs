defmodule Transport.DataTest do
  use ExUnit.Case, async: true

  alias Venomq.Transport.Data

  test "decode_table can decode %{a: true} field table" do
    bytes = <<4::32, 1, "a", "t", 1>>
    {value, _, _} = Data.decode_table(bytes)
    assert value == %{"a" => true}
  end

  test "decode_table can decode %{age: 25} field table" do
    bytes = <<9::32, 3, "age", "I", 25::32>>
    {value, _, _} = Data.decode_table(bytes)
    assert value == %{"age" => 25}
  end

  test "decode_table can decode nested tables" do
    bytes = <<35::32, 6, "zergov", "F", 23::32, 9, "firstname", "S", 8::32, "jonathan">>
    {value, _, _} = Data.decode_table(bytes)
    assert value == %{"zergov" => %{"firstname" => "jonathan"}}
  end

  test "decode_short_string can decode a short-string" do
    bytes = <<4, "allo">>
    assert {"allo", 5, ""} == Data.decode_short_string(bytes)
  end

  test "decode_long_string can decode a long-string" do
    bytes = <<4::32, "allo">>
    assert {"allo", 8, ""} == Data.decode_long_string(bytes)
  end
end
