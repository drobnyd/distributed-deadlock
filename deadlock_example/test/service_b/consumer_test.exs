defmodule ServiceB.ConsumerTest do
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

      start_supervised!({ServiceB.Server, id: id})
      start_supervised!({ServiceB.Consumer, connection_params})

      assert {:ok, id} == ServiceB.Api.compute(id)
    end
  end
end
