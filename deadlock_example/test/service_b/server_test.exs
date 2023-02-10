defmodule ServiceB.ServerTest do
  use ExUnit.Case

  describe "compute/1" do
    test "id 1" do
      id = 1
      start_supervised!({ServiceB.Server, id: id})

      assert {:ok, id} == ServiceB.Server.compute(id)
    end
  end
end
