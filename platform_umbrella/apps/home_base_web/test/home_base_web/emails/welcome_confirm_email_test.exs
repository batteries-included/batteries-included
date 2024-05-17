defmodule HomeBaseWeb.WelcomeConfirmEmailTest do
  use Heyya.SnapshotCase

  alias HomeBaseWeb.WelcomeConfirmEmail

  component_snapshot_test "welcome confirm text email" do
    WelcomeConfirmEmail.text(%{url: "/confirm"})
  end

  component_snapshot_test "welcome confirm html email" do
    assigns = %{}

    ~H"""
    <WelcomeConfirmEmail.html url="/confirm" />
    """
  end
end
