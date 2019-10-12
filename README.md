# Venomq
A work in progress, zero dependency AMQP 0.9.1 message broker.

## Introduction
I got interested on how [rabbitmq](https://www.rabbitmq.com/) works, so I decided to write my own AMQP broker.

It's been a nice learning experience! I learned a bunch of new things like
parsing packets from the transport layer and how to do connection multiplexing over a single TCP socket.

## Goal
My goal is to follow the [rabbitmq tutorials](https://www.rabbitmq.com/getstarted.html), and implement as much feature as possible so that all tutorials can be played on the broker.

I am using the python version of the tutorials, using the AMQP [`pika`](https://github.com/pika/pika) client.
You can find the tutorial scripts in the `/examples` folder.

## Starting the broker
You will need [elixir](https://elixir-lang.org/install.html) installed on your machine.

Then, just start an iex session with the mix project:
```
λ iex -S mix

Erlang/OTP 22 [erts-10.5] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe] [dtrace]

Interactive Elixir (1.9.1) - press Ctrl+C to exit (type h() ENTER for help)

03:57:49.438 [info]  Accepting connections on port 5672
iex(1)>
```

At this point, the broker is running and is accepting connections from AMQP clients on
port 5672 (the default AMQP port)
