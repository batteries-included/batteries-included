defmodule CommonCore.Batteries.VMClusterConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :vm_cluster
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers
  import Ecto.Changeset, only: [validate_number: 3, validate_required: 2]

  alias CommonCore.Defaults

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :cluster_image_tag, :string, default: Defaults.Images.vm_cluster_tag()
    field :cookie_secret, :string

    defaultable_field :replication_factor, :integer, default: 1

    defaultable_field :vminsert_replicas, :integer, default: 1
    defaultable_field :vmselect_replicas, :integer, default: 1
    defaultable_field :vmstorage_replicas, :integer, default: 1

    defaultable_field :vmselect_volume_size, :string, default: "1Gi"
    defaultable_field :vmstorage_volume_size, :string, default: "5Gi"
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> validate_required(@required_fields)
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:vmstorage_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vminsert_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vmselect_replicas, greater_than: 0, less_than: 99)
    |> validate_cookie_secret()
    |> apply_changeset_if_valid()
  end
end
