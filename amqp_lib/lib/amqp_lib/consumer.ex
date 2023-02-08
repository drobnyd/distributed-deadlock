defmodule AMQPLib.Consumer do
  use GenServer
  use AMQP

  require Logger

  def start_link(exchange, routing_key, queue, recv_callback) do
    GenServer.start_link(__MODULE__, [{exchange, routing_key, queue, recv_callback}],
      name: String.to_atom(queue)
    )
  end

  @impl GenServer
  def init([{exchange, routing_key, queue, recv_callback}]) do
    host = System.fetch_env!("HOST")
    username = System.fetch_env!("USERNAME")
    password = System.fetch_env!("PASSWORD")

    {:ok, connection} = Connection.open(host: host, username: username, password: password)
    {:ok, channel} = AMQP.Channel.open(connection)
    {:ok, _} = AMQP.Queue.declare(channel, queue)
    :ok = AMQP.Queue.bind(channel, queue, exchange, routing_key: routing_key)
    :ok = AMQP.Basic.qos(channel, prefetch_count: 0)
    {:ok, tag} = AMQP.Basic.consume(channel, queue, nil, no_ack: true)

    Logger.info(
      "Consumer start consuming from queue: #{inspect(queue)} - consumer tag: #{inspect(tag)}"
    )

    {:ok, %{channel: channel, consumer_tag: tag, recv_callback: recv_callback}}
  end

  @impl GenServer
  def handle_info({:basic_consume_ok, _}, state), do: {:noreply, state}

  @impl GenServer
  def handle_info({:basic_deliver, payload, meta}, state) do
    :ok =
      payload
      |> state.recv_callback.(meta)
      |> reply(meta, state)

    {:noreply, state}
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
