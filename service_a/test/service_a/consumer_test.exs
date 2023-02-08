defmodule ServiceA.ConsumerTest do
  use ExUnit.Case

  test "RPC request to compute" do
    id = 42
    start_supervised!({ServiceA.Server, id: id})
    start_supervised!(AMQPLib.Producer)
    start_supervised!(ServiceA.Consumer)

    expected_reply = to_string(1_000_000 + id)
    assert {:ok, ^expected_reply, _meta} =
             AMQPLib.Producer.call("amq.direct", "service_a", to_string(id))
  end
end
