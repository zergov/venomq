defmodule Venomq.Transport.Frame do

  alias Venomq.Transport.Method
  alias Venomq.Transport.ContentHeader
  alias Venomq.Transport.ContentBody
  alias Venomq.Transport.Frame

  defstruct type: nil,
            channel_id: 0,
            size: 0,
            payload: nil

  def parse_frames(packet) do
    packet
    |> String.split(<< 0xce >>, trim: true)
    |> Enum.map(&parse_frame/1)
    |> IO.inspect
  end

  defp parse_frame(<<1, channel_id::16, size::32, payload::binary-size(size)>>) do
    %Frame{
      type: :method,
      channel_id: channel_id,
      size: size,
      payload: Method.parse_method(payload)
    }
  end

  defp parse_frame(<<2, channel_id::16, size::32, payload::binary-size(size)>>) do
    %Frame{
      type: :content_header,
      channel_id: channel_id,
      size: size,
      payload: ContentHeader.parse_header(payload)
    }
  end

  defp parse_frame(<<3, channel_id::16, size::32, payload::binary-size(size)>>) do
    %Frame{
      type: :content_body,
      channel_id: channel_id,
      size: size,
      payload: ContentBody.parse_body(payload),
    }
  end
end
