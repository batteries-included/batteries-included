defmodule CommonCore.Metrics.PrometheusFormatter do
  @moduledoc """
  Formats metrics data into Prometheus text exposition format.

  Implements the Prometheus text format specification:
  https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format

  This module follows single responsibility principle by focusing solely on
  Prometheus text format generation. It uses the Store module to retrieve
  metrics data and formats it according to Prometheus specifications.
  """

  @behaviour CommonCore.Metrics.PrometheusFormatter.Behaviour

  use TypedStruct

  @doc """
  Format all metrics from the store into Prometheus text exposition format.

  Returns a string in the proper Prometheus exposition format with:
  - HELP lines describing metrics
  - TYPE lines declaring metric types
  - Metric lines with labels and values
  - Proper label value escaping

  ## Returns

  String in Prometheus text exposition format
  """
  @impl CommonCore.Metrics.PrometheusFormatter.Behaviour
  def format_prometheus(metrics \\ []) do
    if Enum.empty?(metrics) do
      ""
    else
      metrics
      |> group_metrics_by_name()
      # Sort by metric name alphabetically
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map_join("\n", &format_metric_group/1)
    end
  end

  ## Private Functions

  defp group_metrics_by_name(metrics) do
    Enum.group_by(metrics, & &1.name)
  end

  defp format_metric_group({metric_name, metric_entries}) do
    # Get the first metric to determine type (assume all have same type for same name)
    first_metric = List.first(metric_entries)
    metric_type = Map.get(first_metric, :type, infer_type_from_name(metric_name))

    lines = []

    # Add HELP line
    help_description = generate_help_description(metric_name, metric_type)
    lines = [format_help_line(metric_name, help_description) | lines]

    # Add TYPE line
    lines = [format_type_line(metric_name, metric_type) | lines]

    # Add metric lines for each entry
    metric_lines =
      Enum.flat_map(metric_entries, fn metric ->
        format_metric_lines_for_entry(metric_name, metric)
      end)

    lines = lines ++ metric_lines

    # Reverse since we built the list backwards, then join
    lines
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp format_help_line(metric_name, description) do
    "# HELP #{metric_name} #{description}"
  end

  defp format_type_line(metric_name, metric_type) do
    "# TYPE #{metric_name} #{metric_type}"
  end

  defp format_metric_lines_for_entry(metric_name, metric) do
    cond do
      # Summary metric with aggregated statistics
      Map.has_key?(metric, :count) and Map.has_key?(metric, :sum) ->
        format_summary_metric_lines(metric_name, metric)

      # Counter or gauge metric with simple value
      Map.has_key?(metric, :value) ->
        formatted_value = format_value(metric.value)
        [format_single_metric_line(metric_name, formatted_value, metric.tags)]

      # Fallback - shouldn't happen but handle gracefully
      true ->
        [format_single_metric_line(metric_name, 0, metric.tags)]
    end
  end

  defp format_single_metric_line(metric_name, formatted_value, tags) do
    if Enum.empty?(tags) do
      "#{metric_name} #{formatted_value}"
    else
      labels = format_labels(tags)
      "#{metric_name}{#{labels}} #{formatted_value}"
    end
  end

  defp format_summary_metric_lines(metric_name, summary_metric) do
    format_summary_metric_lines(metric_name, summary_metric, summary_metric.tags)
  end

  defp format_summary_metric_lines(metric_name, summary_metric, tags) do
    base_labels = format_labels(tags)
    labels_suffix = if Enum.empty?(tags), do: "", else: "{#{base_labels}}"

    [
      "#{metric_name}_sum#{labels_suffix} #{format_value(summary_metric.sum)}",
      "#{metric_name}_count#{labels_suffix} #{format_value(summary_metric.count)}"
    ]
  end

  defp format_labels(tags) do
    tags
    # Sort labels alphabetically by key
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map_join(",", fn {key, value} ->
      escaped_value = escape_label_value(to_string(value))
      ~s(#{key}="#{escaped_value}")
    end)
  end

  defp escape_label_value(value) do
    value
    # Escape backslashes first
    |> String.replace("\\", "\\\\")
    # Escape quotes
    |> String.replace("\"", "\\\"")
    # Escape newlines
    |> String.replace("\n", "\\n")
  end

  defp format_value(:nan), do: "NaN"
  defp format_value(:infinity), do: "+Inf"
  defp format_value(:negative_infinity), do: "-Inf"
  defp format_value(value) when is_number(value), do: to_string(value)
  defp format_value(value), do: to_string(value)

  defp infer_type_from_name(name) do
    cond do
      String.ends_with?(name, "_total") -> :counter
      String.ends_with?(name, "_count") -> :counter
      String.contains?(name, "duration") -> :summary
      String.contains?(name, "time") -> :summary
      String.contains?(name, "usage") -> :gauge
      String.contains?(name, "memory") -> :gauge
      # Default to gauge
      true -> :gauge
    end
  end

  defp generate_help_description(metric_name, metric_type) do
    case metric_type do
      :counter -> "Total count of #{metric_name}"
      :gauge -> "Current value of #{metric_name}"
      :summary -> "Summary statistics for #{metric_name}"
      :histogram -> "Histogram of #{metric_name}"
      _ -> "Metric #{metric_name}"
    end
  end
end
