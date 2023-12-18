defmodule CommonCore.Batteries.NotebooksConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :notebooks
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers
  import Ecto.Changeset, only: [validate_required: 2]

  alias CommonCore.Defaults

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :cookie_secret, :string
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> maybe_set_random(:cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1)
    |> validate_required(@required_fields)
    |> apply_changeset_if_valid()
  end
end
