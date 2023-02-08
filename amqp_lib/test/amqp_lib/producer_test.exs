defmodule AMQPLib.ProducerTest do
  use ExUnit.Case

  require Logger

  alias AMQPLib.{Producer, Consumer}

  @exchange "amq.direct"
  @routing_key "routing_key"

  test "greets the world" do
    start_supervised!(Producer)

    request = "hello"
    response = "world"

    Consumer.start_link(
      @exchange,
      @routing_key,
      "queue",
      fn ^request, _meta ->
        {:reply, response}
      end
    )

    assert {:ok, ^response, _meta} = Producer.call(@exchange, @routing_key, request)
  end
end
