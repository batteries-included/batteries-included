defmodule CommonUI.Components.FormTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Form

  component_snapshot_test "default form" do
    assigns = %{}

    ~H"""
    <.simple_form title="Some title">
      <div>Some inputs would go here</div>

      <:actions>
        <div>Some actions would go here</div>
      </:actions>
    </.simple_form>
    """
  end

  component_snapshot_test "form with error" do
    assigns = %{flash: %{"error" => "This is an error"}}

    ~H"""
    <.simple_form title="Some title" flash={@flash}>
      <div>Some inputs would go here</div>

      <:actions>
        <div>Some actions would go here</div>
      </:actions>
    </.simple_form>
    """
  end
end
