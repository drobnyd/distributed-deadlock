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

      assert {:ok, 1_000_000 + id} == ServiceA.Api.compute(id)
    end

    test "id 42 has a bug and deadlocks" do
      id = 42
      start_supervised!(AMQPLib.Producer)

      start_supervised!({ServiceA.Server, id: id})
      start_supervised!(ServiceA.Consumer)
      start_supervised!({ServiceB.Server, id: id})
      start_supervised!(ServiceB.Consumer)

      try do
        {:ok, _res} = ServiceA.Api.compute(id)
        assert false
      catch
        :exit, {:timeout, {GenServer, :call, _}} ->
          assert true
      end
    end
  end
end
