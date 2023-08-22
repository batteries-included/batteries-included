defmodule CommonCore.Batteries.VictoriaMetricsConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @required_fields ~w()a
  @optional_fields ~w(
    replication_factor

    cluster_image_tag
    image_tag

    vminsert_replicas vmselect_replicas vmstorage_replicas
    vmselect_volume_size vmstorage_volume_size)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :replication_factor, :integer, default: 1
    field :cluster_image_tag, :string, default: Defaults.Images.vm_cluster_tag()
    field :vm_operator_image, :string, default: Defaults.Images.vm_operator_image()
    field :image_tag, :string, default: Defaults.Images.vm_tag()

    field :vminsert_replicas, :integer, default: 1
    field :vmselect_replicas, :integer, default: 1
    field :vmstorage_replicas, :integer, default: 1

    field :vmselect_volume_size, :string, default: "1Gi"
    field :vmstorage_volume_size, :string, default: "5Gi"
  end

  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> validate_required(@required_fields)
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:vmstorage_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vminsert_replicas, greater_than: 0, less_than: 99)
    |> validate_number(:vmselect_replicas, greater_than: 0, less_than: 99)
  end
end
