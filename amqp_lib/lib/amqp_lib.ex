defmodule AMQPLib do
  @moduledoc """
  Library for publishing and consuming messages through AMQP message broker.
  """

  @typedoc """
  AMQP Connection parameters are a keyword list that includes the following keys:
  * `host`
  * `username`
  * `password`
  """
  @type connection_params :: [
    {:host, String.t()}
    | {:username, String.t()}
    | {:password, String.t()}
  ]
end
