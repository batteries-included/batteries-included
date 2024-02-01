defmodule ControlServerWeb.Integration.PostgresTest do
  use ControlServerWeb.IntegrationTestCase

  @base_cluster_name "int-test"

  feature "Can start a postgres cluster", %{session: session} do
    cluster_name = cluster_name()

    session
    |> visit("/postgres/new")
    |> assert_text("New Postgres Cluster")
    |> fill_in(text_field("cluster[name]"), with: cluster_name)
    |> click(button("Save"))
    # Make sure that the postres cluster show page title is there
    |> assert_text("Postgres Cluster")
    # Make sure that this page has the kubenetes elements
    |> assert_text("Pods")
    # Assert that we are on the correct cluster show page
    |> assert_text(cluster_name)

    # Assert that we have gotten to the show page
    path = current_path(session)
    assert path =~ ~r/\/postgres\/[\d\w-]+\/show$/
  end

  defp cluster_name, do: "#{@base_cluster_name}-#{:rand.uniform(10_000)}"
end
