defmodule ServiceB.Consumer do
  require Logger

  @spec child_spec(AMQPLib.connection_params()) :: Supervisor.child_spec()
  def child_spec(connection_params) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [connection_params]},
      type: :worker
    }
  end

  @spec start_link(AMQPLib.connection_params()) :: GenServer.on_start()
  def start_link(connection_params) do
    GenServer.start_link(
      AMQPLib.Consumer,
      [{connection_params, "amq.direct", "service_b", "service_b", &handle_message/2}],
      name: __MODULE__
    )
  end

  defp handle_message(payload, meta) do
    Logger.info(
      "#{node()}:#{inspect(self())}:#{__MODULE__} Received #{inspect(payload)} with meta #{inspect(meta)}"
    )

    id = Proto.decode(payload)

    Logger.info(
      "#{node()}:#{inspect(self())}:#{__MODULE__} Sending to #{ServiceB.Server} #{inspect(id)}"
    )

    {:ok, result} = ServiceB.Server.compute(id)

    {:reply, Proto.encode(result)}
  end
end
