# AmqpLib

Simple library that makes easier creating producer and consumer processes for AMQP.
The library provides an abstraction layer over [amqp](https://github.com/pma/amqp).

Currently only supports synchronous producer calls and doesn't really handle errors but rather crashes. Also, each consumer and producer creates a new TLS connection to the broker which isn't very efficient.

## Installation

```elixir
def deps do
  [
    {:amqp_lib, "~> 0.1.0"}
  ]
end
```

## Local Testing

To run tests locally start the broker by running
```console
$ docker-compose up -d amqp
```

from the root of the repository and then run the tests by:

```console
$ mix test
```