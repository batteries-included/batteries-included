defmodule CommonCore.Batteries.GiteaConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :gitea
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
    defaultable_field :image, :string, default: Defaults.Images.gitea_image()
    defaultable_field :admin_username, :string, default: "battery-gitea-admin"
    field :admin_password, :string
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> validate_required(@required_fields)
    |> RandomKeyChangeset.maybe_set_random(:admin_password)
    |> apply_changeset_if_valid()
  end
end
