defmodule CommonUi.DatetimeDisplayTest do
  use ExUnit.Case

  import CommonUI.DatetimeDisplay
  import Phoenix.LiveViewTest

  describe "relative_display/1" do
    test "returns relative time tooltip" do
      assigns = %{time: ~U[2023-02-15 13:45:00Z]}
      html = assigns |> relative_display() |> rendered_to_string()

      # Since the display will change relative to now
      # there's not a lot to assert. Assert that the
      # date is there since that's the tooltip slot,
      # it's a good test of rendering most of what we expect.
      assert html =~ ~S|2023-02-15|
    end
  end
end
