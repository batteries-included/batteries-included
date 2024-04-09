defmodule HomeBaseWeb.InstallationLiveTest do
  use HomeBaseWeb.ConnCase

  import HomeBase.Factory
  import Phoenix.LiveViewTest

  alias HomeBase.CustomerInstalls

  defp create_installation(_) do
    {:ok, installation} =
      :installation
      |> CommonCore.Factory.build()
      |> Map.from_struct()
      |> CustomerInstalls.create_installation()

    %{installation: installation}
  end

  defp setup_user(_) do
    %{user: :user |> params_for() |> register_user!()}
  end

  defp login_conn(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  describe "Index" do
    setup [:create_installation, :setup_user, :login_conn]

    test "lists all installations", %{conn: conn, installation: installation} do
      {:ok, _index_live, html} = live(conn, ~p"/installations")

      assert html =~ "Listing Installations"
      assert html =~ installation.slug
    end
  end

  describe "Show" do
    setup [:create_installation, :setup_user, :login_conn]

    test "displays installation", %{conn: conn, installation: installation} do
      {:ok, _show_live, html} = live(conn, ~p"/installations/#{installation}/show")

      assert html =~ "Show Installation"
      assert html =~ installation.slug
    end
  end
end
