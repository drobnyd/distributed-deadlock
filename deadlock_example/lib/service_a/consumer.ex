defmodule ServiceA.Consumer do
  require Logger

  @spec child_spec(non_neg_integer()) :: Supervisor.child_spec()
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker
    }
  end

  def start_link() do
    GenServer.start_link(
      AMQPLib.Consumer,
      [{"amq.direct", "service_a", "", &handle_message/2}],
      name: __MODULE__
    )
  end

  defp handle_message(payload, meta) do
    Logger.info(
      "#{node()}:#{inspect(self())}:#{__MODULE__} Received #{inspect(payload)} with meta #{inspect(meta)}"
    )

    id = Protocol.decode_int(payload)

    Logger.info(
      "#{node()}:#{inspect(self())}:#{__MODULE__} Sending to #{ServiceA.Server} #{inspect(id)}"
    )

    {:ok, result} = ServiceA.Server.compute(id)

    {:reply, Protocol.encode(result)}
  end
end