defmodule CommonCore.Util.Tuple do
  @moduledoc """
  Utilities for working with tuples
  """

  @doc """
  Swaps elements in a 2 element tuple.

  ## Examples

        iex> CommonCore.Util.Tuple.swap({:a, "b"})
        {"b", :a}

        iex> CommonCore.Util.Tuple.swap({"b", :a})
        {:a, "b"}
  """
  @spec swap({term(), term()}) :: {term(), term()}
  def swap({l, r}), do: {r, l}
end
