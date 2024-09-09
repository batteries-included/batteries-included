defmodule ControlServer.SystemState do
  @moduledoc false

  use ControlServer, :context

  def transaction do
    Multi.new()
    |> Multi.all(:batteries, CommonCore.Batteries.SystemBattery)
    |> Multi.all(:postgres_clusters, CommonCore.Postgres.Cluster)
    |> Multi.all(:ferret_services, CommonCore.FerretDB.FerretService)
    |> Multi.all(:redis_instances, CommonCore.Redis.RedisInstance)
    |> Multi.all(:notebooks, CommonCore.Notebooks.JupyterLabNotebook)
    |> Multi.all(:knative_services, CommonCore.Knative.Service)
    |> Multi.all(:traditional_services, CommonCore.TraditionalServices.Service)
    |> Multi.all(:ip_address_pools, CommonCore.MetalLB.IPAddressPool)
    |> Multi.all(:projects, CommonCore.Projects.Project)
    |> Multi.all(:model_instances, CommonCore.Ollama.ModelInstance)
    |> Repo.transaction()
  end
end
