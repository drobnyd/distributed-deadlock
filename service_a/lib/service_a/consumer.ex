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
      [{"amq.direct", "service_a", "queue", &handle_message/2}],
      name: __MODULE__
    )
  end

  defp handle_message(payload, meta) do
    Logger.info("#{__MODULE__} Received #{inspect(payload)} with meta #{inspect(meta)}")

    {id, ""} = Integer.parse(payload)

    Logger.info("Sending to server #{inspect(id)}")

    {:ok, result} = ServiceA.Server.compute(id)

    {:reply, to_string(result)}
  end
end