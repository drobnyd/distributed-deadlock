# Distributed Deadlock Example

Example of a distributed deadlock in a setup with RabbitMQ broker and two different micro services that form clusters of two replicas.

## Description of the services

### ServiceA

`ServiceA` spawns a single consumer that dispatches requests to process by underlying `ServiceA.Server` processes based on `ID` in the message. 
The server processes are [globally registered](https://hexdocs.pm/elixir/1.12/GenServer.html#module-name-registration) in the erlang cluster (using the `global` [process registry](https://www.erlang.org/doc/man/global.html) from `OTP`) so the actual handling might happen on either of the nodes.
The consumer process is blocked until a reply for the request is computed.

A server in `ServiceA` needs to make an RPC `ServiceB` to compute the result. 

### ServiceB

Similarly, `ServiceB` spawns a single consumer that distributes requests to underlying `ServiceB.Server` processes based on `ID` in the message. 
Just like before, the processes are globally registered in the erlang cluster.

`ServiceB.Server` most of the times doesn't need to make an RPC but can purely compute a result with the exception of handling message with `ID` `42` which requires additional data obtained from `ServiceA`.
However, this turns out to be a bug if the `ServiceB.Server`'s computation with `ID` `42` was triggered by `ServiceA` because that would mean that the request to `ServiceA` will be handled by `ServiceA.Server` with registered under the name `{:server_a, 42}` which must be the same process that is waiting for a reply from `ServiceB` and hence can't process any other request until the previous operation finishes. 
This should cause in callers of:
* initial `ServiceA.Api.compute/1`
* `ServiceB.Api.compute/1` (that's the `ServiceA.Server` process registered under name `{:server_a, 42}`)
* `ServiceA.Api.compute/1` (that's the `ServiceB.Server` process registered under name `{:server_b, 42}`)

The `AMQP.Producer` process doesn't timeout - it only dispatches messages to the broker and handles replies once they deliver. However producer is called through `GenServer` callbacks which have the default timeout set to 5s and this is what triggers the crashes (this is illustrated in the `ServiceA.ServerTest` suite).

## Setup and Caveats

The example in `dist_deadlock_example/deadlock_example/test/distributed_test.exs` sets up a local erlang cluster which mimics micro services setup but enables us to set up tests more easily. 
The cluster has 5 nodes - 2 replicas of `ServiceA`, 2 replicas of `ServiceB` and the test manager. 

In a proper micro services setup we would only cluster erlang nodes of a given service together as opposed to our erlang cluster where all the five nodes are connected to each other. 
However, for our purposes this shouldn't matter as long as we make sure the global names don't collide across services (which we make sure by having distinct name registrations `{:server_a, id}`, `{:server_b, id}` respectively).

Also, in our test setup we deterministically spawn servers on given nodes whereas in the real world we would probably randomly pick a node of given service to spawn a new process on (to guarantee proper distribution of load).

To encode the messages passed between services (which are plainly integers at the moment) erlang's `term_to_binary/1` function is used for simplicity but in reality we would want to use some language agnostic protocol like [protobuf](https://protobuf.dev/).

Lastly, the servers are very simple and what they do feels very artificial but this example is just meant to sketch out how a distributed deadlock can occur and introduce a framework from which we can come up with more realistic (and elaborate) scenarios.

### Local Testing

To run tests locally start the broker by running
```console
$ docker-compose up -d amqp
```

from the root of the repository and then run the tests by:

```console
$ mix test
```