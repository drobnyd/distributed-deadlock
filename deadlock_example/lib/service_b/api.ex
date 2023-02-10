defmodule ServiceB.Api do
  @spec compute(non_neg_integer) :: {:ok, number()}
  def compute(id) do
    {:ok, reply, _meta} = AMQPLib.Producer.call("amq.direct", "service_b", Protocol.encode(id))
    {:ok, Protocol.decode_int(reply)}
  end
end
