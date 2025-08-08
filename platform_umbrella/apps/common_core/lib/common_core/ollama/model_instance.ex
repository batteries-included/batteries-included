defmodule CommonCore.Ollama.ModelInstance do
  @moduledoc false
  use CommonCore, {:schema, no_encode: [:project]}

  alias CommonCore.Defaults.GPU
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
      cpu_requested: 2000,
      memory_requested: Memory.to_bytes(8, :GB),
      memory_limits: Memory.to_bytes(8, :GB)
    },
    %{
      name: "large",
      cpu_requested: 4000,
      memory_requested: Memory.to_bytes(16, :GB),
      memory_limits: Memory.to_bytes(16, :GB)
    },
    %{
      name: "xlarge",
      cpu_requested: 8_000,
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

  @models %{
    "deepseek-r1:1.5b" => %{name: "Deepseek R1 1.5b", size: Memory.to_bytes(1.1, :GB)},
    "deepseek-r1:7b" => %{name: "Deepseek R1 7b", size: Memory.to_bytes(4.7, :GB)},
    "gpt-oss:20b" => %{name: "GPT-OSS 20b", size: Memory.to_bytes(14.0, :GB)},
    "gpt-oss:120b" => %{name: "GPT-OSS 120b", size: Memory.to_bytes(65.0, :GB)},
    "llama3.1:70b" => %{name: "Llama 3.1 70b", size: Memory.to_bytes(43.0, :GB)},
    "llama3.1:8b" => %{name: "Llama 3.1 8b", size: Memory.to_bytes(4.9, :GB)},
    "llama3.2:1b" => %{name: "Llama 3.2 1b", size: Memory.to_bytes(1.3, :GB)},
    "llama3.2:3b" => %{name: "Llama 3.2 3b", size: Memory.to_bytes(2.0, :GB)},
    "mxbai-embed-large" => %{name: "mxbai embed [Large] 335m", size: Memory.to_bytes(670, :MB)},
    "nomic-embed-text" => %{name: "Nomic embed-text 137m", size: Memory.to_bytes(274, :MB)},
    "phi4" => %{name: "Phi4 14b", size: Memory.to_bytes(9.1, :GB)},
    "snowflake-arctic-embed2" => %{name: "Snowflake Arctic Embed 2.0 568m", size: Memory.to_bytes(1.2, :GB)}
  }

  @gpu_node_types GPU.node_types_with_gpus()

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name, :memory_limits, :gpu_count]
  }

  batt_schema "model_instances" do
    slug_field :name

    field :model, :string, default: "llama3.2:1b"
    field :num_instances, :integer, default: 1

    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    field :gpu_count, :integer, default: 0
    field :node_type, Ecto.Enum, values: GPU.node_type_keys(), default: :default

    field :virtual_size, :string, virtual: true

    belongs_to :project, CommonCore.Projects.Project

    timestamps()
  end

  def changeset(model_instance, attrs, opts \\ []) do
    model_instance
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> maybe_set_virtual_size(@presets)
    |> validate_inclusion(:model, Map.keys(@models))
    |> validate_number(:cpu_requested, greater_than: 0, less_than: 100_000)
    |> validate_number(:cpu_limits, greater_than: 0, less_than: 100_000)
    |> validate_number(:memory_requested, greater_than: 0, less_than: Memory.to_bytes(1_000, :TB))
    |> validate_number(:memory_limits, greater_than: 0, less_than: Memory.to_bytes(1_000, :TB))
    |> validate_gpu_count()
    |> validate_node_type()
    |> foreign_key_constraint(:project_id)
  end

  defp validate_gpu_count(changeset) do
    validate_change(changeset, :gpu_count, fn :gpu_count, gpu_count ->
      do_validate_gpu_count(get_field(changeset, :node_type, :default), gpu_count)
    end)
  end

  defp do_validate_gpu_count(type, count) when type in @gpu_node_types do
    if count > 0, do: [], else: [gpu_count: "must be greater than 0 when requesting a node type with GPU(s)"]
  end

  defp do_validate_gpu_count(_type, count) do
    if count > 0, do: [gpu_count: "must be 0 when requesting a node type without GPU(s)"], else: []
  end

  defp validate_node_type(changeset) do
    validate_change(changeset, :node_type, fn :node_type, node_type ->
      do_validate_node_type(node_type, get_field(changeset, :gpu_count, 0))
    end)
  end

  defp do_validate_node_type(type, count) when type in @gpu_node_types do
    if count > 0, do: [], else: [node_type: "must not be a GPU type if GPU count is 0"]
  end

  defp do_validate_node_type(_type, count) do
    if count > 0, do: [node_type: "must be a GPU type if GPU count is greater than 0"], else: []
  end

  def preset_options_for_select(model_name) do
    size = model_size(model_name)

    Enum.map(@presets, &[key: String.capitalize(&1.name), value: &1.name, disabled: &1.memory_requested < size])
  end

  def model_options_for_select do
    # the key in the @model registry is what should/would be stored in the db
    # the key for the form is what the user chooses
    Enum.map(@models, fn {key, %{name: name, size: size}} ->
      [key: "#{name} (#{Memory.humanize(size, false)})", value: key]
    end)
  end

  def model_size(model_name), do: @models |> Map.get(model_name, %{}) |> Map.get(:size, 0)

  @doc """
  Find the smallest preset that requests more memory than `size`.
  """
  def get_preset_for_size(size) do
    @presets
    |> Enum.sort(&(&1.memory_requested < &2.memory_requested))
    |> Enum.find(fn %{memory_requested: memory_requested} -> memory_requested >= size end)
  end

  def presets, do: @presets
end
