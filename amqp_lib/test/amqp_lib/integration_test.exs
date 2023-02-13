defmodule AMQPLib.IntegrationTest do
  @moduledoc """
  Tests the integration between `AMQP.Producer` and `AMQP.Consumer`.
  """
  use ExUnit.Case

  require Logger

  alias AMQPLib.{Producer, Consumer}

  @exchange "amq.direct"
  @routing_key "routing_key"

  test "greets the world" do
    username = Application.fetch_env!(:amqp_lib, :username)
    password = Application.fetch_env!(:amqp_lib, :password)
    host = Application.fetch_env!(:amqp_lib, :host)
    connection_params = [username: username, password: password, host: host]

    start_supervised!({Producer, connection_params})

    request = "hello"
    response = "world"

    start_supervised!(
      {Consumer,
       {
         connection_params,
         @exchange,
         @routing_key,
         "",
         fn ^request, _meta ->
           {:reply, response}
         end
       }}
    )

    assert {:ok, ^response, _meta} = Producer.call(@exchange, @routing_key, request)
  end
end
