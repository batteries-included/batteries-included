defmodule CommonCore.Resources.IstioTest do
  use ExUnit.Case

  alias CommonCore.Resources.IstioConfig

  test "Correctly creates a rewrite virtual service." do
    vc = IstioConfig.VirtualService.rewriting("/x/prefix", "main-host")
    matches = vc |> Map.get(:http) |> hd |> Map.get(:match)
    rewrite = vc |> Map.get(:http) |> hd |> Map.get(:rewrite)

    assert map_size(vc) > 2
    assert length(matches) == 2
    assert rewrite.uri == "/"
  end
end
