defmodule CommonUI.Components.TableTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Table

  component_snapshot_test "Table with no row click" do
    rows = [
      %{a: 100, b: "test"},
      %{a: 102, b: "testing"},
      %{a: 420, b: "anyone there?"}
    ]

    assigns = %{rows: rows}

    ~H"""
    <.table rows={@rows}>
      <:col :let={row} label="A"><%= row.a %></:col>
      <:col :let={row} label="B"><%= row.b %></:col>
    </.table>
    """
  end
end
