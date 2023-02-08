defmodule AMQPLib.Producer do
  use GenServer
  use AMQP

  require Logger

  @spec call(String.t(), String.t(), binary()) ::
          {:ok, payload :: binary(), meta :: map()} | {:error, term()}
  def call(exchange, routing_key, payload) do
    GenServer.call(
      __MODULE__,
      {:amqp_call, exchange, routing_key, payload}
    )
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    host = System.fetch_env!("HOST")
    username = System.fetch_env!("USERNAME")
    password = System.fetch_env!("PASSWORD")

    {:ok, connection} = Connection.open(host: host, username: username, password: password)
    {:ok, channel} = Channel.open(connection)

    {:ok, %{queue: reply_queue_name}} =
      AMQP.Queue.declare(channel, _queue_name = "", auto_delete: true)

    {:ok, consumer_tag} = AMQP.Basic.consume(channel, reply_queue_name, nil, no_ack: true)

    AMQP.Basic.return(channel, self())

    {:ok,
     %{
       channel: channel,
       consumer_tag: consumer_tag,
       reply_queue: reply_queue_name,
       awaiting_replies: %{}
     }}
  end

  @impl GenServer
  def handle_call(
        {:amqp_call, exchange, routing_key, payload},
        from,
        state
      ) do
    correlation_id = "#{System.unique_integer([:positive])}"

    :ok =
      AMQP.Basic.publish(
        state.channel,
        exchange,
        routing_key,
        payload,
        correlation_id: correlation_id,
        reply_to: state.reply_queue,
        expiration: 1_000
      )

    {:noreply, %{state | awaiting_replies: Map.put(state.awaiting_replies, correlation_id, from)}}
  end

  @impl GenServer
  def handle_info({:basic_consume_ok, _}, state), do: {:noreply, state}

  @impl GenServer
  def handle_info(
        {:basic_deliver, payload, %{correlation_id: correlation_id} = meta},
        state
      ) do
    Logger.info("Received reply #{inspect(payload)} - #{inspect(meta)}")

    new_awaiting_replies =
      case Map.pop(state.awaiting_replies, correlation_id) do
        {nil, ^state} ->
          Logger.error("Unexpected reply received, correlation id: #{inspect(correlation_id)}")
          state

        {from, new_awaiting_replies} ->
          GenServer.reply(from, {:ok, payload, meta})
          new_awaiting_replies
      end

    {:noreply, %{state | awaiting_replies: new_awaiting_replies}}
  end
end
