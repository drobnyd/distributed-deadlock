defmodule Protocol do
  @spec encode(term()) :: binary()
  def encode(term) do
    :erlang.term_to_binary(term)
  end

  @spec decode_int(binary()) :: term()
  def decode_int(bin) do
    res = :erlang.binary_to_term(bin)
    {res_int, ""} = Integer.parse(res)
    res_int
  end
end
