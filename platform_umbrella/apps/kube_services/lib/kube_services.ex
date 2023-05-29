defmodule KubeServices do
  @moduledoc """
  Documentation for `KubeServices`.
  """

  def get_current_events do
    conn = KubeServices.ConnectionPool.get()

    operation = K8s.Client.list("v1", "Event")

    with {:ok, result} <- K8s.Client.run(conn, operation) do
      result
    end
  end

  def cluster_type, do: Application.get_env(:kube_services, :cluster_type, :dev)
end
