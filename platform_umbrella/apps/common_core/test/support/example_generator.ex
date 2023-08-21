defmodule CommonCore.Resources.ExampleGenerator do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "example-app"

  alias CommonCore.Resources.Builder, as: B

  resource(:main) do
    name = "main"

    :service_account
    |> B.build_resource()
    |> B.name(name)
  end

  multi_resource(:multi_list) do
    Enum.map(0..10, fn idx ->
      name = "multi-list-#{idx}"

      :service_account
      |> B.build_resource()
      |> B.name(name)
    end)
  end

  multi_resource(:multi_map) do
    0..2
    |> Enum.map(fn idx ->
      name = "map-#{idx}"

      {"/map_#{idx}",
       :service_account
       |> B.build_resource()
       |> B.name(name)}
    end)
    |> Map.new()
  end
end
