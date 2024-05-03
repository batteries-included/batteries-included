defmodule CommonCore.Batteries.TrustManagerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :trust_manager
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.trust_manager_image()
    defaultable_field :init_image, :string, default: Defaults.Images.trust_manager_init_image()

    type_field()
  end
end
