defmodule CommonCore.Resources.UID do
  def uid(resource) do
    get_in(resource, ~w(metadata uid))
  end
end
