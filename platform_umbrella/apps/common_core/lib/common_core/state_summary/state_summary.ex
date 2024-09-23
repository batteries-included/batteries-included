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

  use CommonCore, {:embedded_schema, no_encode: [:kube_state, :keycloak_state, :home_base_init_data]}

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Installation
  alias CommonCore.Installs.HomeBaseInitData

  batt_embedded_schema do
    # Database backed fields
    embeds_many :batteries, SystemBattery
    embeds_many :postgres_clusters, CommonCore.Postgres.Cluster
    embeds_many :ferret_services, CommonCore.FerretDB.FerretService
    embeds_many :redis_instances, CommonCore.Redis.RedisInstance
    embeds_many :notebooks, CommonCore.Notebooks.JupyterLabNotebook
    embeds_many :knative_services, CommonCore.Knative.Service
    embeds_many :traditional_services, CommonCore.TraditionalServices.Service
    embeds_many :ip_address_pools, CommonCore.MetalLB.IPAddressPool
    embeds_many :projects, CommonCore.Projects.Project
    embeds_many :model_instances, CommonCore.Ollama.ModelInstance

    # Fields not from the database
    embeds_one :keycloak_state, CommonCore.StateSummary.KeycloakSummary
    embeds_one :install_status, CommonCore.ET.InstallStatus
    embeds_one :stable_versions_report, CommonCore.ET.StableVersionsReport
    embeds_one :home_base_init_data, HomeBaseInitData

    field :captured_at, :utc_datetime_usec

    field :kube_state, :map, default: %{}
  end

  def target_summary(%Installation{} = installation, opts \\ []) do
    home_base_init_data = Keyword.get(opts, :home_base_init_data, %HomeBaseInitData{})
    batteries = CommonCore.Installs.Batteries.default_batteries(installation)

    cluster_args = CommonCore.Installs.Postgres.cluster_arg_list(batteries, installation)

    %__MODULE__{}
    |> changeset(
      %{
        batteries: Enum.map(batteries, fn b -> %{Map.from_struct(b) | config: Map.from_struct(b.config)} end),
        postgres_clusters: cluster_args,
        traditional_services: CommonCore.Installs.TraditionalServices.services(installation),
        home_base_init_data: Map.from_struct(home_base_init_data),
        # For now we don't have projects to add to the target summary
        # once we work out inter-cluster project sharing we can add this
        projects: []
      },
      action: :insert
    )
    |> apply_action(:insert)
  end
end
