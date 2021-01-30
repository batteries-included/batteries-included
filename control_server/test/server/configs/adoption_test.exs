defmodule Server.Configs.AdoptionTest do
  use Server.DataCase

  import Server.Factory
  alias Server.Configs
  alias Server.Configs.Adoption
  alias Server.Configs.RawConfig

  test "create_adoption" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id

    {:ok, %RawConfig{} = raw_config} = Adoption.create_for_cluster(cluster.id)
    assert raw_config.content == %{is_adopted: false}
    assert raw_config.path == "/adoption"
    assert raw_config.kube_cluster_id == cluster_id
  end

  test "test adopt raw config" do
    kube_cluster = insert(:kube_cluster)
    assert {:ok, %RawConfig{} = adopt_config} = Adoption.create_for_cluster(kube_cluster.id)
    id = adopt_config.id
    Adoption.adopt(adopt_config)

    assert %RawConfig{content: %{"is_adopted" => true}, id: ^id} =
             Configs.get_raw_config!(adopt_config.id)
  end
end
