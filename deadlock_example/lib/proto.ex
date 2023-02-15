defmodule Proto do
  @spec encode(term()) :: binary()
  def encode(term) do
    :erlang.term_to_binary(term)
  end

  @spec decode(binary()) :: term()
  def decode(bin) do
    :erlang.binary_to_term(bin)
  end
end
