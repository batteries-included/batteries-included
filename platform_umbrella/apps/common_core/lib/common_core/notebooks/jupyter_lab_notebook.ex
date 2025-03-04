defmodule CommonCore.Notebooks.JupyterLabNotebook do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project]}

  alias CommonCore.Containers.EnvValue
  alias CommonCore.Defaults.GPU
  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name, :storage_size, :memory_limits]
  }

  @presets [
    %{
      name: "tiny",
      storage_size: Memory.to_bytes(512, :MB),
      cpu_requested: 500,
      cpu_limits: 500,
      memory_requested: Memory.to_bytes(512, :MB),
      memory_limits: Memory.to_bytes(512, :MB)
    },
    %{
      name: "small",
      storage_size: Memory.to_bytes(16, :GB),
      cpu_requested: 500,
      cpu_limits: 2000,
      memory_requested: Memory.to_bytes(1, :GB),
      memory_limits: Memory.to_bytes(4, :GB)
    },
    %{
      name: "medium",
      storage_size: Memory.to_bytes(64, :GB),
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.to_bytes(8, :GB),
      memory_limits: Memory.to_bytes(8, :GB)
    },
    %{
      name: "large",
      storage_size: Memory.to_bytes(128, :GB),
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.to_bytes(16, :GB),
      memory_limits: Memory.to_bytes(16, :GB)
    },
    %{
      name: "xlarge",
      storage_size: Memory.to_bytes(256, :GB),
      cpu_requested: 10_000,
      cpu_limits: 10_000,
      memory_requested: Memory.to_bytes(32, :GB),
      memory_limits: Memory.to_bytes(32, :GB)
    },
    %{
      name: "huge",
      storage_size: Memory.to_bytes(1024, :GB),
      cpu_requested: 32_000,
      cpu_limits: 32_000,
      memory_requested: Memory.to_bytes(256, :GB),
      memory_limits: Memory.to_bytes(256, :GB)
    }
  ]

  @required_fields ~w(name image)a
  @read_only_fields ~w(name)a

  batt_schema "jupyter_lab_notebooks" do
    slug_field :name

    field :image, :string,
      default:
        :jupyter_datascience_lab
        |> CommonCore.Defaults.Images.get_image!()
        |> CommonCore.Defaults.Image.default_image()

    field :storage_size, :integer
    field :storage_class, :string
    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    field :node_type, Ecto.Enum, values: GPU.node_type_keys(), default: :default

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true

    embeds_many :env_values, EnvValue, on_replace: :delete

    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(jupyter_lab_notebook, attrs, opts \\ []) do
    jupyter_lab_notebook
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> maybe_set_virtual_size(@presets)
    |> validate_number(:cpu_requested, greater_than: 0, less_than: 100_000)
    |> validate_number(:cpu_limits, greater_than: 0, less_than: 100_000)
    |> validate_inclusion(:memory_requested, memory_options())
    |> validate_inclusion(:memory_limits, memory_options())
    |> foreign_key_constraint(:project_id)
    |> validate_required([:storage_size])
  end

  def cpu_options do
    [
      {"None", nil},
      {"0.05 cores", 50},
      {"0.1 cores", 100},
      {"0.2 cores", 200},
      {"0.5 cores", 500},
      {"1 core", 1000},
      {"2 cores", 2000},
      {"4 cores", 4000},
      {"8 cores", 8000},
      {"16 cores", 16_000},
      {"24 cores", 24_000},
      {"32 cores", 32_000}
    ]
  end

  def memory_options do
    [
      Memory.to_bytes(512, :MB),
      Memory.to_bytes(1, :GB),
      Memory.to_bytes(2, :GB),
      Memory.to_bytes(4, :GB),
      Memory.to_bytes(8, :GB),
      Memory.to_bytes(16, :GB),
      Memory.to_bytes(32, :GB),
      Memory.to_bytes(64, :GB),
      Memory.to_bytes(128, :GB),
      Memory.to_bytes(256, :GB),
      Memory.to_bytes(512, :GB),
      Memory.to_bytes(1024, :GB)
    ]
  end

  def preset_options_for_select do
    Enum.map(@presets, &{String.capitalize(&1.name), &1.name})
  end
end
