defmodule CommonCore.Metrics.Reporter do
  @moduledoc """
  Custom telemetry reporter that stores metrics in ETS tables.

  This module implements the telemetry_metrics reporter specification:
  https://hexdocs.pm/telemetry_metrics/writing_reporters.html

  The reporter:
  - Attaches to telemetry events based on provided metrics definitions
  - Processes telemetry events and extracts measurements/tags
  - Stores metrics in ETS tables via Store module
  - Handles error cases gracefully without crashing
  - Supports all telemetry metric types (counter, summary, gauge, etc.)
  """

  use GenServer
  use TypedStruct

  @state_opts [:metrics, :store_module, :store_target]

  typedstruct module: State do
    field :metrics, [Telemetry.Metrics.t()], default: []
    field :store_module, module(), default: CommonCore.Metrics.Store
    field :store_target, atom(), required: true
    field :handler_ids, [term()], default: []
  end

  ## Public API

  @doc """
  Starts the metrics reporter GenServer.

  ## Options

  - `:name` - GenServer name (default: __MODULE__)
  - `:metrics` - List of telemetry metrics to report on
  - `:store_module` - Module implementing Store.Behaviour (default: CommonCore.Metrics.Store)
  -
  """
  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  ## GenServer Callbacks

  @impl GenServer
  def init(opts) do
    state = struct!(State, opts)
    handler_ids = attach_handlers(state.metrics, state)
    {:ok, %{state | handler_ids: handler_ids}}
  end

  @impl GenServer
  def terminate(_reason, state) do
    detach_handlers(state.handler_ids)
  end

  ## Private Functions

  defp attach_handlers(metrics, state) do
    metrics
    |> Enum.group_by(& &1.event_name)
    |> Enum.map(fn {event_name, event_metrics} ->
      handler_id = {__MODULE__, event_name, make_ref()}

      case :telemetry.attach(
             handler_id,
             event_name,
             &handle_event/4,
             %{metrics: event_metrics, state: state}
           ) do
        :ok -> :ok
        {:error, :already_exists} -> :ok
      end

      handler_id
    end)
  end

  defp detach_handlers(handler_ids) do
    Enum.each(handler_ids, fn handler_id ->
      :telemetry.detach(handler_id)
    end)
  end

  defp handle_event(event_name, measurements, metadata, %{metrics: metrics, state: state}) do
    # Only process metrics that match the event name
    matching_metrics =
      Enum.filter(metrics, fn metric ->
        metric.event_name == event_name
      end)

    Enum.each(matching_metrics, fn metric ->
      try do
        process_metric(metric, measurements, metadata, state)
      rescue
        _error ->
          # Log error but don't crash the handler
          # Could add proper logging here if needed
          :ok
      end
    end)
  end

  defp process_metric(
         metric,
         measurements,
         metadata,
         %State{store_module: store_module, store_target: store_target} = _state
       ) do
    # Apply keep function if present
    if should_keep_metric?(metric, measurements, metadata) do
      # Extract measurement value
      measurement_value = extract_measurement(metric, measurements)

      if measurement_value != nil do
        # Extract tags
        tags = extract_tags(metric, metadata)

        # Determine metric type and store appropriately
        metric_type = get_metric_type(metric)

        # Store the metric with type information
        enhanced_tags = Map.put(tags, "_type", metric_type)

        case store_module do
          module when is_atom(module) ->
            # Use the Store module via GenServer call pattern
            # Handle case where the store process might not be available (e.g., during tests)
            try do
              apply(module, :put_metric, [
                store_target,
                metric_name_to_string(metric.name),
                measurement_value,
                enhanced_tags
              ])
            catch
              :exit, {:noproc, _} ->
                # Store process not available, silently ignore
                :ok

              :exit, {:timeout, _} ->
                # Store process timeout, silently ignore
                :ok
            end

          _ ->
            # Direct module call for testing
            try do
              store_module.put_metric(
                store_target,
                metric_name_to_string(metric.name),
                measurement_value,
                enhanced_tags
              )
            rescue
              _ ->
                # Error in direct call, silently ignore
                :ok
            end
        end
      end
    end
  end

  defp should_keep_metric?(metric, measurements, metadata) do
    case metric.keep do
      nil -> true
      keep_fn when is_function(keep_fn, 2) -> keep_fn.(measurements, metadata)
      _ -> true
    end
  end

  defp extract_measurement(metric, measurements) do
    case metric.measurement do
      measurement_key when is_atom(measurement_key) ->
        Map.get(measurements, measurement_key)

      measurement_fn when is_function(measurement_fn, 1) ->
        measurement_fn.(measurements)

      _ ->
        nil
    end
  end

  defp extract_tags(metric, metadata) do
    # Extract tags based on tag names
    Enum.reduce(metric.tags, %{}, fn tag_key, acc ->
      case Map.get(metadata, tag_key) do
        nil -> acc
        value -> Map.put(acc, to_string(tag_key), to_string(value))
      end
    end)
  end

  defp get_metric_type(%Telemetry.Metrics.Counter{}), do: :counter
  defp get_metric_type(%Telemetry.Metrics.Summary{}), do: :summary
  defp get_metric_type(_), do: :gauge

  # Convert metric name list to string
  defp metric_name_to_string([]), do: ""
  defp metric_name_to_string([name]), do: metric_name_to_string(name)

  defp metric_name_to_string([head | tail]) do
    metric_name_to_string(head) <> "." <> metric_name_to_string(tail)
  end

  defp metric_name_to_string(name) when is_atom(name), do: Atom.to_string(name)
  defp metric_name_to_string(name) when is_binary(name), do: name
end
