defmodule Server.Configs.AdoptionTest do
  use Server.DataCase

  import Server.Factory
  alias Server.Configs
  alias Server.Configs.Adoption
  alias Server.Configs.Defaults
  alias Server.Configs.RawConfig

  test "test adopt raw config" do
    kube_cluster = insert(:kube_cluster)
    assert {:ok, %RawConfig{} = adopt_config} = Defaults.create_adoption(kube_cluster.id)
    id = adopt_config.id
    Adoption.adopt(adopt_config)

    assert %RawConfig{content: %{"is_adopted" => true}, id: ^id} =
             Configs.get_raw_config!(adopt_config.id)
  end
end
