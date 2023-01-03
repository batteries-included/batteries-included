defmodule CommonCore.ExampleSettings do
  import CommonCore.MapSettings

  setting(:namespace, :namespace, "battery-core")
  setting(:string_key, "string_key", "key-value")

  def computation_func, do: "computed"

  setting(:test_image, :image) do
    computation_func()
  end

  setting(:id, :id) do
    System.unique_integer()
  end
end
