defmodule ServiceA.ServerTest do
  use ExUnit.Case

  test "start two instances of service a" do
    [service_a_node1, service_a_node2] = LocalCluster.start_nodes("service-a", 2)

    Support.DistTestHelper.setup_node(service_a_node1)
    Support.DistTestHelper.setup_node(service_a_node2)

    Support.DistTestHelper.start_child(service_a_node1, {ServiceA.Server, id: 1})
    Support.DistTestHelper.start_child(service_a_node1, ServiceA.Consumer)

    # Support.DistTestHelper.start_child(service_a_node2, {ServiceA.Server, id: 2})

    # Support.DistTestHelper.start_child(service_a_node2, AMQPLib.Producer)
    # Support.DistTestHelper.start_child(service_a_node2, ServiceA.Consumer)

    [service_b_node1, service_b_node2] = LocalCluster.start_nodes("service-b", 2)

    Support.DistTestHelper.setup_node(service_b_node1)
    Support.DistTestHelper.setup_node(service_b_node2)

    Support.DistTestHelper.start_child(service_b_node1, {ServiceB.Server, id: 1})
    Support.DistTestHelper.start_child(service_b_node1, ServiceB.Consumer)

    # Support.DistTestHelper.start_child(service_b_node2, {ServiceB.Server, id: 2})

    # Support.DistTestHelper.start_child(service_b_node2, AMQPLib.Producer)
    # Support.DistTestHelper.start_child(service_b_node2, ServiceB.Consumer)

    # Call
    start_supervised!(AMQPLib.Producer)
    {:ok, reply, _meta} = AMQPLib.Producer.call("amq.direct", "service_a", "1")
    {reply_num, ""} = Integer.parse(reply)
    assert 1_000_001 == reply_num
  end
end
