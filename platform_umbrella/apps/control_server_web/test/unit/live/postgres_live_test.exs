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

  test "render list postgres", %{conn: conn} do
    conn
    |> start(~p|/postgres|)
    |> assert_html("Postgres Clusters")
    |> assert_html("New")
    |> click("a", "New Cluster")
    |> follow(~p|/postgres/new|)
    |> assert_html("New Postgres Cluster")
  end

  test "create new cluster", %{conn: conn} do
    assert is_nil(Repo.get_by(Cluster, name: @valid_attrs.cluster.name))

    conn
    |> start(~p"/postgres/new")
    |> submit_form("#cluster-form", @valid_attrs)

    assert not is_nil(Repo.get_by(Cluster, name: @valid_attrs.cluster.name))
  end
end
