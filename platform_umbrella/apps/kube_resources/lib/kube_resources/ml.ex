defmodule KubeResources.ML do
  alias KubeResources.Notebooks

  def materialize(config) do
    Map.merge(%{}, Notebooks.notebooks(config))
  end
end
