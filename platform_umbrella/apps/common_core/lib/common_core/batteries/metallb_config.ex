defmodule CommonCore.Batteries.MetalLBConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :metallb
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :speaker_image, :string, default: Defaults.Images.metallb_speaker_image()
    defaultable_field :controller_image, :string, default: Defaults.Images.metallb_controller_image()
    defaultable_field :frrouting_image, :string, default: Defaults.Images.frrouting_frr_image()
    type_field()
  end
end
