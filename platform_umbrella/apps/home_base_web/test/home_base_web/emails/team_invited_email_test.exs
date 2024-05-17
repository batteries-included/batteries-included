defmodule HomeBaseWeb.TeamInvitedEmailTest do
  use Heyya.SnapshotCase
  use HomeBaseWeb.ConnCase, async: true

  alias HomeBaseWeb.TeamInvitedEmail

  setup do
    %{team: insert(:team, name: "test")}
  end

  component_snapshot_test "team invited text email", ctx do
    TeamInvitedEmail.text(%{team: ctx.team, url: "/"})
  end

  component_snapshot_test "team invited html email", ctx do
    assigns = %{team: ctx.team}

    ~H"""
    <TeamInvitedEmail.html team={@team} url="/" />
    """
  end
end
