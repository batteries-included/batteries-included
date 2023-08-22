defmodule CommonCore.Batteries.CloudnativePGConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @required_fields ~w()a
  @optional_fields ~w(image)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.cloudnative_pg_image()
  end

  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> validate_required(@required_fields)
  end
end
