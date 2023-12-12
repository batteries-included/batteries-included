defmodule CommonCore.Batteries.Smtp4devConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :smtp4dev
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  import CommonCore.Util.PolymorphicTypeHelpers
  import Ecto.Changeset, only: [validate_required: 2]

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

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
    |> RandomKeyChangeset.maybe_set_random(:cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1)
    |> validate_required(@required_fields)
    |> apply_changeset_if_valid()
  end
end
