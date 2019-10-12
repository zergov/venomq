# Venomq
A work in progress, zero dependency AMQP message broker.

## Introduction
I got interested on how rabbitmq works, so I decided to roll my own AMQP broker.
It's a nice learning experience as of now! I learned a lot of things while coding on this
project.

## starting the broker
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

## Playing with the broker
My goal is to follow the [rabbitmq tutorials](https://www.rabbitmq.com/getstarted.html), and implement as much feature as possible
so that the tutorials can be played on this broker.

I am using the python version of the tutorials, using the amqp [pika](https://github.com/pika/pika) .
You can find the tutorial scripts in the `/examples` folder.
