defmodule Venomq.Transport.ContentHeader do
  def parse_header(<<60::16, weight::16, body_size::64, property_flag::16, remainder::binary>>) do
    %{
      class: :basic,
      weight: weight,
      body_size: body_size,
      property_flag: property_flag,
      remainder: remainder,
    }
  end
end
