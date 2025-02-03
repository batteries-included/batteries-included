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

  def changeset(model_instance, attrs, opts \\ []) do
    model_instance
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
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
    [
      {"Deepseek R1 1.5b (1.1GB)", "deepseek-r1:1.5b"},
      {"Deepseek R1 7b (4.7GB)", "deepseek-r1:7b"},
      {"Llama 3.2 3b (2.0GB)", "llama3.2:3b"},
      {"Llama 3.2 1b (1.3GB)", "llama3.2:1b"},
      {"Phi4 14b (9.1GB)", "phi4"},
      {"Llama 3.1 8b (4.9GB)", "llama3.1:8b"},
      {"Llama 3.1 70b (43GB)", "llama3.1:70b"},
      {"Nomic embed-text 137m (274MB)", "nomic-embed-text"},
      {"mxbai embed [Large] 335m (670MB)", "mxbai-embed-large"},
      {"Snowflake Arctic Embed 2.0 568m (1.2GB)", "snowflake-arctic-embed2"}
    ]
  end
end
