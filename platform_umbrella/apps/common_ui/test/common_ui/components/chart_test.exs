defmodule CommonUI.Components.ChartTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Chart

  component_snapshot_test "default chart component" do
    assigns = %{}

    ~H"""
    <.chart
      id="test-chart"
      data={%{datasets: [%{label: "Test", data: [1, 2, 3, 4, 5, 6]}]}}
      merge_options={false}
    />
    """
  end
end
