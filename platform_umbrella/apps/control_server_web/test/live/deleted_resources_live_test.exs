defmodule ControlServerWeb.DeletedResourcesLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "deleted resources list page" do
    test "Can show an empty page", %{conn: conn} do
      conn
      |> start(~p|/deleted_resources|)
      |> assert_html("There no deleted resources.")
      |> assert_matches_snapshot(selector: "#empty-state-deleted")
    end

    test "can show a list of deleted resources", %{conn: conn} do
      _resource1 = insert(:deleted_resource, name: "resource1")
      _resource2 = insert(:deleted_resource, name: "resource2")

      conn
      |> start(~p|/deleted_resources|)
      |> assert_html("resource1")
      |> assert_html("resource2")
      |> assert_matches_snapshot(selector: "#deleted-resources-table thead")
    end
  end
end
