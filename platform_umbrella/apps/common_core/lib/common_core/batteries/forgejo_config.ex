defmodule CommonCore.Batteries.ForgejoConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :forgejo
  use CommonCore.Util.DefaultableField

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers

  alias CommonCore.Defaults

  @required_fields ~w()a

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
