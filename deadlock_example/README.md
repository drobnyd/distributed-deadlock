# Distributed Deadlock Example

Example of a distributed deadlock in a setup with an RabbitMQ broker and two different micro services that form two erlang clusters of two replicas each.

## Description of the services

### ServiceA

`ServiceA` spawns a single consumer that dispatches requests to process by underlying `ServiceA.Server` processes based on the `ID` in the message. 
The server processes are [globally registered](https://hexdocs.pm/elixir/1.12/GenServer.html#module-name-registration) in the erlang cluster (using the `global` [process registry](https://www.erlang.org/doc/man/global.html) from `OTP`) so the actual handling might happen in either of the nodes (replicas) of the service.
The consumer process is blocked until a reply for the request is computed.

A server process `ServiceA.Server` executes an RPC to `ServiceB` in order to compute a result. 

### ServiceB

Similarly, `ServiceB` spawns a single consumer that distributes requests to underlying `ServiceB.Server` processes based on the `ID` in the message. 
Just like before, the processes are globally registered in the erlang cluster.

`ServiceB.Server` most of the times doesn't need to make an RPC but can purely compute a result with the exception of handling message where `ID == 42` which requires additional data obtained from `ServiceA`.
However, this turns out to be a bug - if `ServiceB.Server`'s computation with `ID` `42` was triggered by `ServiceA` it means that the subsequent RPC to `ServiceB.Server` makes will be handled by `ServiceA.Server` with registered under the name `{:server_a, 42}` which must be the same process that is waiting for a reply from `ServiceB` and hence `ServiceA.Server` and transitively `ServiceA.Consumer` can't process any other request until the previous operation finishes.
This should cause timeouts in the callers of the following functions:
* initial `ServiceA.Api.compute/1` (the test runner process)
* `ServiceB.Api.compute/1` (that's the `ServiceA.Server` process registered under name `{:server_a, 42}`)
* `ServiceA.Api.compute/1` (that's the `ServiceB.Server` process registered under name `{:server_b, 42}`)

The `AMQP.Producer` process doesn't timeout - it only dispatches messages to the broker and handles replies once they deliver. 
However, the clients of the producer block until they receive a reply or until `GenServer`'s timeout (by default `5s`) is triggered (refer to `ServiceA.Server` tests for [more details](./test/service_a/server_test.exs)).

## Setup and Caveats

The example in [distributed_test.exs](./test/distributed_test.exs) creates a local erlang cluster which mimics a micro services setup but enables us to tests easily. 
The cluster has 5 nodes - 2 nodes (replicas) of `ServiceA`, 2 nodes of `ServiceB` and the test manager. 

In a proper micro services setup we would only cluster together erlang nodes of a given service as opposed to our fully connected local erlang cluster where all five nodes are connected to each other.
However, for our purposes this shouldn't matter as long as we make sure the globally registered names don't collide across services (which we make sure by having distinct name registrations `{:server_a, id}`, `{:server_b, id}` respectively).

Also, in the distributed test we deterministically spawn servers on given nodes whereas in the real world we would probably randomly pick any node of a given service to spawn a new process on (to distribute the load in a "stateless" way).

To encode the messages passed between services (which are just plain integers at the moment) erlang's `term_to_binary/1` function is used for simplicity but in the reality we would want to use some language agnostic protocol like [protobuf](https://protobuf.dev/).

Lastly, the services/servers are very simple and what they do feels very artificial but this example is meant to sketch out how we can run into a distributed deadlock and introduce a framework that enables us to test more realistic (and elaborate) scenarios in the future.

## Local Testing

To run tests locally start the broker by running
```console
$ docker-compose up -d amqp
```

Assuming you have Elixir installed locally, you can execute the tests from the root of the project by running:

```console
$ mix test
```