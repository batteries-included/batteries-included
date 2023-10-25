defmodule CommonCore.Batteries.VMAgentConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @required_fields ~w()a
  @optional_fields ~w(image_tag)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image_tag, :string, default: Defaults.Images.vm_tag()
  end

  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> validate_required(@required_fields)
  end
end
