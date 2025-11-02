defmodule CommonCore.Metrics.AggregatorTest do
  use ExUnit.Case, async: true

  import Telemetry.Metrics

  alias CommonCore.Metrics.Aggregator

  describe "aggregate_metrics/3" do
    test "aggregates counter metrics by summing all increments" do
      # Counter metrics always increment by 1 regardless of measurement value
      raw_metrics = [
        %{
          name: "http.requests",
          value: 5,
          tags: %{"method" => "GET"},
          timestamp: ~U[2023-01-01 10:00:00Z],
          type: :counter
        },
        %{
          name: "http.requests",
          value: 10,
          tags: %{"method" => "GET"},
          timestamp: ~U[2023-01-01 10:00:01Z],
          type: :counter
        },
        %{
          name: "http.requests",
          value: 15,
          tags: %{"method" => "GET"},
          timestamp: ~U[2023-01-01 10:00:02Z],
          type: :counter
        }
      ]

      metrics = [
        counter("http.requests", tags: [:method])
      ]

      time_window = 30_000

      aggregated = Aggregator.aggregate_metrics(raw_metrics, metrics, time_window)

      assert length(aggregated) == 1

      aggregated_metric = List.first(aggregated)
      assert aggregated_metric.name == "http.requests"
      assert aggregated_metric.type == :counter
      # Count of events, not sum of values
      assert aggregated_metric.value == 3
      assert aggregated_metric.tags == %{"method" => "GET"}
    end

    test "aggregates summary metrics with statistical calculations" do
      raw_metrics = [
        %{
          name: "response.time",
          value: 100,
          tags: %{"endpoint" => "/api"},
          timestamp: ~U[2023-01-01 10:00:00Z],
          type: :summary
        },
        %{
          name: "response.time",
          value: 200,
          tags: %{"endpoint" => "/api"},
          timestamp: ~U[2023-01-01 10:00:01Z],
          type: :summary
        },
        %{
          name: "response.time",
          value: 150,
          tags: %{"endpoint" => "/api"},
          timestamp: ~U[2023-01-01 10:00:02Z],
          type: :summary
        },
        %{
          name: "response.time",
          value: 300,
          tags: %{"endpoint" => "/api"},
          timestamp: ~U[2023-01-01 10:00:03Z],
          type: :summary
        }
      ]

      metrics = [
        summary("response.time", tags: [:endpoint])
      ]

      time_window = 30_000

      aggregated = Aggregator.aggregate_metrics(raw_metrics, metrics, time_window)

      assert length(aggregated) == 1

      aggregated_metric = List.first(aggregated)
      assert aggregated_metric.name == "response.time"
      assert aggregated_metric.type == :summary
      assert aggregated_metric.tags == %{"endpoint" => "/api"}

      # Check summary statistics
      assert aggregated_metric.count == 4
      assert aggregated_metric.sum == 750
      assert aggregated_metric.min == 100
      assert aggregated_metric.max == 300
      assert aggregated_metric.mean == 187.5
    end

    test "aggregates gauge metrics using most recent value" do
      raw_metrics = [
        %{
          name: "memory.usage",
          value: 100,
          tags: %{"instance" => "server1"},
          timestamp: ~U[2023-01-01 10:00:00Z],
          type: :gauge
        },
        # Most recent
        %{
          name: "memory.usage",
          value: 120,
          tags: %{"instance" => "server1"},
          timestamp: ~U[2023-01-01 10:00:02Z],
          type: :gauge
        },
        %{
          name: "memory.usage",
          value: 110,
          tags: %{"instance" => "server1"},
          timestamp: ~U[2023-01-01 10:00:01Z],
          type: :gauge
        }
      ]

      metrics = [
        last_value("memory.usage", tags: [:instance])
      ]

      time_window = 30_000

      aggregated = Aggregator.aggregate_metrics(raw_metrics, metrics, time_window)

      assert length(aggregated) == 1

      aggregated_metric = List.first(aggregated)
      assert aggregated_metric.name == "memory.usage"
      assert aggregated_metric.type == :gauge
      # Most recent by timestamp
      assert aggregated_metric.value == 120
      assert aggregated_metric.tags == %{"instance" => "server1"}
    end

    test "groups metrics by name and tag combinations" do
      raw_metrics = [
        %{
          name: "http.requests",
          value: 1,
          tags: %{"method" => "GET", "status" => "200"},
          timestamp: ~U[2023-01-01 10:00:00Z],
          type: :counter
        },
        %{
          name: "http.requests",
          value: 1,
          tags: %{"method" => "GET", "status" => "200"},
          timestamp: ~U[2023-01-01 10:00:01Z],
          type: :counter
        },
        %{
          name: "http.requests",
          value: 1,
          tags: %{"method" => "POST", "status" => "200"},
          timestamp: ~U[2023-01-01 10:00:02Z],
          type: :counter
        },
        %{
          name: "http.requests",
          value: 1,
          tags: %{"method" => "GET", "status" => "404"},
          timestamp: ~U[2023-01-01 10:00:03Z],
          type: :counter
        }
      ]

      metrics = [
        counter("http.requests", tags: [:method, :status])
      ]

      time_window = 30_000

      aggregated = Aggregator.aggregate_metrics(raw_metrics, metrics, time_window)

      # Three unique tag combinations
      assert length(aggregated) == 3

      # Sort by tags for predictable testing
      sorted_metrics = Enum.sort_by(aggregated, &{&1.tags["method"], &1.tags["status"]})

      # GET 200
      assert Enum.at(sorted_metrics, 0).value == 2
      assert Enum.at(sorted_metrics, 0).tags == %{"method" => "GET", "status" => "200"}

      # GET 404
      assert Enum.at(sorted_metrics, 1).value == 1
      assert Enum.at(sorted_metrics, 1).tags == %{"method" => "GET", "status" => "404"}

      # POST 200
      assert Enum.at(sorted_metrics, 2).value == 1
      assert Enum.at(sorted_metrics, 2).tags == %{"method" => "POST", "status" => "200"}
    end

    test "handles multiple metric names in single call" do
      raw_metrics = [
        %{
          name: "http.requests",
          value: 1,
          tags: %{"method" => "GET"},
          timestamp: ~U[2023-01-01 10:00:00Z],
          type: :counter
        },
        %{
          name: "http.requests",
          value: 1,
          tags: %{"method" => "GET"},
          timestamp: ~U[2023-01-01 10:00:01Z],
          type: :counter
        },
        %{
          name: "response.time",
          value: 150,
          tags: %{"endpoint" => "/api"},
          timestamp: ~U[2023-01-01 10:00:00Z],
          type: :summary
        },
        %{
          name: "memory.usage",
          value: 100,
          tags: %{"instance" => "server1"},
          timestamp: ~U[2023-01-01 10:00:00Z],
          type: :gauge
        }
      ]

      metrics = [
        counter("http.requests", tags: [:method]),
        summary("response.time", tags: [:endpoint]),
        last_value("memory.usage", tags: [:instance])
      ]

      time_window = 30_000

      aggregated = Aggregator.aggregate_metrics(raw_metrics, metrics, time_window)

      assert length(aggregated) == 3

      # Check that all three metric types are present
      metric_names = aggregated |> Enum.map(& &1.name) |> Enum.sort()
      assert metric_names == ["http.requests", "memory.usage", "response.time"]
    end

    test "handles empty metrics gracefully" do
      aggregated = Aggregator.aggregate_metrics([], [], 30_000)
      assert aggregated == []
    end

    test "handles missing metric definitions by using inferred types" do
      raw_metrics = [
        %{name: "unknown.metric", value: 42, tags: %{}, timestamp: ~U[2023-01-01 10:00:00Z], type: :gauge}
      ]

      # No definitions provided
      metrics = []
      time_window = 30_000

      aggregated = Aggregator.aggregate_metrics(raw_metrics, metrics, time_window)

      assert length(aggregated) == 1

      aggregated_metric = List.first(aggregated)
      assert aggregated_metric.name == "unknown.metric"
      # Should use the type from the raw metric
      assert aggregated_metric.type == :gauge
      assert aggregated_metric.value == 42
    end

    test "aggregates sum metrics by adding measurement values" do
      raw_metrics = [
        %{
          name: "bytes.transferred",
          value: 1024,
          tags: %{"service" => "api"},
          timestamp: ~U[2023-01-01 10:00:00Z],
          type: :sum
        },
        %{
          name: "bytes.transferred",
          value: 2048,
          tags: %{"service" => "api"},
          timestamp: ~U[2023-01-01 10:00:01Z],
          type: :sum
        },
        %{
          name: "bytes.transferred",
          value: 512,
          tags: %{"service" => "api"},
          timestamp: ~U[2023-01-01 10:00:02Z],
          type: :sum
        }
      ]

      metrics = [
        sum("bytes.transferred", tags: [:service])
      ]

      time_window = 30_000

      aggregated = Aggregator.aggregate_metrics(raw_metrics, metrics, time_window)

      assert length(aggregated) == 1

      aggregated_metric = List.first(aggregated)
      assert aggregated_metric.name == "bytes.transferred"
      assert aggregated_metric.type == :sum
      # Sum of measurement values
      assert aggregated_metric.value == 3584
      assert aggregated_metric.tags == %{"service" => "api"}
    end
  end

  describe "find_metric_definition/2" do
    test "finds metric definition by name" do
      metrics = [
        counter("http.requests", tags: [:method]),
        summary("response.time", tags: [:endpoint])
      ]

      result = Aggregator.find_metric_definition("http.requests", metrics)

      assert result
      assert result.name == [:http, :requests]
    end

    test "returns nil when metric definition not found" do
      metrics = [
        counter("http.requests", tags: [:method])
      ]

      result = Aggregator.find_metric_definition("unknown.metric", metrics)

      assert result == nil
    end
  end

  describe "group_by_name_and_tags/1" do
    test "groups metrics correctly by name and tags" do
      raw_metrics = [
        %{name: "test.metric", value: 1, tags: %{"a" => "1"}, timestamp: ~U[2023-01-01 10:00:00Z], type: :counter},
        %{name: "test.metric", value: 2, tags: %{"a" => "1"}, timestamp: ~U[2023-01-01 10:00:01Z], type: :counter},
        %{name: "test.metric", value: 3, tags: %{"a" => "2"}, timestamp: ~U[2023-01-01 10:00:02Z], type: :counter}
      ]

      grouped = Aggregator.group_by_name_and_tags(raw_metrics)

      assert map_size(grouped) == 2
      assert Map.has_key?(grouped, {"test.metric", %{"a" => "1"}})
      assert Map.has_key?(grouped, {"test.metric", %{"a" => "2"}})

      group1 = Map.get(grouped, {"test.metric", %{"a" => "1"}})
      group2 = Map.get(grouped, {"test.metric", %{"a" => "2"}})

      assert length(group1) == 2
      assert length(group2) == 1
    end
  end
end
