defmodule KubeResources.ML.VirtualServices do
  alias KubeResources.Notebooks

  def virtual_services(config) do
    Notebooks.virtual_service(config)
  end
end
