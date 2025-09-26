defmodule CommonCore.Metrics.PrometheusFormatter.Behaviour do
  @moduledoc """
  Behaviour for formatting metrics into Prometheus text exposition format.

  This behaviour defines the interface for converting stored metrics data
  into the Prometheus text-based exposition format as specified at:
  https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format
  """

  @doc """
  Format all metrics from the store into Prometheus text exposition format.

  The output should conform to the Prometheus text format specification including:
  - HELP lines with metric descriptions
  - TYPE lines with metric types (counter, gauge, summary, etc.)
  - Metric lines with labels and values
  - Proper escaping of label values

  ## Parameters
  - `opts`: Keyword list of options including:
    - `:store_module` - Module implementing Store.Behaviour (default: CommonCore.Metrics.Store)
    - `:store_table` - Atom name of ETS table to read from (default: :metrics_store)

  ## Returns
  String in Prometheus text exposition format
  """
  @callback format_prometheus(keyword()) :: String.t()
end
