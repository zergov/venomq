defmodule Venomq.Transport.Frame do

  alias Venomq.Transport.Method
  alias Venomq.Transport.Frame

  defstruct type: nil,
            channel_id: 0,
            size: 0,
            payload: nil

  def parse_frame(<<1, channel_id::16, size::32, payload::binary-size(size), 0xce>>) do
    %Frame{
      type: :method,
      channel_id: channel_id,
      size: size,
      payload: Method.parse_method(payload)
    }
  end

  def parse_frame(<<2, channel_id::16, size::32, payload::binary-size(size), 0xce>>) do
    <<class_id::16, weight::16, body_size::64, property_flag::16, remainder::binary>> = payload
    %Frame{
      type: :content_header,
      channel_id: channel_id,
      size: size,
      payload: %{
        class: class_atom(class_id),
        weight: weight,
        body_size: body_size,
        property_flag: property_flag,
        remainder: remainder,
      }
    }
  end

  def parse_frame(<<3, channel_id::16, size::32, payload::binary-size(size), 0xce>>) do
    %Frame{
      type: :content_body,
      channel_id: channel_id,
      size: size,
      payload: payload,
    }
  end

  defp class_atom(60), do: :basic
end
