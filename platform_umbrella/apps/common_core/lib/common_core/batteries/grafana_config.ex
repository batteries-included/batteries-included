defmodule CommonCore.Batteries.GrafanaConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :grafana
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.grafana_image()
    defaultable_field :sidecar_image, :string, default: Defaults.Images.kiwigrid_sidecar_image()
    type_field()
  end
end
