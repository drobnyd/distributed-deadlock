defmodule ServiceA.ServerTest do
  use ExUnit.Case

  setup do
    start_supervised!(AMQPLib.Producer)

    [service_a_node1, service_a_node2] = LocalCluster.start_nodes("service-a", 2)

    Support.DistTestHelper.setup_node(service_a_node1)
    Support.DistTestHelper.setup_node(service_a_node2)

    Support.DistTestHelper.start_child(service_a_node1, ServiceA.Consumer)

    1..20
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_a_node1, {ServiceA.Server, id: id})
    end)

    Support.DistTestHelper.start_child(service_a_node2, ServiceA.Consumer)

    21..40
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_a_node2, {ServiceA.Server, id: id})
    end)

    [service_b_node1, service_b_node2] = LocalCluster.start_nodes("service-b", 2)

    Support.DistTestHelper.setup_node(service_b_node1)
    Support.DistTestHelper.setup_node(service_b_node2)

    Support.DistTestHelper.start_child(service_b_node1, ServiceB.Consumer)

    1..20
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_b_node1, {ServiceB.Server, id: id})
    end)

    Support.DistTestHelper.start_child(service_b_node2, ServiceB.Consumer)

    21..40
    |> Enum.to_list()
    |> Enum.each(fn id ->
      Support.DistTestHelper.start_child(service_b_node2, {ServiceB.Server, id: id})
    end)

    :ok
  end

  test "working scenario" do
    {:ok, reply, _meta} = AMQPLib.Producer.call("amq.direct", "service_a", "1")
    {reply_num, ""} = Integer.parse(reply)
    assert 1_000_001 == reply_num
  end

  test "deadlock scenario" do
    try do
      AMQPLib.Producer.call("amq.direct", "service_a", "42")
      assert false
    catch
      :exit, {:timeout, _} -> assert true
    end
  end
end
