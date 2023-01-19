defmodule CommonCore.Batteries.MailhogConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @required_fields ~w()a
  @optional_fields ~w(image)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.mailhog_image()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, Enum.concat(@required_fields, @optional_fields))
    |> validate_required(@required_fields)
  end
end
