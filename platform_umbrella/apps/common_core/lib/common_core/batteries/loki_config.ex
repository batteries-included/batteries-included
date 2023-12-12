defmodule CommonCore.Batteries.LokiConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :loki
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  import CommonCore.Util.PolymorphicTypeHelpers
  import Ecto.Changeset, only: [validate_number: 3, validate_required: 2]

  alias CommonCore.Defaults

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.loki_image()
    defaultable_field :replication_factor, :integer, default: 1
    defaultable_field :replicas, :integer, default: 1
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> validate_required(@required_fields)
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:replicas, greater_than: 0, less_than: 99)
    |> apply_changeset_if_valid()
  end
end
