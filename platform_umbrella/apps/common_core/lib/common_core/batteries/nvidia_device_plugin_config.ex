defmodule CommonCore.Batteries.NvidiaDevicePluginConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @required_fields ~w()a

  batt_polymorphic_schema type: :nvidia_device_plugin do
    defaultable_image_field :image, image_id: :nvidia_device_plugin
  end
end
