defmodule HomeBaseWeb.InstallationLiveTest do
  use HomeBaseWeb.ConnCase

  import HomeBase.ControlServerClustersFixtures
  import Phoenix.LiveViewTest

  @create_attrs %{slug: "some-slug"}
  @invalid_attrs %{slug: ""}

  defp create_installation(_) do
    installation = installation_fixture()
    %{installation: installation}
  end

  describe "Index" do
    setup [:create_installation]

    test "lists all installations", %{conn: conn, installation: installation} do
      {:ok, _index_live, html} = live(conn, ~p"/installations")

      assert html =~ "Listing Installations"
      assert html =~ installation.slug
    end
  end

  describe "New" do
    test "saves new installation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/installations/new")

      assert index_live
             |> form("#installation-form", installation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      index_live
      |> form("#installation-form", installation: @create_attrs)
      |> render_submit()

      {:ok, _, html} = live(conn, ~p"/installations")

      assert html =~ "some-slug"
    end
  end

  describe "Show" do
    setup [:create_installation]

    test "displays installation", %{conn: conn, installation: installation} do
      {:ok, _show_live, html} = live(conn, ~p"/installations/#{installation}/show")

      assert html =~ "Show Installation"
      assert html =~ installation.slug
    end
  end
end
