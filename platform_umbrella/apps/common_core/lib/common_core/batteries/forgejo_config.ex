defmodule CommonCore.Batteries.ForgejoConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :forgejo
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers
  import Ecto.Changeset, only: [validate_required: 2]

  alias CommonCore.Defaults

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.forgejo_image()
    defaultable_field :admin_username, :string, default: "battery-forgejo-admin"
    field :admin_password, :string
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> validate_required(@required_fields)
    |> maybe_set_random(:admin_password)
    |> apply_changeset_if_valid()
  end
end
