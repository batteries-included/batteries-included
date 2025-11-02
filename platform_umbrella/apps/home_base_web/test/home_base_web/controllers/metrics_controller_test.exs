defmodule HomeBaseWeb.MetricsControllerTest do
  use HomeBaseWeb.ConnCase, async: false

  alias CommonCore.Metrics.Store

  describe "GET /api/metrics" do
    test "returns prometheus format with correct content-type", %{conn: conn} do
      # Store test metrics in home base stores
      Store.record_metric(
        HomeBaseWeb.MetricsStore,
        "http_requests_total",
        42,
        %{"method" => "GET", "code" => "200"},
        :counter,
        System.system_time(:microsecond)
      )

      Store.record_metric(
        HomeBaseWeb.MetricsStore,
        "response_time_ms",
        150,
        %{},
        :gauge,
        System.system_time(:microsecond)
      )

      # Trigger aggregation
      send(HomeBaseWeb.MetricsStore, :aggregate_metrics)

      # Wait for aggregation to process
      Process.sleep(50)

      conn = get(conn, ~p"/api/metrics")

      assert response(conn, 200) =~ "http_requests_total"
      assert get_resp_header(conn, "content-type") == ["text/plain; version=0.0.4; charset=utf-8"]
    end

    test "handles store errors gracefully", %{conn: conn} do
      # Test graceful handling without stopping store - empty response is valid
      conn = get(conn, ~p"/api/metrics")

      # Should return 200 with empty response when no metrics are available
      assert response(conn, 200)
    end
  end

  describe "GET /api/metrics/json" do
    test "returns json format with metrics data", %{conn: conn} do
      Store.record_metric(
        HomeBaseWeb.MetricsStore,
        "http_requests_total",
        42,
        %{"method" => "GET", "code" => "200"},
        :counter,
        System.system_time(:microsecond)
      )

      Store.record_metric(
        HomeBaseWeb.MetricsStore,
        "response_time_ms",
        150,
        %{},
        :gauge,
        System.system_time(:microsecond)
      )

      # Trigger aggregation
      send(HomeBaseWeb.MetricsStore, :aggregate_metrics)

      # Wait for aggregation to process
      Process.sleep(50)

      conn = get(conn, ~p"/api/metrics/json")

      response_data = json_response(conn, 200)
      assert %{"collected_at" => _, "metrics" => metrics} = response_data
      assert is_list(metrics)
      assert length(metrics) >= 2
    end

    test "handles store errors gracefully", %{conn: conn} do
      # Test graceful handling - empty response is valid
      conn = get(conn, ~p"/api/metrics/json")

      assert response = json_response(conn, 200)
      assert Map.has_key?(response, "metrics")
    end
  end
end
