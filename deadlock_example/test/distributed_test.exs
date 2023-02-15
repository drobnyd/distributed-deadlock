defmodule DistributedTest do
  @moduledoc """
  Test suite integrating `ServiceA`, `ServiceB` and `amqp`.
  The `LocalCluster` setup imitates micro services.

  Note that `docker-compose up -d amqp` needs to be run prior to
  running the tests.
  """
  use ExUnit.Case

  setup do
    username = Application.fetch_env!(:amqp_lib, :username)
    password = Application.fetch_env!(:amqp_lib, :password)
    host = Application.fetch_env!(:amqp_lib, :host)
    connection_params = [username: username, password: password, host: host]

    start_supervised!({AMQPLib.Producer, connection_params})

    [service_a_node1, service_a_node2] =
      LocalCluster.start_nodes("service-a", 2,
        applications:
          Enum.map(Application.loaded_applications(), fn {appl, _, _} -> appl end) -- [:dialyxir]
      )

    Support.DistTestHelper.setup_node(service_a_node1)
    Support.DistTestHelper.setup_node(service_a_node2)

    Support.DistTestHelper.start_child(service_a_node1, {ServiceA.Consumer, connection_params})

    1..30
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_a_node1, {ServiceA.Server, id: id})
    end)

    Support.DistTestHelper.start_child(service_a_node2, {ServiceA.Consumer, connection_params})

    31..60
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_a_node2, {ServiceA.Server, id: id})
    end)

    [service_b_node1, service_b_node2] =
      LocalCluster.start_nodes("service-b", 2,
        applications:
          Enum.map(Application.loaded_applications(), fn {appl, _, _} -> appl end) -- [:dialyxir]
      )

    Support.DistTestHelper.setup_node(service_b_node1)
    Support.DistTestHelper.setup_node(service_b_node2)

    Support.DistTestHelper.start_child(service_b_node1, {ServiceB.Consumer, connection_params})

    1..30
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_b_node1, {ServiceB.Server, id: id})
    end)

    Support.DistTestHelper.start_child(service_b_node2, {ServiceB.Consumer, connection_params})

    31..60
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_b_node2, {ServiceB.Server, id: id})
    end)

    :ok
  end

  test "working scenario" do
    assert {:ok, 1_000_001} = ServiceA.Api.compute(1)
  end

  test "deadlock scenario" do
    try do
      {:ok, _result} = ServiceA.Api.compute(42)
      assert false
    catch
      :exit,
      {:timeout,
       {GenServer, :call,
        [AMQPLib.Producer, {:amqp_call, "amq.direct", "service_a.compute", bin_req}, 5000]}} ->
        assert bin_req == Proto.encode(42)
    end
  end
end
