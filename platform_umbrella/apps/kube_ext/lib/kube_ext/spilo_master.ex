defmodule KubeExt.SpiloMaster do
  @moduledoc """
  This module will help you with getting the current
  master of a postgres cluster. Assuming that cluster
  is using spilo and spilo labels. (Like postgres-operator)
  """
  alias CommonCore.ApiVersionKind
  alias KubeExt.ConnectionPool

  require Logger

  @spec get_master_pod(any, any) :: {:error, any()} | {:ok, map()}
  def get_master_pod(cluster, namespace) do
    operation = list_master_operation(cluster, namespace)

    conn = ConnectionPool.get()

    Logger.debug("Going to lids pods for #{cluster} in #{namespace} with master labels")

    case K8s.Client.run(conn, operation) do
      {:ok, %{"items" => [master_pod | _]}} ->
        {:ok, master_pod}

      _ ->
        {:error, "Couldn't fetch pod"}
    end
  end

  defp list_master_operation(cluster, namespace) do
    # We want the pod in the namespace that are running spilio (have a spilo-role label)
    # and are currently master (spilo-role = master)
    # and are for the given clustername ( cluster-name = cluster )
    :pod
    |> ApiVersionKind.from_resource_type!()
    |> then(fn {api_ver, kind} ->
      K8s.Client.list(api_ver, kind, namespace: namespace)
    end)
    |> K8s.Operation.put_selector(
      K8s.Selector.label(%{"spilo-role" => "master", "cluster-name" => cluster})
    )
  end
end
