defmodule KubeExt do
  require Jason

  def uid(resource) do
    get_in(resource, ~w(metadata uid))
  end

  def cluster_type, do: Application.get_env(:kube_ext, :cluster_type, :dev)
end
