defmodule CommonCore.TraditionalServices.Volume do
  @moduledoc false
  use CommonCore, :embedded_schema

  @required_fields ~w(name type)a
  @config_types ~w[config_map empty_dir secret]a
  @allowed_mediums [
    default: "Default",
    memory: "Memory"
  ]

  batt_embedded_schema do
    field :name, :string
    field :type, Ecto.Enum, values: @config_types, default: :empty_dir

    # cm or secret config
    field :default_mode, :string
    field :source_name, :string
    field :optional, :boolean, default: false

    # empty dir config
    field :medium, Ecto.Enum, values: Keyword.keys(@allowed_mediums), default: :default
    field :size_limit, :string
  end

  def changeset(struct, params \\ %{}, opts \\ []) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(params, opts)
    |> validate_inclusion(:type, @config_types)
    |> validate_length(:name, min: 3, max: 256)
  end

  @spec to_k8s_volume(t()) :: map()
  def to_k8s_volume(%__MODULE__{type: :config_map} = mount) do
    %{
      "name" => mount.name,
      "configMap" => %{
        "defaultMode" => mount.default_mode,
        "name" => mount.source_name,
        "optional" => mount.optional
      }
    }
  end

  def to_k8s_volume(%__MODULE__{type: :empty_dir} = mount) do
    medium = if mount.medium == :default, do: "", else: mount.medium
    %{"name" => mount.name, "emptyDir" => %{"medium" => medium, "sizeLimit" => mount.size_limit}}
  end

  def to_k8s_volume(%__MODULE__{type: :secret} = mount) do
    %{
      "name" => mount.name,
      "secret" => %{
        "defaultMode" => mount.default_mode,
        "secretName" => mount.source_name,
        "optional" => mount.optional
      }
    }
  end

  def medium_options, do: Enum.map(@allowed_mediums, fn {k, v} -> {v, k} end)
end
