defmodule ServiceB.Api do
  @spec compute(non_neg_integer) :: {:ok, number()}
  def compute(id) do
    {:ok, reply, _meta} = AMQPLib.Producer.call("amq.direct", "service_b", Proto.encode(id))
    {:ok, Proto.decode(reply)}
  end
end
