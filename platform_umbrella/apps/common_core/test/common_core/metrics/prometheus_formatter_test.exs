defmodule CommonCore.Metrics.PrometheusFormatterTest do
  use ExUnit.Case, async: true

  import Mox

  alias CommonCore.Metrics.PrometheusFormatter

  setup :verify_on_exit!

  describe "format_prometheus/1" do
    test "formats empty metrics list" do
      result = PrometheusFormatter.format_prometheus([])

      assert result == ""
    end

    test "formats single counter metric" do
      metrics = [
        %{
          name: "http_requests_total",
          value: 100,
          tags: %{"method" => "GET", "endpoint" => "/api/test"},
          timestamp: DateTime.utc_now(),
          type: :counter
        }
      ]

      result =
        PrometheusFormatter.format_prometheus(metrics)

      # Should contain HELP line
      assert String.contains?(result, "# HELP http_requests_total")

      # Should contain TYPE line
      assert String.contains?(result, "# TYPE http_requests_total counter")

      # Should contain metric line with labels (labels are sorted alphabetically)
      assert String.contains?(result, ~s(http_requests_total{endpoint="/api/test",method="GET"} 100))
    end

    test "formats multiple metrics of same name" do
      metrics = [
        %{
          name: "cpu_usage",
          value: 0.5,
          tags: %{"instance" => "server1"},
          timestamp: DateTime.utc_now(),
          type: :gauge
        },
        %{
          name: "cpu_usage",
          value: 0.7,
          tags: %{"instance" => "server2"},
          timestamp: DateTime.utc_now(),
          type: :gauge
        }
      ]

      result = PrometheusFormatter.format_prometheus(metrics)

      # Should only have one HELP and TYPE line per metric name
      assert result |> String.split("# HELP cpu_usage") |> length() == 2
      assert result |> String.split("# TYPE cpu_usage") |> length() == 2

      # Should have both metric instances
      assert String.contains?(result, ~s(cpu_usage{instance="server1"} 0.5))
      assert String.contains?(result, ~s(cpu_usage{instance="server2"} 0.7))
    end

    test "formats metrics with different types" do
      metrics = [
        %{
          name: "requests_total",
          value: 1000,
          tags: %{},
          timestamp: DateTime.utc_now(),
          type: :counter
        },
        %{
          name: "memory_usage",
          value: 0.8,
          tags: %{},
          timestamp: DateTime.utc_now(),
          type: :gauge
        },
        %{
          name: "response_time",
          value: 0.25,
          tags: %{},
          timestamp: DateTime.utc_now(),
          type: :summary
        }
      ]

      result = PrometheusFormatter.format_prometheus(metrics)

      # Should have correct TYPE declarations
      assert String.contains?(result, "# TYPE requests_total counter")
      assert String.contains?(result, "# TYPE memory_usage gauge")
      assert String.contains?(result, "# TYPE response_time summary")
    end

    test "escapes label values properly" do
      metrics = [
        %{
          name: "test_metric",
          value: 1,
          tags: %{
            "path" => "/api/test \"with quotes\"",
            "backslash" => "C:\\Windows\\System32",
            "newline" => "line1\nline2"
          },
          timestamp: DateTime.utc_now(),
          type: :counter
        }
      ]

      result = PrometheusFormatter.format_prometheus(metrics)

      # Check that special characters are properly escaped
      assert String.contains?(result, ~s(path="/api/test \\"with quotes\\""))
      assert String.contains?(result, ~s(backslash="C:\\\\Windows\\\\System32"))
      assert String.contains?(result, ~s(newline="line1\\nline2"))
    end

    test "handles metrics without tags" do
      metrics = [
        %{
          name: "simple_metric",
          value: 42,
          tags: %{},
          timestamp: DateTime.utc_now(),
          type: :gauge
        }
      ]

      result = PrometheusFormatter.format_prometheus(metrics)

      # Should have metric without label braces
      assert String.contains?(result, "simple_metric 42")
      refute String.contains?(result, "simple_metric{}")
    end

    test "handles special float values" do
      metrics = [
        %{name: "nan_metric", value: :nan, tags: %{}, timestamp: DateTime.utc_now(), type: :gauge},
        %{name: "inf_metric", value: :infinity, tags: %{}, timestamp: DateTime.utc_now(), type: :gauge},
        %{name: "neg_inf_metric", value: :negative_infinity, tags: %{}, timestamp: DateTime.utc_now(), type: :gauge}
      ]

      result = PrometheusFormatter.format_prometheus(metrics)

      assert String.contains?(result, "nan_metric NaN")
      assert String.contains?(result, "inf_metric +Inf")
      assert String.contains?(result, "neg_inf_metric -Inf")
    end

    test "orders metrics alphabetically by name" do
      metrics = [
        %{name: "zebra_metric", value: 1, tags: %{}, timestamp: DateTime.utc_now(), type: :counter},
        %{name: "alpha_metric", value: 2, tags: %{}, timestamp: DateTime.utc_now(), type: :counter},
        %{name: "beta_metric", value: 3, tags: %{}, timestamp: DateTime.utc_now(), type: :counter}
      ]

      result = PrometheusFormatter.format_prometheus(metrics)

      lines = String.split(result, "\n", trim: true)

      # Find the metric lines (not HELP or TYPE)
      metric_lines =
        Enum.filter(lines, fn line ->
          not String.starts_with?(line, "#") and String.contains?(line, "_metric ")
        end)

      # Should be in alphabetical order
      assert length(metric_lines) == 3
      assert metric_lines |> Enum.at(0) |> String.starts_with?("alpha_metric ")
      assert metric_lines |> Enum.at(1) |> String.starts_with?("beta_metric ")
      assert metric_lines |> Enum.at(2) |> String.starts_with?("zebra_metric ")
    end
  end
end
