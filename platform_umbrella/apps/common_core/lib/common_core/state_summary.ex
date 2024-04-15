defmodule CommonCore.StateSummary do
  @moduledoc """
    The StateSummary module provides a struct to store and manage system state information.

    ## Example Usage

    ```elixir
    # Create a new state summary struct
    state_summary = %CommonCore.StateSummary{}

    # Access fields
    batteries = state_summary.batteries
    postgres_clusters = state_summary.postgres_clusters

    # Update fields
    state_summary = %{state_summary | batteries: [%CommonCore.Batteries.SystemBattery{}]}

  """
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Installation

  @derive Jason.Encoder

  @optional_fields ~w(kube_state)a
  @required_fields ~w()a

  typed_embedded_schema do
    embeds_many :batteries, SystemBattery
    embeds_many :postgres_clusters, CommonCore.Postgres.Cluster
    embeds_many :ferret_services, CommonCore.FerretDB.FerretService
    embeds_many :redis_clusters, CommonCore.Redis.FailoverCluster
    embeds_many :notebooks, CommonCore.Notebooks.JupyterLabNotebook
    embeds_many :knative_services, CommonCore.Knative.Service
    embeds_many :backend_services, CommonCore.Backend.Service
    embeds_many :ip_address_pools, CommonCore.MetalLB.IPAddressPool
    embeds_many :projects, CommonCore.Projects.Project

    embeds_one :keycloak_state, CommonCore.StateSummary.KeycloakSummary

    field :kube_state, :map, default: %{}
  end

  def changeset(state_summary, attrs) do
    fields = @required_fields ++ @optional_fields

    state_summary
    |> cast(attrs, fields)
    |> cast_embed(:batteries)
    |> cast_embed(:postgres_clusters)
    |> cast_embed(:ferret_services)
    |> cast_embed(:redis_clusters)
    |> cast_embed(:notebooks)
    |> cast_embed(:knative_services)
    |> cast_embed(:backend_services)
    |> cast_embed(:ip_address_pools)
    |> cast_embed(:projects)
    |> validate_required(@required_fields)
  end

  def new(map) do
    %__MODULE__{}
    |> changeset(map)
    |> apply_action(:insert)
  end

  def target_summary(%Installation{} = installation) do
    batteries = CommonCore.Installs.Batteries.default_batteries(installation)

    %__MODULE__{}
    |> changeset(%{
      batteries: Enum.map(batteries, fn b -> %{Map.from_struct(b) | config: Map.from_struct(b.config)} end),
      postgres_clusters: CommonCore.Installs.Postgres.cluster_arg_list(batteries, installation),
      # For now we don't have projects to add to the target summary
      # once we work out inter-cluster project sharing we can add this
      projects: []
    })
    |> apply_action(:insert)
  end
end
