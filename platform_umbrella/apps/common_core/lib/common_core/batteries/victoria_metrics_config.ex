defmodule CommonCore.Batteries.VictoriaMetricsConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults
  alias CommonCore.Ecto.Schema
  alias CommonCore.Resources.Quantity
  alias CommonCore.Util.Memory

  @read_only_fields ~w(cookie_secret)a

  @presets [
    %{
      name: "tiny",
      vmselect_volume_size: Memory.to_bytes(512, :MB),
      vmstorage_volume_size: Memory.to_bytes(1, :GB)
    },
    %{
      name: "small",
      vmselect_volume_size: Memory.to_bytes(5, :GB),
      vmstorage_volume_size: Memory.to_bytes(10, :GB)
    },
    %{
      name: "medium",
      vmselect_volume_size: Memory.to_bytes(10, :GB),
      vmstorage_volume_size: Memory.to_bytes(50, :GB)
    },
    %{
      name: "large",
      vmselect_volume_size: Memory.to_bytes(100, :GB),
      vmstorage_volume_size: Memory.to_bytes(200, :GB)
    },
    %{
      name: "xlarge",
      vmselect_volume_size: Memory.to_bytes(250, :GB),
      vmstorage_volume_size: Memory.to_bytes(500, :GB)
    },
    %{
      name: "huge",
      vmselect_volume_size: Memory.to_bytes(1, :TB),
      vmstorage_volume_size: Memory.to_bytes(2, :TB)
    }
  ]

  batt_polymorphic_schema type: :victoria_metrics do
    defaultable_field :cluster_image_tag, :string, default: Defaults.Images.vm_cluster_tag()
    defaultable_image_field :operator_image, image_id: :vm_operator

    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1

    field :replication_factor, :integer, default: 1

    field :vminsert_replicas, :integer, default: 1
    field :vmselect_replicas, :integer, default: 1
    field :vmstorage_replicas, :integer, default: 1

    field :vmselect_volume_size, :integer
    field :vmstorage_volume_size, :integer

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true
  end

  def changeset(base_struct, args, opts \\ []) do
    base_struct
    |> Schema.schema_changeset(args, opts)
    |> maybe_set_virtual_size(@presets)
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:vmstorage_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vminsert_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vmselect_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vmselect_volume_size, greater_than_or_equal_to: base_struct.vmselect_volume_size || 0)
    |> validate_number(:vmstorage_volume_size, greater_than_or_equal_to: base_struct.vmstorage_volume_size || 0)
  end

  def load(%{"vmselect_volume_size" => size} = data) when is_binary(size),
    do: convert_str_to_int(data, "vmselect_volume_size", size)

  def load(%{"vmstorage_volume_size" => size} = data) when is_binary(size),
    do: convert_str_to_int(data, "vmstorage_volume_size", size)

  def load(data), do: Schema.schema_load(__MODULE__, data)

  defp convert_str_to_int(data, field, size) do
    size
    |> Quantity.parse_quantity()
    |> trunc()
    |> then(&Map.put(data, field, &1))
    |> load()
  end

  def preset_options_for_select do
    Enum.map(@presets, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]
  end
end
