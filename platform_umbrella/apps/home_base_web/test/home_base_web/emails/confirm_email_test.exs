defmodule HomeBaseWeb.ConfirmEmailTest do
  use Heyya.SnapshotCase

  alias HomeBaseWeb.ConfirmEmail

  component_snapshot_test "confirm text email" do
    ConfirmEmail.text(%{url: "/confirm"})
  end

  component_snapshot_test "confirm html email" do
    assigns = %{}

    ~H"""
    <ConfirmEmail.html url="/confirm" />
    """
  end
end
