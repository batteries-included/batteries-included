defmodule CommonCore.Notebooks.JupyterLabNotebook do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project]}

  import CommonCore.Util.EctoValidations

  alias CommonCore.Projects.Project
  alias CommonCore.Util.Memory

  @presets [
    %{
      name: "tiny",
      storage_size: Memory.mb_to_bytes(512),
      cpu_requested: 500,
      cpu_limits: 500,
      memory_requested: Memory.mb_to_bytes(512),
      memory_limits: Memory.mb_to_bytes(512)
    },
    %{
      name: "small",
      storage_size: Memory.gb_to_bytes(16),
      cpu_requested: 500,
      cpu_limits: 2000,
      memory_requested: Memory.gb_to_bytes(1),
      memory_limits: Memory.gb_to_bytes(4)
    },
    %{
      name: "medium",
      storage_size: Memory.gb_to_bytes(64),
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.gb_to_bytes(8),
      memory_limits: Memory.gb_to_bytes(8)
    },
    %{
      name: "large",
      storage_size: Memory.gb_to_bytes(128),
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.gb_to_bytes(16),
      memory_limits: Memory.gb_to_bytes(16)
    },
    %{
      name: "xlarge",
      storage_size: Memory.gb_to_bytes(256),
      cpu_requested: 10_000,
      cpu_limits: 10_000,
      memory_requested: Memory.gb_to_bytes(32),
      memory_limits: Memory.gb_to_bytes(32)
    },
    %{
      name: "huge",
      storage_size: Memory.gb_to_bytes(1024),
      cpu_requested: 32_000,
      cpu_limits: 32_000,
      memory_requested: Memory.gb_to_bytes(256),
      memory_limits: Memory.gb_to_bytes(256)
    }
  ]

  typed_schema "jupyter_lab_notebooks" do
    field :name, :string
    field :image, :string, default: "jupyter/datascience-notebook:lab-4.0.7"
    field :storage_size, :integer
    field :storage_class, :string
    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true

    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(jupyter_lab_notebook, attrs) do
    jupyter_lab_notebook
    |> cast(attrs, [
      :name,
      :image,
      :storage_size,
      :storage_class,
      :cpu_requested,
      :cpu_limits,
      :memory_requested,
      :memory_limits,
      :virtual_size,
      :project_id
    ])
    |> maybe_fill_in_slug(:name)
    |> downcase_fields([:name])
    |> maybe_set_virtual_size(@presets)
    |> validate_dns_label(:name)
    |> validate_required([:name, :image, :storage_size])
    |> validate_number(:cpu_requested, greater_than: 0, less_than: 100_000)
    |> validate_number(:cpu_limits, greater_than: 0, less_than: 100_000)
    |> validate_inclusion(:memory_requested, memory_options())
    |> validate_inclusion(:memory_limits, memory_options())
    |> foreign_key_constraint(:project_id)
  end

  def cpu_select_options,
    do: [
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

  def memory_options,
    do: [
      Memory.mb_to_bytes(512),
      Memory.gb_to_bytes(1),
      Memory.gb_to_bytes(2),
      Memory.gb_to_bytes(4),
      Memory.gb_to_bytes(8),
      Memory.gb_to_bytes(16),
      Memory.gb_to_bytes(32),
      Memory.gb_to_bytes(64),
      Memory.gb_to_bytes(128),
      Memory.gb_to_bytes(256),
      Memory.gb_to_bytes(512),
      Memory.gb_to_bytes(1024)
    ]

  def preset_options_for_select do
    Enum.map(@presets, &{String.capitalize(&1.name), &1.name})
  end
end
