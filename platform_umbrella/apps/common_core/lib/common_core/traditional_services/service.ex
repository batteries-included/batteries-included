defmodule CommonCore.TraditionalServices.Service do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project]}

  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory

  @service_size_preset [
    %{
      name: "tiny",
      cpu_requested: 500,
      cpu_limits: 500,
      memory_requested: Memory.to_bytes(512, :MB),
      memory_limits: Memory.to_bytes(512, :MB)
    },
    %{
      name: "small",
      cpu_requested: 500,
      cpu_limits: 2000,
      memory_requested: Memory.to_bytes(1, :GB),
      memory_limits: Memory.to_bytes(4, :GB)
    },
    %{
      name: "medium",
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.to_bytes(8, :GB),
      memory_limits: Memory.to_bytes(8, :GB)
    },
    %{
      name: "large",
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.to_bytes(16, :GB),
      memory_limits: Memory.to_bytes(16, :GB)
    },
    %{
      name: "xlarge",
      cpu_requested: 10_000,
      cpu_limits: 10_000,
      memory_requested: Memory.to_bytes(32, :GB),
      memory_limits: Memory.to_bytes(32, :GB)
    },
    %{
      name: "huge",
      cpu_requested: 32_000,
      cpu_limits: 32_000,
      memory_requested: Memory.to_bytes(256, :GB),
      memory_limits: Memory.to_bytes(256, :GB)
    }
  ]

  @required_fields ~w(name num_instances)a

  batt_schema "traditional_services" do
    slug_field :name

    field :kube_internal, :boolean, default: false
    field :kube_deployment_type, Ecto.Enum, values: [:statefulset, :deployment], default: :deployment
    field :num_instances, :integer, default: 1

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true

    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    embeds_many :containers, CommonCore.Containers.Container, on_replace: :delete
    embeds_many :init_containers, CommonCore.Containers.Container, on_replace: :delete
    embeds_many :env_values, CommonCore.Containers.EnvValue, on_replace: :delete
    embeds_many :ports, CommonCore.Port, on_replace: :delete

    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(service, attrs) do
    service
    |> CommonCore.Ecto.Schema.schema_changeset(attrs)
    |> maybe_set_virtual_size(@service_size_preset)
    |> unique_constraint(:name)
  end

  def preset_options_for_select do
    Enum.map(@service_size_preset, &{String.capitalize(&1.name), &1.name})
  end
end
