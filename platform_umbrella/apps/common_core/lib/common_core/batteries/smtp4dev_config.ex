defmodule CommonCore.Batteries.Smtp4devConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :smtp4dev
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
    defaultable_field :image, :string, default: Defaults.Images.smtp4dev_image()
    field :cookie_secret, :string
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> validate_cookie_secret()
    |> validate_required(@required_fields)
    |> apply_changeset_if_valid()
  end
end
