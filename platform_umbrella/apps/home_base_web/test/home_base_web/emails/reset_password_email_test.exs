defmodule HomeBaseWeb.ResetPasswordEmailTest do
  use Heyya.SnapshotCase

  alias HomeBaseWeb.ResetPasswordEmail

  component_snapshot_test "reset password text email" do
    ResetPasswordEmail.text(%{url: "/reset"})
  end

  component_snapshot_test "reset password html email" do
    assigns = %{}

    ~H"""
    <ResetPasswordEmail.html url="/reset" />
    """
  end
end
