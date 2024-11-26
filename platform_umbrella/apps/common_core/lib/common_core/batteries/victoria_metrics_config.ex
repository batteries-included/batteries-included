defmodule CommonCore.Batteries.VictoriaMetricsConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults
  alias CommonCore.Ecto.Schema
  alias CommonCore.Resources.Quantity

  @read_only_fields ~w(cookie_secret)a

  batt_polymorphic_schema type: :victoria_metrics do
    defaultable_field :cluster_image_tag, :string, default: Defaults.Images.vm_cluster_tag()
    defaultable_image_field :operator_image, image_id: :vm_operator

    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1

    field :replication_factor, :integer, default: 1

    field :vminsert_replicas, :integer, default: 1
    field :vmselect_replicas, :integer, default: 1
    field :vmstorage_replicas, :integer, default: 1

    field :vmselect_volume_size, :integer, default: "1Gi" |> Quantity.parse_quantity() |> trunc()
    field :vmstorage_volume_size, :integer, default: "5Gi" |> Quantity.parse_quantity() |> trunc()
  end

  def changeset(base_struct, args, opts \\ []) do
    base_struct
    |> Schema.schema_changeset(args, opts)
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:vmstorage_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vminsert_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vmselect_replicas, greater_than: 0, less_than: 99)
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
end
