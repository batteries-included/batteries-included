defmodule ControlServer.SystemState do
  @moduledoc false
  alias Ecto.Multi

  def transaction do
    Multi.new()
    |> Multi.all(:batteries, CommonCore.Batteries.SystemBattery)
    |> Multi.all(:postgres_clusters, CommonCore.Postgres.Cluster)
    |> Multi.all(:ferret_services, CommonCore.FerretDB.FerretService)
    |> Multi.all(:redis_clusters, CommonCore.Redis.FailoverCluster)
    |> Multi.all(:notebooks, CommonCore.Notebooks.JupyterLabNotebook)
    |> Multi.all(:knative_services, CommonCore.Knative.Service)
    |> Multi.all(:backend_services, CommonCore.Backend.Service)
    |> Multi.all(:ip_address_pools, CommonCore.MetalLB.IPAddressPool)
    |> Multi.all(:projects, CommonCore.Projects.Project)
    |> ControlServer.Repo.transaction()
  end
end
