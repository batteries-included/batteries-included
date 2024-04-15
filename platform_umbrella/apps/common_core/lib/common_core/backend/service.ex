defmodule CommonCore.Backend.Service do
  @moduledoc false
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import Ecto.Changeset

  alias CommonCore.Util.Memory

  @service_size_preset [
    %{
      name: "tiny",
      cpu_requested: 500,
      cpu_limits: 500,
      memory_requested: Memory.mb_to_bytes(512),
      memory_limits: Memory.mb_to_bytes(512)
    },
    %{
      name: "small",
      cpu_requested: 500,
      cpu_limits: 2000,
      memory_requested: Memory.gb_to_bytes(1),
      memory_limits: Memory.gb_to_bytes(4)
    },
    %{
      name: "medium",
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.gb_to_bytes(8),
      memory_limits: Memory.gb_to_bytes(8)
    },
    %{
      name: "large",
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.gb_to_bytes(16),
      memory_limits: Memory.gb_to_bytes(16)
    },
    %{
      name: "xlarge",
      cpu_requested: 10_000,
      cpu_limits: 10_000,
      memory_requested: Memory.gb_to_bytes(32),
      memory_limits: Memory.gb_to_bytes(32)
    },
    %{
      name: "huge",
      cpu_requested: 32_000,
      cpu_limits: 32_000,
      memory_requested: Memory.gb_to_bytes(256),
      memory_limits: Memory.gb_to_bytes(256)
    }
  ]

  @required_fields ~w(name)a
  @optional_fields ~w(kube_deployment_type num_instances virtual_size)a
  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "backend_services" do
    field :name, :string

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

    timestamps()
  end

  @doc false
  def changeset(service, attrs) do
    service
    |> cast(attrs, Enum.concat(@required_fields, @optional_fields))
    |> maybe_fill_in_slug(:name)
    |> maybe_set_virtual_size(@service_size_preset)
    |> downcase_fields([:name])
    |> cast_embed(:containers)
    |> cast_embed(:init_containers)
    |> cast_embed(:env_values)
    |> unique_constraint(:name)
    |> validate_dns_label(:name)
    |> validate_required(@required_fields)
  end

  def preset_options_for_select,
    do: Enum.map(@service_size_preset, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]
end
