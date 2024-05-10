defmodule HomeBaseWeb.InstallationLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  import HomeBase.CustomerInstallsFixtures

  alias HomeBase.CustomerInstalls

  defp setup_user(_) do
    %{user: :user |> params_for() |> register_user!()}
  end

  defp login_conn(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  defp create_installation(%{user: user}) do
    {:ok, installation} =
      :installation
      |> CommonCore.Factory.build(user_id: user.id)
      |> Map.from_struct()
      |> CustomerInstalls.create_installation()

    %{installation: installation}
  end

  describe "Index" do
    setup [:setup_user, :login_conn, :create_installation]

    test "lists all installations", %{conn: conn, installation: installation} do
      {:ok, _index_live, html} = live(conn, ~p"/installations")

      assert html =~ "Installations"
      assert html =~ installation.slug
    end
  end

  describe "Show" do
    setup [:setup_user, :login_conn, :create_installation]

    test "displays installation", %{conn: conn, installation: installation} do
      {:ok, _show_live, html} = live(conn, ~p"/installations/#{installation}")

      assert html =~ installation.slug
    end

    test "shows not found for installation on another team", %{conn: conn} do
      team = insert(:team)
      installation = installation_fixture(team_id: team.id)

      assert_error_sent :not_found, fn -> get(conn, ~p"/installations/#{installation}") end
    end
  end
end
