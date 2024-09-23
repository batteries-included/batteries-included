defmodule CommonCore.TraditionalServices.Volume do
  @moduledoc false
  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.PolymorphicType
  alias CommonCore.TraditionalServices.ConfigMapConfig
  alias CommonCore.TraditionalServices.EmptyDirConfig
  alias CommonCore.TraditionalServices.SecretConfig

  @required_fields ~w(name type)a
  @config_types [
    config_map: ConfigMapConfig,
    empty_dir: EmptyDirConfig,
    secret: SecretConfig
  ]

  batt_embedded_schema do
    field :name, :string
    field :type, Ecto.Enum, values: Keyword.keys(@config_types), default: :empty_dir

    field :config, PolymorphicType, mappings: @config_types
  end

  def changeset(struct, params \\ %{}, opts \\ []) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(params, opts)
    |> validate_length(:name, min: 3, max: 256)
  end

  @spec to_k8s_volume(t()) :: map()
  def to_k8s_volume(%__MODULE__{type: :config_map, config: config} = mount) do
    %{
      "name" => mount.name,
      "configMap" => %{
        "defaultMode" => config.default_mode,
        "name" => config.name,
        "optional" => config.optional
      }
    }
  end

  def to_k8s_volume(%__MODULE__{type: :empty_dir, config: config} = mount) do
    medium = if config.medium == :default, do: "", else: config.medium
    %{"name" => mount.name, "emptyDir" => %{"medium" => medium, "sizeLimit" => config.size_limit}}
  end

  def to_k8s_volume(%__MODULE__{type: :secret, config: config} = mount) do
    %{
      "name" => mount.name,
      "secret" => %{
        "defaultMode" => config.default_mode,
        "secretName" => config.name,
        "optional" => config.optional
      }
    }
  end
end
