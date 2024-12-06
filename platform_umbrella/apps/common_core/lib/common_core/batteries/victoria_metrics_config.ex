defmodule CommonCore.Batteries.VictoriaMetricsConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults
  alias CommonCore.Ecto.Schema
  alias CommonCore.Resources.Quantity
  alias CommonCore.Util.Memory

  @read_only_fields ~w(cookie_secret)a
  @range_ticks [
    {"500MB", 0},
    {"1GB", 0.1},
    {"50GB", 0.2},
    {"250GB", 0.4},
    {"500GB", 0.6},
    {"1TB", 0.8},
    {"2TB", 1}
  ]

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

    field :vmselect_volume_size, :integer,
      default: Enum.find_value(@presets, fn %{name: name, vmselect_volume_size: size} -> if name == "tiny", do: size end)

    field :vmstorage_volume_size, :integer,
      default: Enum.find_value(@presets, fn %{name: name, vmstorage_volume_size: size} -> if name == "tiny", do: size end)

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true

    field :virtual_vmselect_volume_size_range, :integer, virtual: true
    field :virtual_vmstorage_volume_size_range, :integer, virtual: true
  end

  def changeset(base_struct, args, opts \\ []) do
    base_struct
    |> Schema.schema_changeset(args, opts)
    |> maybe_set_virtual_size(@presets)
    |> put_range_value_from_size(:vmselect_volume_size)
    |> put_range_value_from_size(:vmstorage_volume_size)
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:vmstorage_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vminsert_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vmselect_replicas, greater_than: 0, less_than: 99)
    |> validate_required([:vmselect_volume_size, :vmstorage_volume_size])
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

  def volume_range_ticks, do: @range_ticks

  def put_volume_size(changeset, field, range_value, existing_size) do
    changeset
    |> put_volume_size_from_range_value(field, range_value)
    |> validate_number(field, greater_than_or_equal_to: existing_size)
  end

  defp put_volume_size_from_range_value(changeset, field, range_value) when is_binary(range_value) do
    case Float.parse(range_value) do
      {bytes, _} -> put_volume_size_from_range_value(changeset, field, round(bytes))
      :error -> add_error(changeset, virtual_field_for_field(field), "can't parse value")
    end
  end

  defp put_volume_size_from_range_value(changeset, field, range_value) do
    volume_size = Memory.range_value_to_bytes(range_value, @range_ticks)

    changeset
    |> put_change(field, volume_size)
    |> put_change(virtual_field_for_field(field), range_value)
  end

  defp put_range_value_from_size(changeset, field) do
    range_value =
      if volume_size = get_field(changeset, field) do
        Memory.bytes_to_range_value(volume_size, @range_ticks)
      else
        0
      end

    put_change(changeset, virtual_field_for_field(field), range_value)
  end

  defp virtual_field_for_field(field), do: String.to_existing_atom("virtual_#{field}_range")
end
