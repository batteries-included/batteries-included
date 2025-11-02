defmodule KubeServices.RoboSRE.Registry do
  @moduledoc """
  Registry for RoboSRE issue worker processes.

  This allows us to look up worker processes by issue ID.
  """

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    Registry.child_spec(keys: :unique, name: name)
  end
end
