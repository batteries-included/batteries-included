defmodule HomeBaseWeb.TeamRoleEmailTest do
  use Heyya.SnapshotCase
  use HomeBaseWeb.ConnCase, async: true

  alias HomeBaseWeb.TeamRoleEmail

  setup do
    %{team: insert(:team, name: "test")}
  end

  component_snapshot_test "team role text email", ctx do
    TeamRoleEmail.text(%{team: ctx.team, url: "/installations"})
  end

  component_snapshot_test "team role html email", ctx do
    assigns = %{team: ctx.team}

    ~H"""
    <TeamRoleEmail.html team={@team} url="/installations" />
    """
  end
end
