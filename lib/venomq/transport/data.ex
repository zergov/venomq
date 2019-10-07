defmodule Venomq.Transport.Data do
  require Logger

  def encode_long_string(string) do
    <<byte_size(string)::32>> <> string
  end

  def encode_short_string(string) do
    <<byte_size(string)>> <> string
  end

  @doc"""
  Utility function to decode a map from field-table byte stream.

  returns: {value, length, encoded}, where
      - value is the decoded value
      - length is the length of the decoding value
      - encoded is the remaining bytes not decoded
  """
  def decode_table(encoded) do
    <<table_size::32, encoded::binary>> = encoded
    decode_table(%{}, table_size, 0, encoded)
  end

  def decode_short_string(encoded), do: decode_value("s", encoded)
  def decode_long_string(encoded), do: decode_value("S", encoded)
  def decode_short_int(encoded), do: decode_value("U", encoded)
  def decode_long_int(encoded), do: decode_value("I", encoded)

  @moduledoc"""
  The following functions decodes a stream of bytes based on
  a `value_type`. The different value types are specified in
  the AMQP 0.9.1 grammar.

  ## parameters
    - value_type: Byte used to represent the value type in the AMQP 0.9.1 Grammar
    - encoded: total or partial stream of bytes to decode

  ## returns
    - {value, length, encoded} where
      - value is the decoded value
      - length is the length of the decoding value
      - encoded is the remaining bytes not decoded
  """
  defp decode_table(result, size, offset, table) when offset >= size, do: {result, size, table}
  defp decode_table(result, size, offset, table) when offset < size do
    << ksize, key::binary-size(ksize), value_type, table::binary >> = table
    case decode_value(<<value_type>>, table) do
      {value, length, rest} ->
        result = Map.put(result, key, value)

        offset = offset + length + byte_size(key) + 2
        decode_table(result, size, offset, rest)
      :not_implemented -> :not_implemented
    end
  end

  defp decode_value("t", encoded) do    # boolean
    << boolean, rest::binary >> = encoded
    {!!boolean, 1, rest}
  end

  defp decode_value("b", _encoded) do 	# short-short-int
    :not_implemented
  end

  defp decode_value("B", _encoded) do 	# short-short-uint
    :not_implemented
  end

  defp decode_value("U", encoded) do 	# short-int
    <<number::16, rest::binary>> = encoded
    {number, 2, rest}
  end

  defp decode_value("u", _encoded) do 	# short-uint
    :not_implemented
  end

  defp decode_value("I", encoded) do 	# long-int
    <<number::32, rest::binary>> = encoded
    {number, 4, rest}
  end

  defp decode_value("i", _encoded) do 	# long-uint
    :not_implemented
  end

  defp decode_value("L", _encoded) do 	# long-long-int
    :not_implemented
  end

  defp decode_value("l", _encoded) do 	# long-long-uint
    :not_implemented
  end

  defp decode_value("f", _encoded) do 	# float
    :not_implemented
  end

  defp decode_value("d", _encoded) do 	# double
    :not_implemented
  end

  defp decode_value("D", _encoded) do 	# decial-value
    :not_implemented
  end

  defp decode_value("s", encoded) do 	# short-string
    <<size, string::binary-size(size), rest::binary>> = encoded
    {string, 1 + size, rest}
  end

  defp decode_value("S", encoded) do  	# long-string
    <<size::32, string::binary-size(size), rest::binary>> = encoded
    {string, 4 + size, rest}
  end

  defp decode_value("A", _encoded) do 	# field-array
    :not_implemented
  end

  defp decode_value("T", _encoded) do 	# timestamp
    :not_implemented
  end

  defp decode_value("F", encoded) do 	# field-table
    {table, length, rest} = decode_table(encoded)
    {table, 4 + length, rest}
  end

  defp decode_value("V", _encoded) do 	# no field
    :not_implemented
  end
end
