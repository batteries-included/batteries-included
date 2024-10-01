defmodule HomeBaseWeb.WelcomeConfirmEmailTest do
  use Heyya.SnapshotCase

  alias HomeBaseWeb.WelcomeConfirmEmail

  @url "/confirm"

  component_snapshot_test "welcome confirm text email" do
    WelcomeConfirmEmail.text(%{home_url: nil, url: @url})
  end

  component_snapshot_test "welcome confirm html email" do
    assigns = %{home_url: nil, url: @url}

    ~H"""
    <WelcomeConfirmEmail.html home_url={@home_url} url={@url} />
    """
  end
end
