defmodule CommonCore.Batteries.VMAgentConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :vm_agent
  use CommonCore.Util.DefaultableField

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers

  alias CommonCore.Defaults

  @required_fields ~w()a

  typed_embedded_schema do
    defaultable_field :image_tag, :string, default: Defaults.Images.vm_tag()
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
