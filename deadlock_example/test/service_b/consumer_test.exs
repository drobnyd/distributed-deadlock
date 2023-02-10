defmodule ServiceB.ConsumerTest do
  use ExUnit.Case

  describe "RPC request to compute" do
    test "id 1 works fine" do
      id = 1
      start_supervised!(AMQPLib.Producer)

      start_supervised!({ServiceB.Server, id: id})
      start_supervised!(ServiceB.Consumer)

      assert {:ok, id} == ServiceB.Api.compute(id)
    end

  end
end
