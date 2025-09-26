defmodule CommonCore.Metrics.Aggregator do
  @moduledoc """
  Handles time-window aggregation of raw metrics data.

  Implements metric type-specific aggregation logic:
  - Counter: Sum increments (always 1 per event)
  - Sum: Sum measurement values
  - Summary: Calculate min, max, count, mean, sum
  - LastValue/Gauge: Use most recent by timestamp
  - Distribution: Build histogram buckets (future implementation)

  ## Example Usage

      raw_metrics = [
        %{name: "http.requests", value: 1, tags: %{"method" => "GET"}, timestamp: ~U[2023-01-01 10:00:00Z], type: :counter},
        %{name: "http.requests", value: 1, tags: %{"method" => "GET"}, timestamp: ~U[2023-01-01 10:00:01Z], type: :counter}
      ]

      metrics = [
        Telemetry.Metrics.counter("http.requests", tags: [:method])
      ]

      aggregated = CommonCore.Metrics.Aggregator.aggregate_metrics(raw_metrics, metrics, 30_000)
      # Returns: [%{name: "http.requests", type: :counter, value: 2, tags: %{"method" => "GET"}, ...}]
  """

  @doc """
  Aggregate raw metrics into time-window summaries.

  Groups raw metrics by name and tag combinations, then applies metric type-specific
  aggregation logic to produce summary statistics for each group.

  ## Parameters

  - `raw_metrics` - List of raw metric maps with keys: name, value, tags, timestamp, type
  - `metrics` - List of Telemetry.Metrics definitions for type information
  - `time_window` - Time window in milliseconds (currently unused but available for future filtering)

  ## Returns

  List of aggregated metric maps with type-specific fields:
  - Counter: %{name, type: :counter, value: count, tags, timestamp}
  - Sum: %{name, type: :sum, value: sum, tags, timestamp}
  - Summary: %{name, type: :summary, count, sum, min, max, mean, tags, timestamp}
  - Gauge: %{name, type: :gauge, value: latest_value, tags, timestamp}
  """
  def aggregate_metrics(raw_metrics, metrics, _time_window) do
    raw_metrics
    |> group_by_name_and_tags()
    |> Enum.map(fn {metric_key, measurements} ->
      {metric_name, tags} = metric_key
      metric_def = find_metric_definition(metric_name, metrics)
      aggregate_by_type(metric_def, measurements, metric_name, tags)
    end)
  end

  @doc """
  Group raw metrics by name and tag combinations.

  Creates a map where keys are {metric_name, tags} tuples and values are lists
  of metrics that share the same name and tag values.

  ## Parameters

  - `raw_metrics` - List of raw metric maps

  ## Returns

  Map with {name, tags} keys and metric list values
  """
  def group_by_name_and_tags(raw_metrics) do
    Enum.group_by(raw_metrics, fn metric ->
      {metric.name, metric.tags}
    end)
  end

  @doc """
  Find a metric definition by name from the provided definitions.

  Searches for a telemetry metric definition that matches the given metric name.
  Handles name comparison by converting between string and atom list formats.

  ## Parameters

  - `metric_name` - String name of the metric to find
  - `metrics` - List of Telemetry.Metrics definitions

  ## Returns

  Telemetry.Metrics struct or nil if not found
  """
  def find_metric_definition(metric_name, metrics) do
    # Convert string metric name to atom list for comparison
    name_atoms = metric_name_to_atoms(metric_name)

    Enum.find(metrics, fn definition ->
      definition.name == name_atoms
    end)
  end

  ## Private Functions

  # Aggregate measurements based on metric type
  defp aggregate_by_type(nil, measurements, metric_name, tags) do
    # No metric definition found, use type from raw metric or infer
    sample_metric = List.first(measurements)
    metric_type = Map.get(sample_metric, :type, :gauge)
    aggregate_by_type_name(metric_type, measurements, metric_name, tags)
  end

  defp aggregate_by_type(%Telemetry.Metrics.Counter{}, measurements, metric_name, tags) do
    aggregate_by_type_name(:counter, measurements, metric_name, tags)
  end

  defp aggregate_by_type(%Telemetry.Metrics.Sum{}, measurements, metric_name, tags) do
    aggregate_by_type_name(:sum, measurements, metric_name, tags)
  end

  defp aggregate_by_type(%Telemetry.Metrics.Summary{}, measurements, metric_name, tags) do
    aggregate_by_type_name(:summary, measurements, metric_name, tags)
  end

  defp aggregate_by_type(%Telemetry.Metrics.LastValue{}, measurements, metric_name, tags) do
    aggregate_by_type_name(:gauge, measurements, metric_name, tags)
  end

  defp aggregate_by_type(_metric_def, measurements, metric_name, tags) do
    # Default to gauge for unknown metric types
    aggregate_by_type_name(:gauge, measurements, metric_name, tags)
  end

  # Type-specific aggregation implementations
  defp aggregate_by_type_name(:counter, measurements, metric_name, tags) do
    # Counters increment by 1 for each event, regardless of measurement value
    count = length(measurements)
    latest_timestamp = get_latest_timestamp(measurements)

    %{
      name: metric_name,
      type: :counter,
      value: count,
      tags: tags,
      timestamp: latest_timestamp
    }
  end

  defp aggregate_by_type_name(:sum, measurements, metric_name, tags) do
    # Sum metrics add the measurement values
    total = Enum.sum(Enum.map(measurements, & &1.value))
    latest_timestamp = get_latest_timestamp(measurements)

    %{
      name: metric_name,
      type: :sum,
      value: total,
      tags: tags,
      timestamp: latest_timestamp
    }
  end

  defp aggregate_by_type_name(:summary, measurements, metric_name, tags) do
    # Summary metrics compute statistical aggregates
    values = Enum.map(measurements, & &1.value)
    count = length(values)
    sum = Enum.sum(values)
    min = Enum.min(values)
    max = Enum.max(values)
    mean = sum / count
    latest_timestamp = get_latest_timestamp(measurements)

    %{
      name: metric_name,
      type: :summary,
      count: count,
      sum: sum,
      min: min,
      max: max,
      mean: mean,
      tags: tags,
      timestamp: latest_timestamp
    }
  end

  defp aggregate_by_type_name(:gauge, measurements, metric_name, tags) do
    # Gauge metrics use the most recent value by timestamp
    latest_metric = Enum.max_by(measurements, & &1.timestamp, DateTime)

    %{
      name: metric_name,
      type: :gauge,
      value: latest_metric.value,
      tags: tags,
      timestamp: latest_metric.timestamp
    }
  end

  # Get the most recent timestamp from a list of measurements
  defp get_latest_timestamp(measurements) do
    Enum.max_by(measurements, & &1.timestamp, DateTime).timestamp
  end

  # Convert metric name string to atom list for comparison with Telemetry.Metrics
  defp metric_name_to_atoms(metric_name) when is_binary(metric_name) do
    metric_name
    |> String.split(".")
    |> Enum.map(&String.to_atom/1)
  end
end
