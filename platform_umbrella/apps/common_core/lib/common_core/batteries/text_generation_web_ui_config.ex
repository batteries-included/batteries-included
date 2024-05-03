defmodule CommonCore.Batteries.TextGenerationWebUIConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :text_generation_webui
  use CommonCore.Util.DefaultableField

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers

  alias CommonCore.Defaults

  @required_fields ~w()a

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.text_generation_webui_image()
    field :cookie_secret, :string
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> validate_required(@required_fields)
    |> validate_cookie_secret()
    |> apply_changeset_if_valid()
  end
end
