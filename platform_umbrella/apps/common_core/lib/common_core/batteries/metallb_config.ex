defmodule CommonCore.Batteries.MetalLBConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :metallb do
    defaultable_field :speaker_image, :string, default: Defaults.Images.metallb_speaker_image()
    defaultable_field :controller_image, :string, default: Defaults.Images.metallb_controller_image()
    defaultable_field :frrouting_image, :string, default: Defaults.Images.frrouting_frr_image()
  end
end
