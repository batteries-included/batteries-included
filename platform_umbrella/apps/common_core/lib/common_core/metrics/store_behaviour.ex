defmodule CommonCore.Metrics.Store.Behaviour do
  @moduledoc """
  Behaviour for metrics storage operations.

  This behaviour defines the interface for storing and retrieving telemetry metrics
  using ETS tables. Implementations should focus solely on storage operations without
  formatting concerns.
  """

  @doc """
  Store a metric value with optional tags.

  ## Parameters
  - `server_name`: GenServer name to send the metric to
  - `metric_name`: String name of the metric
  - `value`: Numeric value of the measurement
  - `tags`: Map of tag key-value pairs for the metric (default: %{})

  ## Returns
  `:ok` on successful storage
  """
  @callback put_metric(atom(), String.t(), number(), map()) :: :ok

  @doc """
  Retrieve all metrics from the specified table.

  ## Parameters
  - `table`: The ETS table name to retrieve metrics from

  ## Returns
  List of metric maps with keys: `:name`, `:value`, `:tags`, `:timestamp`
  """
  @callback get_all_metrics(atom()) :: [map()]
  @callback get_all_metrics() :: [map()]

  @doc """
  Get metrics for a specific metric name from the specified table.

  ## Parameters
  - `table`: The ETS table name to query
  - `metric_name`: String name of the metric to retrieve

  ## Returns
  List of metric maps matching the metric name
  """
  @callback get_metrics(atom(), String.t()) :: [map()]

  @doc """
  Retrieve aggregated metrics from the specified store.

  ## Parameters
  - `server_name`: The name of the Store GenServer process

  ## Returns
  List of aggregated metric maps with type-specific fields
  """
  @callback get_aggregated_metrics(atom()) :: [map()]
end
