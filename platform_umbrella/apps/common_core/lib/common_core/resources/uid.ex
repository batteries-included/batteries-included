defmodule CommonCore.Resources.UID do
  @moduledoc false
  def uid(resource) do
    get_in(resource, ~w(metadata uid))
  end
end
