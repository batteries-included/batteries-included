defmodule CommonCore.Containers.EnvValue do
  @moduledoc false

  use CommonCore, :embedded_schema

  @required_fields ~w(name source_type)a

  batt_embedded_schema do
    field :name, :string

    field :source_type, Ecto.Enum, values: [:value, :config, :secret], default: :value
    field :value, :string
    field :source_name, :string
    field :source_key, :string
    field :source_optional, :boolean, default: false
  end

  def changeset(struct, params \\ %{}, opts \\ []) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(params, opts)
    |> validate_length(:name, min: 3, max: 256)
  end

  @spec to_k8s_value(t()) :: map()
  def to_k8s_value(%__MODULE__{source_type: :value} = val) do
    %{"name" => val.name, "value" => val.value}
  end

  def to_k8s_value(%__MODULE__{source_type: :config} = val) do
    %{
      "name" => val.name,
      "valueFrom" => %{
        "configMapKeyRef" => %{
          "key" => val.source_key,
          "name" => val.source_name,
          "optional" => val.source_optional
        }
      }
    }
  end

  def to_k8s_value(%__MODULE__{source_type: :secret} = val) do
    %{
      "name" => val.name,
      "valueFrom" => %{
        "secretKeyRef" => %{
          "key" => val.source_key,
          "name" => val.source_name,
          "optional" => val.source_optional
        }
      }
    }
  end
end
