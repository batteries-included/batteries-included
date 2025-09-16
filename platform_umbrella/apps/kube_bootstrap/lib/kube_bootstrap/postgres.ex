defmodule KubeBootstrap.Postgres do
  @moduledoc """
  Module to handle the waiting for Postgres clusters to be ready in a Kubernetes environment.
  It checks the status of the Postgres clusters and their associated pods, ensuring they are ready before proceeding.
  """

  alias CommonCore.Postgres.Cluster
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.PostgresState

  require Logger

  @spec wait_for_postgres(K8s.Conn.t(), StateSummary.t()) :: :ok | {:error, list()}
  def wait_for_postgres(%K8s.Conn{} = conn, %StateSummary{postgres_clusters: clusters} = summary) do
    errors =
      clusters
      |> Enum.map(&wait_for_cluster_service(summary, &1, conn))
      |> Enum.filter(&error?/1)

    if Enum.empty?(errors) do
      Logger.info("Postgres Clusters are ready")
      :ok
    else
      Logger.error("Postgres Clusters failed to start", errors: errors)
      {:error, errors}
    end
  end

  defp wait_for_cluster_service(summary, %Cluster{} = cluster, conn) do
    namespace = PostgresState.cluster_namespace(summary, cluster)

    pod_operation =
      "v1"
      |> K8s.Client.list(:pod, namespace: namespace)
      |> K8s.Selector.label(%{
        "role" => "primary",
        "cnpg.io/cluster" => "pg-#{cluster.name}"
      })
      |> K8s.Selector.field({"status.phase", "Running"})

    Logger.info("Waiting for Postgres service and pods", cluster: cluster.name)

    with {:ok, _} <-
           K8s.Client.wait_until(conn, pod_operation,
             find: fn
               %{"items" => items} ->
                 !Enum.empty?(items)

               _ ->
                 false
             end,
             eval: true,
             timeout: 600
           ) do
      {:ok, cluster}
    end
  end

  defp error?({:error, _}), do: true
  defp error?(:error), do: false
  defp error?(_), do: false
end
