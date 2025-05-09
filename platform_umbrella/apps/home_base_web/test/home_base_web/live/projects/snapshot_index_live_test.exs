defmodule HomeBaseWeb.Projects.SnapshotIndexLiveTest do
  use HomeBaseWeb.ConnCase
  use Heyya.LiveCase

  defp setup_user(_) do
    %{user: :user |> params_for() |> register_user!()}
  end

  defp login_conn(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end

  describe "Index" do
    setup [:setup_user, :login_conn]

    test "lists empty snapshots", %{conn: conn} do
      conn
      |> start(~p"/projects/snapshots")
      |> assert_html("Project Snapshots")
    end

    test "shows owned snapshots", %{conn: conn, user: user} do
      team = insert(:team)
      _ = insert(:team_role, team: team, user: user)

      install = insert(:installation, user_id: user.id, team_id: team.id)
      stored = insert(:stored_project_snapshot, installation_id: install.id, snapshot: params_for(:project))

      conn
      |> start(~p"/projects/snapshots")
      |> assert_html("Project Snapshots")
      |> assert_html(stored.snapshot.name)
    end
  end
end
