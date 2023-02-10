defmodule DistributedTest do
  use ExUnit.Case

  setup do
    start_supervised!(AMQPLib.Producer)

    [service_a_node1, service_a_node2] = LocalCluster.start_nodes("service-a", 2)

    Support.DistTestHelper.setup_node(service_a_node1)
    Support.DistTestHelper.setup_node(service_a_node2)

    Support.DistTestHelper.start_child(service_a_node1, ServiceA.Consumer)

    1..30
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_a_node1, {ServiceA.Server, id: id})
    end)

    # Support.DistTestHelper.start_child(service_a_node2, ServiceA.Consumer)

    31..60
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_a_node2, {ServiceA.Server, id: id})
    end)

    [service_b_node1, service_b_node2] = LocalCluster.start_nodes("service-b", 2)

    Support.DistTestHelper.setup_node(service_b_node1)
    Support.DistTestHelper.setup_node(service_b_node2)

    Support.DistTestHelper.start_child(service_b_node1, ServiceB.Consumer)

    1..30
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_b_node1, {ServiceB.Server, id: id})
    end)

    # Support.DistTestHelper.start_child(service_b_node2, ServiceB.Consumer)

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
      :exit, {:timeout, _} -> assert true
    end
  end
end