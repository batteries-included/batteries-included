defmodule HomeBaseWeb.TeamBootedEmailTest do
  use Heyya.SnapshotCase
  use HomeBaseWeb.ConnCase, async: true

  alias HomeBaseWeb.TeamBootedEmail

  setup do
    %{team: insert(:team, name: "test")}
  end

  component_snapshot_test "team booted text email", ctx do
    TeamBootedEmail.text(%{team: ctx.team})
  end

  component_snapshot_test "team booted html email", ctx do
    assigns = %{team: ctx.team}

    ~H"""
    <TeamBootedEmail.html team={@team} />
    """
  end
end
