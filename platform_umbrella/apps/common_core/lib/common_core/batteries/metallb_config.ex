defmodule CommonCore.Batteries.MetalLBConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :metallb do
    defaultable_image_field :speaker_image, image_id: :metallb_speaker
    defaultable_image_field :controller_image, image_id: :metallb_controller
    defaultable_image_field :frrouting_image, image_id: :frrouting_frr

    field :enable_pod_monitor, :boolean, default: false
  end
end
