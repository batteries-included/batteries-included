defmodule CommonCore.Projects.ProjectSnapshotSummary do
  @moduledoc false
  use CommonCore, :embedded_schema

  batt_embedded_schema do
    field :id, CommonCore.Ecto.BatteryUUID
    field :name, :string
    field :description, :string

    field :num_postgres_clusters, :integer, default: 0
    field :num_redis_instances, :integer, default: 0
    field :num_ferret_services, :integer, default: 0
    field :num_jupyter_notebooks, :integer, default: 0
    field :num_knative_services, :integer, default: 0
    field :num_traditional_services, :integer, default: 0
    field :num_model_instances, :integer, default: 0
  end
end
