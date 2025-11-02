defmodule ControlServerWeb.MetricsController do
  use ControlServerWeb, :controller

  alias CommonCore.Metrics.PrometheusFormatter
  alias CommonCore.Metrics.Store

  @doc """
  Returns metrics in Prometheus text exposition format.
  Content-Type: text/plain; version=0.0.4
  """
  def prometheus(conn, _params) do
    metrics_text = PrometheusFormatter.format_prometheus(collect_control_server_metrics())

    conn
    |> put_resp_content_type("text/plain; version=0.0.4")
    |> text(metrics_text)
  rescue
    error ->
      require Logger

      Logger.error("Failed to format Prometheus metrics: #{inspect(error)}")

      conn
      |> put_status(:internal_server_error)
      |> text("Internal server error")
  end

  @doc """
  Returns metrics in JSON format for bi rage command consumption.
  Content-Type: application/json
  """
  def metrics_json(conn, _params) do
    # Get aggregated metrics data from control server release stores
    metrics_data = collect_control_server_metrics()

    # Structure data for bi rage consumption
    response = %{
      collected_at: DateTime.to_iso8601(DateTime.utc_now()),
      metrics: metrics_data
    }

    json(conn, response)
  rescue
    error ->
      require Logger

      Logger.error("Failed to collect metrics data: #{inspect(error)}")

      conn
      |> put_status(:internal_server_error)
      |> json(%{error: "Internal server error"})
  end

  # Private function to collect metrics from stores available in control server release
  defp collect_control_server_metrics do
    Enum.flat_map(control_server_stores(), &collect_store_metrics/1)
  end

  # Get list of store processes available in control server release
  defp control_server_stores do
    Enum.filter([ControlServerWeb.MetricsStore, ControlServer.MetricsStore], &Process.whereis/1)
  end

  # Collect metrics from a single store
  defp collect_store_metrics(store_name) do
    Store.get_aggregated_metrics(store_name)
  catch
    :exit, _ -> []
  end
end
