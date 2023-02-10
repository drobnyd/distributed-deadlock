defmodule ServiceA.Api do

  @spec compute(non_neg_integer) :: {:ok, number()}
  def compute(id) do
    {:ok, reply, _meta} = AMQPLib.Producer.call("amq.direct", "service_a", to_string(id))
    {reply_num, ""} = Integer.parse(reply)
    {:ok, reply_num}
  end
end
