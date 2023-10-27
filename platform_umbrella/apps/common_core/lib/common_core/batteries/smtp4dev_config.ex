defmodule CommonCore.Batteries.Smtp4devConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

  @required_fields ~w()a
  @optional_fields ~w(image)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.smtp4dev_image()
    field :cookie_secret, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, Enum.concat(@required_fields, @optional_fields))
    |> validate_required(@required_fields)
    |> RandomKeyChangeset.maybe_set_random(:cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1)
  end
end
