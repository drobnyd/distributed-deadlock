defmodule ServiceA.ConsumerTest do
  use ExUnit.Case

  describe "RPC request to compute" do
    test "id 1 works fine" do
      id = 1
      start_supervised!(AMQPLib.Producer)

      start_supervised!({ServiceA.Server, id: id})
      start_supervised!(ServiceA.Consumer)
      start_supervised!({ServiceB.Server, id: id})
      start_supervised!(ServiceB.Consumer)

      expected_reply = to_string(1_000_000 + id)

      assert {:ok, ^expected_reply, _meta} =
               AMQPLib.Producer.call("amq.direct", "service_a", to_string(id))
    end

    test "id 42 has a bug and deadlocks" do
      id = 42
      start_supervised!(AMQPLib.Producer)

      start_supervised!({ServiceA.Server, id: id})
      start_supervised!(ServiceA.Consumer)
      start_supervised!({ServiceB.Server, id: id})
      start_supervised!(ServiceB.Consumer)

      try do
        AMQPLib.Producer.call("amq.direct", "service_a", to_string(id))
        assert false
      catch
        :exit, {:timeout, reason} ->
          assert true
      end
    end
  end
end
