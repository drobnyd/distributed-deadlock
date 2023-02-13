defmodule ServiceA.ConsumerTest do
  use ExUnit.Case

  setup do
    username = Application.fetch_env!(:amqp_lib, :username)
    password = Application.fetch_env!(:amqp_lib, :password)
    host = Application.fetch_env!(:amqp_lib, :host)
    connection_params = [username: username, password: password, host: host]

    {:ok, %{connection_params: connection_params}}
  end

  describe "RPC request to compute" do
    test "id 1 works fine", %{connection_params: connection_params} do
      id = 1
      start_supervised!({AMQPLib.Producer, connection_params})

      start_supervised!({ServiceA.Server, id: id})
      start_supervised!({ServiceA.Consumer, connection_params})
      start_supervised!({ServiceB.Server, id: id})
      start_supervised!({ServiceB.Consumer, connection_params})

      assert {:ok, 1_000_000 + id} == ServiceA.Api.compute(id)
    end

    test "id 42 has a bug and deadlocks", %{connection_params: connection_params} do
      id = 42
      start_supervised!({AMQPLib.Producer, connection_params})

      start_supervised!({ServiceA.Server, id: id})
      start_supervised!({ServiceA.Consumer, connection_params})
      start_supervised!({ServiceB.Server, id: id})
      start_supervised!({ServiceB.Consumer, connection_params})

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
