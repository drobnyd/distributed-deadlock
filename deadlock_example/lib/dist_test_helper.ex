# TODO only compile for tests
defmodule Support.DistTestHelper do
  @spec setup_node(node()) :: {:ok, pid()}
  def setup_node(node) do
    pid = Node.spawn_link(node, __MODULE__, :start_supervisor, [self()])

    receive do
      {:ok, ^node} -> {:ok, pid}
    after
      5_000 -> raise "Failed to setup a service on a remote node #{inspect(node())}"
    end
  end

  @spec start_supervisor(pid()) :: :ok
  def start_supervisor(test_runner_pid) do
    {:ok, _pid} =
      Supervisor.start_link(
        [{DynamicSupervisor, strategy: :one_for_one, name: DynamicSupervisor}, AMQPLib.Producer],
        strategy: :one_for_one
      )

    send(test_runner_pid, {:ok, node()})

    receive do
      {:stop, pid} ->
        send(pid, :stopped)
    end
  end

  def start_child(node, child_spec) do
    {:ok, _pid} =
      :erpc.call(node, fn -> DynamicSupervisor.start_child(DynamicSupervisor, child_spec) end)
  end
end
