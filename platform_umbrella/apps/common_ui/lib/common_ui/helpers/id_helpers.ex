defmodule CommonUI.IDHelpers do
  @moduledoc """
  A module to provide a unique id to
  assigns if one is not provided. Useful for components that
  need to interact with specific DOM elements but don't want
  every component user to come up with world unique ids.
  """
  def provide_id(%{rest: %{id: id}} = assigns), do: Map.put(assigns, :id, id)
  def provide_id(%{id: nil} = assigns), do: Map.put(assigns, :id, generate())
  def provide_id(%{id: _} = assigns), do: assigns
  def provide_id(assigns), do: Map.put_new(assigns, :id, generate())

  defp generate, do: for(_ <- 1..16, into: "", do: <<Enum.random(?a..?z)>>)
end
