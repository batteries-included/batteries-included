defmodule CommonCore.Batteries.VMClusterConfig do
  @moduledoc false
  use CommonCore, {:embedded_schema, no_encode: [:cookie_secret]}

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :vm_cluster do
    defaultable_field :cluster_image_tag, :string, default: Defaults.Images.vm_cluster_tag()
    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1

    defaultable_field :replication_factor, :integer, default: 1

    defaultable_field :vminsert_replicas, :integer, default: 1
    defaultable_field :vmselect_replicas, :integer, default: 1
    defaultable_field :vmstorage_replicas, :integer, default: 1

    defaultable_field :vmselect_volume_size, :string, default: "1Gi"
    defaultable_field :vmstorage_volume_size, :string, default: "5Gi"
  end

  def changeset(base_struct, args) do
    base_struct
    |> CommonCore.Ecto.Schema.schema_changeset(args)
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:vmstorage_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vminsert_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vmselect_replicas, greater_than: 0, less_than: 99)
  end
end
