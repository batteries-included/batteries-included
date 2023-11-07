defmodule ControlServerWeb.PostgresLiveTest do
  use Heyya.LiveTest
  use ControlServerWeb.ConnCase

  alias CommonCore.Postgres.Cluster
  alias ControlServer.Repo

  @valid_attrs %{
    cluster: %{
      name: "PostgresLiveTest",
      virtual_size: "small",
      num_instances: 1
    }
  }

  describe "postgres list page" do
    test "render list postgres", %{conn: conn} do
      conn
      |> start(~p|/postgres|)
      |> assert_html("Postgres Clusters")
      |> assert_html("New")
      |> click("a", "New Cluster")
      |> follow(~p|/postgres/new|)
      |> assert_html("New Postgres Cluster")
    end
  end

  describe "postgres new page" do
    test "create new cluster", %{conn: conn} do
      assert is_nil(Repo.get_by(Cluster, name: @valid_attrs.cluster.name))

      conn
      |> start(~p"/postgres/new")
      |> submit_form("#cluster-form", @valid_attrs)

      assert not is_nil(Repo.get_by(Cluster, name: @valid_attrs.cluster.name))
    end
  end

  describe "postgres show page" do
    import ControlServer.Factory

    defp create_cluster(_) do
      %{cluster: insert(:postgres_cluster)}
    end

    setup [:create_cluster]

    test "show cluster page", %{conn: conn, cluster: cluster} do
      conn
      |> start(~p"/postgres/#{cluster.id}/show")
      |> assert_html("Postgres Cluster: ")
      |> assert_html(cluster.name)
    end
  end
end
