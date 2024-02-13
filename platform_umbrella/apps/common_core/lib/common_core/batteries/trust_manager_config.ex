defmodule CommonCore.Batteries.TrustManagerConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :trust_manager
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.trust_manager_image()
    defaultable_field :init_image, :string, default: Defaults.Images.trust_manager_init_image()

    type_field()
  end
end
