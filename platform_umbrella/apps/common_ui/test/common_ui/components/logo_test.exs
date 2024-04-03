defmodule CommonUI.Components.LogoTest do
  use CommonUI.ComponentCase
  use Heyya.SnapshotCase

  import CommonUI.Components.Logo

  test "it renders the logo correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.logo class="some-class" />
      """)

    assert html =~ "Batteries"
    assert html =~ "some-class"
  end

  component_snapshot_test "logo" do
    assigns = %{}

    ~H"""
    <.logo />
    """
  end
end
