defmodule Venomq.Transport.Frame do

  alias Venomq.Transport.Method
  alias Venomq.Transport.Frame

  defstruct type: nil,
            channel_id: 0,
            size: 0,
            payload: nil

  def parse_frames(packet) do
    packet
    |> String.split(<< 0xce >>)
    |> Enum.reverse |> tl |> Enum.reverse # last item in the list is an empty string
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
end
