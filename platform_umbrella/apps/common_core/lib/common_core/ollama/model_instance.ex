defmodule CommonCore.Ollama.ModelInstance do
  @moduledoc false
  use CommonCore, {:schema, no_encode: [:project]}

  alias CommonCore.Util.Memory

  @required_fields ~w(name)a

  @presets [
    %{
      name: "tiny",
      cpu_requested: 500,
      memory_requested: Memory.to_bytes(512, :MB),
      memory_limits: Memory.to_bytes(512, :MB)
    },
    %{
      name: "medium",
      cpu_requested: 4000,
      memory_requested: Memory.to_bytes(8, :GB),
      memory_limits: Memory.to_bytes(8, :GB)
    },
    %{
      name: "large",
      cpu_requested: 8000,
      memory_requested: Memory.to_bytes(16, :GB),
      memory_limits: Memory.to_bytes(16, :GB)
    },
    %{
      name: "xlarge",
      cpu_requested: 10_000,
      memory_requested: Memory.to_bytes(64, :GB),
      memory_limits: Memory.to_bytes(64, :GB)
    },
    %{
      name: "huge",
      cpu_requested: 32_000,
      memory_requested: Memory.to_bytes(256, :GB),
      memory_limits: Memory.to_bytes(256, :GB)
    }
  ]

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name, :memory_limits, :gpu_count]
  }

  batt_schema "model_instances" do
    slug_field :name

    field :model, :string, default: "llama3.1"
    field :num_instances, :integer, default: 1

    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    field :gpu_count, :integer, default: 0

    field :virtual_size, :string, virtual: true

    belongs_to :project, CommonCore.Projects.Project

    timestamps()
  end

  def changeset(model_instance, attrs) do
    model_instance
    |> CommonCore.Ecto.Schema.schema_changeset(attrs)
    |> maybe_set_virtual_size(@presets)
    |> validate_number(:cpu_requested, greater_than: 0, less_than: 100_000)
    |> validate_number(:cpu_limits, greater_than: 0, less_than: 100_000)
    |> validate_number(:memory_requested, greater_than: 0, less_than: Memory.to_bytes(1_000, :TB))
    |> validate_number(:memory_limits, greater_than: 0, less_than: Memory.to_bytes(1_000, :TB))
    |> foreign_key_constraint(:project_id)
  end

  def preset_options_for_select do
    Enum.map(@presets, &{String.capitalize(&1.name), &1.name})
  end

  def model_options_for_select do
    [{"Meta's Llama 3.1", "llama3.1"}, {"Google's Gemma 2", "gemma2"}, {"mxbai embed (Large)", "mxbai-embed-large"}]
  end
end