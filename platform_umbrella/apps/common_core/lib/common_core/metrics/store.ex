defmodule CommonCore.Metrics.Store do
  @moduledoc """
  GenServer for managing ETS-based metrics storage.

  This module provides shared storage for telemetry metrics across applications
  in the umbrella project. It manages ETS tables with optimized read concurrency
  and periodic aggregation to minimize memory usage.

  ## Configuration

  - `:metrics_table` - Name of the ETS table for raw metrics (default: :metrics_store)
  - `:aggregated_table` - Name of the ETS table for aggregated metrics (default: :aggregated_metrics)
  - `:aggregation_interval` - Interval in ms for periodic aggregation (default: 30_000)
  - `:cleanup_after` - Time in ms after which old metrics are cleaned up (default: 300_000)
  - `:metrics` - List of Telemetry.Metrics for type-aware aggregation (default: [])

  ## Usage

      {:ok, pid} = CommonCore.Metrics.Store.start_link(
        name: MyApp.MetricsStore,
        metrics_table: :my_app_metrics,
        aggregated_table: :my_app_aggregated,
        aggregation_interval: 30_000,
        metrics: [
          Telemetry.Metrics.counter("http.requests", tags: [:method]),
          Telemetry.Metrics.summary("response.time", tags: [:endpoint])
        ]
      )
      :ok = CommonCore.Metrics.Store.put_metric(MyApp.MetricsStore, "http.requests", 1, %{"method" => "GET"})
      metrics = CommonCore.Metrics.Store.get_aggregated_metrics(MyApp.MetricsStore)
  """

  @behaviour CommonCore.Metrics.Store.Behaviour

  use GenServer
  use TypedStruct

  @state_opts [:metrics_table, :aggregated_table, :aggregation_interval, :cleanup_after, :metrics]

  typedstruct module: State do
    field :metrics_table, atom(), default: :metrics_store
    field :aggregated_table, atom(), default: :aggregated_metrics
    field :aggregation_interval, integer(), default: 30_000
    field :cleanup_after, integer(), default: 300_000
    field :metrics, [Telemetry.Metrics.t()], default: []
    field :timer_ref, reference(), default: nil
  end

  ## Public API

  @doc """
  Starts the metrics store GenServer.

  ## Options

  - `:name` - GenServer name (default: __MODULE__)
  - `:metrics_table` - ETS table name for raw metrics (default: :metrics_store)
  - `:aggregated_table` - ETS table name for aggregated metrics (default: :aggregated_metrics)
  - `:aggregation_interval` - Aggregation interval in ms (default: 30_000)
  - `:cleanup_after` - Time in ms after which old metrics are cleaned up (default: 300_000)
  - `:metrics` - List of Telemetry.Metrics for type-aware aggregation (default: [])
  """
  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  # Function headers for default arguments - comment out since we have different approach
  # def put_metric(metric_name, value, tags \\ %{})
  # def put_metric(table, metric_name, value, tags) when is_atom(table)

  @doc """
  Store a metric value with optional tags using default table.
  """
  def put_metric(metric_name, value, tags \\ %{}) when is_binary(metric_name) do
    put_metric(__MODULE__, metric_name, value, tags)
  end

  @doc """
  Store a metric value in a specific table via GenServer call.
  """
  @impl CommonCore.Metrics.Store.Behaviour
  def put_metric(server_name, metric_name, value, tags) when is_atom(server_name) do
    GenServer.call(server_name, {:put_metric, metric_name, value, tags})
  end

  @doc """
  Retrieve all metrics from the specified table.
  """
  @impl CommonCore.Metrics.Store.Behaviour
  def get_all_metrics(table \\ :metrics_store) do
    table
    |> :ets.tab2list()
    |> Enum.map(fn {_key, metric} -> metric end)
  rescue
    ArgumentError -> []
  end

  @doc """
  Retrieve aggregated metrics from the specified store.

  ## Parameters

  - `server_name` - The name of the Store GenServer process

  ## Returns

  List of aggregated metric maps with type-specific fields
  """
  @impl CommonCore.Metrics.Store.Behaviour
  def get_aggregated_metrics(server_name) when is_atom(server_name) do
    GenServer.call(server_name, :get_aggregated_metrics)
  end

  @doc """
  Get metrics for a specific metric name from the specified table.
  """
  @impl CommonCore.Metrics.Store.Behaviour
  def get_metrics(table, metric_name) do
    # Use match pattern to find all entries for this metric name
    pattern = {{metric_name, :_, :_}, :"$1"}

    table
    |> :ets.match(pattern)
    |> Enum.map(&List.first/1)
  rescue
    ArgumentError -> []
  end

  @doc """
  Record a metric with explicit type and timestamp for testing purposes.

  This function is mainly intended for testing scenarios where you need
  precise control over the metric type and timestamp.
  """
  def record_metric(server_name, metric_name, value, tags, type, timestamp) when is_atom(server_name) do
    GenServer.call(server_name, {:record_metric, metric_name, value, tags, type, timestamp})
  end

  ## GenServer Callbacks

  @impl GenServer
  def init(opts) do
    state = struct!(State, opts)

    # Create raw metrics ETS table with read concurrency optimization
    _metrics_table =
      :ets.new(state.metrics_table, [
        :protected,
        :set,
        :named_table,
        read_concurrency: true,
        write_concurrency: false
      ])

    # Create aggregated metrics ETS table
    _aggregated_table =
      :ets.new(state.aggregated_table, [
        :protected,
        :set,
        :named_table,
        read_concurrency: true,
        write_concurrency: false
      ])

    # Schedule first aggregation
    timer_ref = Process.send_after(self(), :aggregate_metrics, state.aggregation_interval)

    {:ok, %{state | timer_ref: timer_ref}}
  end

  @impl GenServer
  def handle_call({:put_metric, metric_name, value, tags}, _from, state) do
    metric_entry = %{
      name: metric_name,
      value: value,
      tags: tags,
      timestamp: DateTime.utc_now(),
      type: Map.get(tags, "_type", :gauge)
    }

    # Use a compound key: {metric_name, timestamp_microsecond, random} for uniqueness
    key = {metric_name, System.system_time(:microsecond), :rand.uniform(1_000_000)}

    :ets.insert(state.metrics_table, {key, metric_entry})
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:get_aggregated_metrics, _from, state) do
    aggregated_metrics =
      state.aggregated_table
      |> :ets.tab2list()
      |> Enum.map(fn {_key, metric} -> metric end)

    {:reply, aggregated_metrics, state}
  end

  @impl GenServer
  def handle_call({:record_metric, metric_name, value, tags, type, timestamp}, _from, state) do
    metric_entry = %{
      name: metric_name,
      value: value,
      tags: tags,
      timestamp: DateTime.from_unix!(timestamp, :microsecond),
      type: type
    }

    # Use a compound key: {metric_name, timestamp_microsecond, random} for uniqueness
    key = {metric_name, timestamp, :rand.uniform(1_000_000)}

    :ets.insert(state.metrics_table, {key, metric_entry})
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:aggregate_metrics, state) do
    # Perform aggregation of raw metrics
    raw_metrics = get_raw_metrics_in_window(state.metrics_table, state.aggregation_interval)

    if not Enum.empty?(raw_metrics) do
      aggregated_metrics =
        CommonCore.Metrics.Aggregator.aggregate_metrics(
          raw_metrics,
          state.metrics,
          state.aggregation_interval
        )

      # Store aggregated metrics
      store_aggregated_metrics(state.aggregated_table, aggregated_metrics)
    end

    # Cleanup old data
    cleanup_old_raw_metrics(state.metrics_table, state.aggregation_interval + 10_000)
    cleanup_old_aggregated_metrics(state.aggregated_table, state.cleanup_after)

    # Schedule next aggregation
    timer_ref = Process.send_after(self(), :aggregate_metrics, state.aggregation_interval)

    {:noreply, %{state | timer_ref: timer_ref}}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ## Private Helper Functions

  # Get raw metrics within the current aggregation window
  defp get_raw_metrics_in_window(table, _time_window) do
    # For now, get all raw metrics - could be optimized to filter by time
    table
    |> :ets.tab2list()
    |> Enum.map(fn {_key, metric} -> metric end)
  rescue
    ArgumentError -> []
  end

  # Store aggregated metrics in the aggregated table
  defp store_aggregated_metrics(table, aggregated_metrics) do
    now = DateTime.utc_now()

    Enum.each(aggregated_metrics, fn metric ->
      # Use compound key: {metric_name, tags_hash, timestamp} for uniqueness
      tags_hash = :erlang.phash2(metric.tags)
      key = {metric.name, tags_hash, now}

      :ets.insert(table, {key, metric})
    end)
  end

  # Cleanup old raw metrics beyond aggregation window + buffer
  defp cleanup_old_raw_metrics(table, cleanup_threshold_ms) do
    now = System.system_time(:microsecond)
    # Convert ms to microseconds
    cutoff_time = now - cleanup_threshold_ms * 1_000

    # Find keys to delete
    keys_to_delete =
      table
      |> :ets.tab2list()
      |> Enum.filter(fn {{_name, timestamp, _random}, _metric} ->
        timestamp < cutoff_time
      end)
      |> Enum.map(fn {key, _metric} -> key end)

    # Delete old entries
    Enum.each(keys_to_delete, fn key ->
      :ets.delete(table, key)
    end)
  rescue
    ArgumentError -> :ok
  end

  # Cleanup old aggregated metrics beyond retention period
  defp cleanup_old_aggregated_metrics(table, cleanup_after_ms) do
    now = DateTime.utc_now()
    cutoff_time = DateTime.add(now, -cleanup_after_ms, :millisecond)

    # Find keys to delete based on metric timestamps
    keys_to_delete =
      table
      |> :ets.tab2list()
      |> Enum.filter(fn {_key, metric} ->
        DateTime.before?(metric.timestamp, cutoff_time)
      end)
      |> Enum.map(fn {key, _metric} -> key end)

    # Delete old entries
    Enum.each(keys_to_delete, fn key ->
      :ets.delete(table, key)
    end)
  rescue
    ArgumentError -> :ok
  end
end
