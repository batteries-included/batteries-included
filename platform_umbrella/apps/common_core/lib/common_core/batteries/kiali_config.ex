defmodule CommonCore.Batteries.KialiConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :kiali
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.kiali_image()
    defaultable_field :version, :string, default: Defaults.Monitoring.kiali_version()
    type_field()
  end
end
