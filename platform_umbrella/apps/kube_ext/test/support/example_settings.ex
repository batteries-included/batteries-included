defmodule KubeExt.ExampleSettings do
  import KubeExt.MapSettings

  setting(:namespace, :namespace, "battery-core")
  setting(:string_key, "string_key", "key-value")
  def default_func, do: "computed"

  setting_fn(:test_image, :image, &default_func/0)
  setting_fn(:id, :id, &System.unique_integer/0)
end
