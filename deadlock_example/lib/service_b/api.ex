defmodule ServiceB.Api do
  
  @spec compute(non_neg_integer) :: {:ok, number()}
  def compute(id) do
    {:ok, reply, _meta} = AMQPLib.Producer.call("amq.direct", "service_b", to_string(id))
    {reply_num, ""} = Integer.parse(reply)
    {:ok, reply_num}
  end
end
