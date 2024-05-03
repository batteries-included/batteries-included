defmodule CommonCore.Batteries.KialiConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :kiali
  use CommonCore.Util.DefaultableField

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers

  alias CommonCore.Defaults

  @required_fields ~w()a

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.kiali_image()
    defaultable_field :version, :string, default: Defaults.Monitoring.kiali_version()

    field :login_signing_key, :string
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> validate_required(@required_fields)
    |> maybe_set_random(:login_signing_key, length: 32)
    |> apply_changeset_if_valid()
  end
end
