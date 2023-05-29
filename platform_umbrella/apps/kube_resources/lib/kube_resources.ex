defmodule KubeResources do
  @moduledoc """
  Documentation for `KubeResources`.
  """

  def uid(resource) do
    get_in(resource, ~w(metadata uid))
  end
end
