defmodule CommonUI.Components.TableTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Table

  component_snapshot_test "default table component" do
    rows = [
      %{a: 100, b: "test"},
      %{a: 102, b: "testing"},
      %{a: 420, b: "anyone there?"}
    ]

    assigns = %{rows: rows}

    ~H"""
    <.table id="foobar" rows={@rows}>
      <:col :let={row} label="A">{row.a}</:col>
      <:col :let={row} label="B">{row.b}</:col>
    </.table>
    """
  end

  component_snapshot_test "table with row click" do
    rows = [
      %{a: 100, b: "test"},
      %{a: 102, b: "testing"},
      %{a: 420, b: "anyone there?"}
    ]

    assigns = %{rows: rows}

    ~H"""
    <.table id="foobar" rows={@rows} row_click={fn _ -> nil end}>
      <:col :let={row} label="A">{row.a}</:col>
      <:col :let={row} label="B">{row.b}</:col>
    </.table>
    """
  end
end
