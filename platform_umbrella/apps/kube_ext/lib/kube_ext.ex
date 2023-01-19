defmodule KubeExt do
  require Jason

  def uid(resource) do
    get_in(resource, ~w(metadata uid))
  end

  def cluster_type, do: Application.get_env(:kube_ext, :cluster_type, :dev)

  def get_logs(namespace, name, opts \\ [tailLines: 100]) do
    conn = KubeExt.ConnectionPool.get()

    operation = K8s.Client.get("v1", "pods/log", name: name, namespace: namespace)
    # There's no easy way to create sub-resource operations with query params.
    enriched_operation = Map.put(operation, :query_params, opts)

    with {:ok, log_str} <- K8s.Client.run(conn, enriched_operation) do
      to_string(log_str)
      |> String.split(~r{\n})
      |> Enum.filter(&(&1 != ""))
    end
  end

  def get_current_events do
    conn = KubeExt.ConnectionPool.get()

    operation = K8s.Client.list("v1", "Event")

    with {:ok, result} <- K8s.Client.run(conn, operation) do
      result
    end
  end
end
