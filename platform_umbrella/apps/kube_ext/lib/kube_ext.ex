defmodule KubeExt do
  require Jason

  def uid(resource) do
    get_in(resource, ~w(metadata uid))
  end

  def cluster_type, do: Application.get_env(:kube_ext, :cluster_type, :dev)

  def get_current_events do
    conn = KubeExt.ConnectionPool.get()

    operation = K8s.Client.list("v1", "Event")

    with {:ok, result} <- K8s.Client.run(conn, operation) do
      result
    end
  end
end
