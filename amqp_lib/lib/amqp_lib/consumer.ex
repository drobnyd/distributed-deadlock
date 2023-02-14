defmodule AMQPLib.Consumer do
  @moduledoc """
  Consumer process that processes incoming messages and publishes results.
  """
  use GenServer
  use AMQP

  require Logger

  @doc """
  Consumer declares a queue, binds it to the `exchange` with provided `routing_key`.
  When message is received, `handler_fun` gets called and the result is sent back through
  the default exchange with `reply_to` routing key that is provided in the original message.

  If the `exchange` parameter is an empty string the direct exchange will be used (equivalent to `"amqp.direct"`).
  If the `queue` parameter is an empty string an auto-generated queue name will be used.
  """
  @spec start_link(
          {AMQPLib.connection_params(), String.t(), String.t(), String.t(),
           (binary(), map() -> {:reply, binary()})}
        ) :: GenServer.on_start()
  def start_link({connection_params, exchange, routing_key, queue, handler_fun}) do
    GenServer.start_link(__MODULE__, [
      {connection_params, exchange, routing_key, queue, handler_fun}
    ])
  end

  @impl GenServer
  def init([{connection_params, exchange, routing_key, queue, handler_fun}]) do
    {:ok, connection} = Connection.open(connection_params)
    {:ok, channel} = AMQP.Channel.open(connection)
    {:ok, _} = AMQP.Queue.declare(channel, queue)
    :ok = AMQP.Queue.bind(channel, queue, exchange, routing_key: routing_key)
    :ok = AMQP.Basic.qos(channel, prefetch_count: 0)
    {:ok, tag} = AMQP.Basic.consume(channel, queue, nil, no_ack: true)

    Logger.info(
      "Consumer started consuming from queue: #{inspect(queue)}. Consumer tag: #{inspect(tag)}"
    )

    {:ok, %{channel: channel, connection: connection, consumer_tag: tag, handler_fun: handler_fun}}
  end

  @impl GenServer
  def handle_info({:basic_consume_ok, _}, state), do: {:noreply, state}

  @impl GenServer
  def handle_info({:basic_deliver, payload, meta}, state) do
    :ok =
      payload
      |> state.handler_fun.(meta)
      |> reply(meta, state)

    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, %{channel: channel, connection: connection, consumer_tag: tag}) do
    AMQP.Basic.cancel(channel, tag)
    AMQP.Channel.close(channel)
    AMQP.Connection.close(connection)
    Logger.info("Consumer #{inspect({__MODULE__, self()})} terminating")
    :ok
  end

  defp reply(
         {:reply, resp_payload},
         %{reply_to: reply_to, correlation_id: correlation_id} = meta,
         state
       )
       when is_binary(resp_payload) do
    case AMQP.Basic.publish(state.channel, "", reply_to, resp_payload,
           correlation_id: correlation_id
         ) do
      :ok ->
        Logger.info("Sending reply #{inspect({resp_payload, meta})}")
        :ok

      error ->
        Logger.warn(
          "Bad publish result  #{inspect(error)} on reply #{inspect(resp_payload)}, #{meta}"
        )

        error
    end
  end
end
