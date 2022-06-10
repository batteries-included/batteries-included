defmodule ControlServerWeb.Integration.PostgrestTest do
  use ControlServerWeb.IntegrationTestCase

  @new_cluster_text "New Cluster"
  @base_cluster_name "int-test"

  feature "Can start a postgres cluster", %{session: session} do
    EventCenter.KubeState.subscribe(:postgresql)

    cluster_name = cluster_name()

    session
    |> visit("/services/data/postgres_clusters")
    |> refute_has(css("tr td"))
    |> click(link(@new_cluster_text))
    |> fill_in(text_field("cluster[name]"), with: cluster_name)
    |> fill_in(text_field("cluster[storage_size]"), with: "100M")
    |> click(button("Save"))
    |> assert_has(css("tr td", count: nil, minimum: 4))
    |> assert_text(cluster_name)

    assert_receive _, 240_000
  end

  defp cluster_name, do: "#{@base_cluster_name}-#{:rand.uniform(10000)}"
end
