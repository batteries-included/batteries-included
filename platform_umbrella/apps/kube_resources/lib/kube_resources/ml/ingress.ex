defmodule KubeResources.MLIngress do
  alias KubeResources.Notebooks

  def ingress(config) do
    Notebooks.ingress(config)
  end
end
