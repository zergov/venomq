defmodule Venomq.Transport.Method do

  import Venomq.Transport.Data

  def parse_method(<<10::16, 11::16, arguments::binary>>) do
    {client_properties, _, arguments} = decode_table(arguments)
    {mechanism, _, arguments} = decode_short_string(arguments)
    {response, _, arguments} = decode_long_string(arguments)
    {locale, _, _} = decode_short_string(arguments)
    %{
      class: :connection,
      method: :start_ok,
      payload: %{
        client_properties: client_properties,
        mechanism: mechanism,
        response: response,
        locale: locale,
      }
    }
  end

  def parse_method(<<10::16, 31::16, arguments::binary>>) do
    {channel_max, _, arguments} = decode_short_int(arguments)
    {frame_max, _, arguments} = decode_long_int(arguments)
    {heartbeat, _, _} = decode_short_int(arguments)
    %{
      class: :connection,
      method: :tune_ok,
      payload: %{
        channel_max: channel_max,
        frame_max: frame_max,
        heartbeat: heartbeat,
      }
    }
  end

  def parse_method(<<10::16, 40::16, arguments::binary>>) do
    {virtual_host, _, arguments} = decode_short_string(arguments)
    {reserved_1, _, arguments} = decode_short_string(arguments)
    <<reserved_2, _::binary>> = arguments
    %{
      class: :connection,
      method: :open,
      payload: %{
        virtual_host: virtual_host,
        reserved_1: reserved_1,
        reserved_2: reserved_2,
      }
    }
  end

  def parse_method(<<20::16, 10::16, _::binary>>) do
    %{
      class: :channel,
      method: :open,
      payload: %{}
    }
  end

  def parse_method(<<50::16, 10::16, arguments::binary>>) do
    {reserved_1, _, arguments} = decode_short_int(arguments)
    {queue_name, _, arguments} = decode_short_string(arguments)
    <<passive, durable, exclusive, auto_delete, no_wait, _::binary>> = arguments
    %{
      class: :queue,
      method: :declare,
      payload: %{
        reserved_1: reserved_1,
        queue_name: queue_name,
        passive: passive,
        durable: durable,
        exclusive: exclusive,
        auto_delete: auto_delete,
        no_wait: no_wait,
      }
    }
  end
end
