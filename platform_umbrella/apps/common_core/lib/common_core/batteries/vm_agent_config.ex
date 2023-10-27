defmodule CommonCore.Batteries.VMAgentConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

  @required_fields ~w()a
  @optional_fields ~w(image_tag)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image_tag, :string, default: Defaults.Images.vm_tag()
    field :cookie_secret, :string
  end

  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> validate_required(@required_fields)
    |> RandomKeyChangeset.maybe_set_random(:cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1)
  end
end
