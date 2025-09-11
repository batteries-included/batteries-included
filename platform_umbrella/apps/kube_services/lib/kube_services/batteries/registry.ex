defmodule KubeServices.Batteries.Registry do
  @moduledoc false

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    Registry.child_spec(keys: :unique, name: name)
  end
end
