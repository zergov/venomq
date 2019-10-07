# Venomq
Zero dependency AMQP message broker

## Introduction
I am currently following a course about distributed systems. One of the things I find
interesting is how they communicate and exchange informations over the network.
Eventually I learned about AMQP.

From the AMQP website:
> The Advanced Message Queuing Protocol (AMQP) is an open standard for passing business messages between applications or organizations.  It connects systems, feeds business processes with the information they need and reliably transmits onward the instructions that achieve their goals.

I thought it was cool, so I started reading the AMQP spec.
I then decided I would write an AMQP message broker from scratch, as an exercise to really understand AMQP compliant
software works.

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

## Test the broker
Right now, I am testing the broker with a script that uses the python client [pika](https://github.com/pika/pika).
You can find the script in the `/examples` folder.
