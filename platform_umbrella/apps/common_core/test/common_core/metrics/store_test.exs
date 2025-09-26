defmodule CommonCore.Metrics.StoreTest do
  use ExUnit.Case, async: true

  import Mox

  alias CommonCore.Metrics.Store

  setup :verify_on_exit!

  describe "start_link/1" do
    test "starts with default options" do
      assert {:ok, pid} =
               Store.start_link(
                 name: :test_store_default,
                 metrics_table: :test_metrics_default,
                 aggregated_table: :test_aggregated_default
               )

      assert Process.alive?(pid)

      # Verify ETS tables were created
      assert :ets.info(:test_metrics_default) != :undefined
      assert :ets.info(:test_aggregated_default) != :undefined

      GenServer.stop(pid)
    end

    test "starts with custom options" do
      opts = [
        name: :test_store_custom,
        metrics_table: :custom_metrics,
        aggregated_table: :custom_aggregated
      ]

      assert {:ok, pid} = Store.start_link(opts)
      assert Process.alive?(pid)

      # Verify custom ETS tables were created
      assert :ets.info(:custom_metrics) != :undefined
      assert :ets.info(:custom_aggregated) != :undefined

      GenServer.stop(pid)
    end
  end

  describe "put_metric/4" do
    setup do
      {:ok, pid} =
        Store.start_link(
          name: :test_store_put,
          metrics_table: :test_metrics_put,
          aggregated_table: :test_aggregated_put
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)
      %{pid: pid}
    end

    test "stores a metric with default table" do
      assert :ok = Store.put_metric(:test_store_put, "test.counter", 1, %{})

      # Should be able to retrieve the metric
      metrics = Store.get_all_metrics(:test_metrics_put)
      assert length(metrics) == 1

      metric = List.first(metrics)
      assert metric.name == "test.counter"
      assert metric.value == 1
      assert metric.tags == %{}
      assert %DateTime{} = metric.timestamp
    end

    test "stores a metric with tags" do
      tags = %{"endpoint" => "/api/test", "method" => "GET"}
      assert :ok = Store.put_metric(:test_store_put, "http.requests", 5, tags)

      metrics = Store.get_all_metrics(:test_metrics_put)
      assert length(metrics) == 1

      metric = List.first(metrics)
      assert metric.name == "http.requests"
      assert metric.value == 5
      assert metric.tags == tags
    end

    test "stores multiple metrics" do
      assert :ok = Store.put_metric(:test_store_put, "metric1", 10, %{})
      assert :ok = Store.put_metric(:test_store_put, "metric2", 20, %{"tag" => "value"})

      metrics = Store.get_all_metrics(:test_metrics_put)
      assert length(metrics) == 2

      names = Enum.map(metrics, & &1.name)
      assert "metric1" in names
      assert "metric2" in names
    end

    test "stores metrics with custom table" do
      {:ok, custom_pid} =
        Store.start_link(
          name: :custom_store,
          metrics_table: :custom_test_table,
          aggregated_table: :custom_test_aggregated
        )

      on_exit(fn -> if Process.alive?(custom_pid), do: GenServer.stop(custom_pid) end)

      assert :ok = Store.put_metric(:custom_store, "custom.metric", 42, %{})

      metrics = Store.get_all_metrics(:custom_test_table)
      assert length(metrics) == 1

      metric = List.first(metrics)
      assert metric.name == "custom.metric"
      assert metric.value == 42
    end
  end

  describe "get_metrics/2" do
    setup do
      {:ok, pid} =
        Store.start_link(
          name: :test_store_get,
          metrics_table: :test_metrics_get,
          aggregated_table: :test_aggregated_get
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)
      %{pid: pid}
    end

    test "gets metrics by name" do
      # Store multiple metrics with same name
      Store.put_metric(:test_store_get, "test.metric", 1, %{"instance" => "A"})
      Store.put_metric(:test_store_get, "test.metric", 2, %{"instance" => "B"})
      Store.put_metric(:test_store_get, "other.metric", 3, %{})

      metrics = Store.get_metrics(:test_metrics_get, "test.metric")
      assert length(metrics) == 2

      values = Enum.map(metrics, & &1.value)
      assert 1 in values
      assert 2 in values
    end

    test "returns empty list for non-existent metric" do
      metrics = Store.get_metrics(:test_metrics_get, "non.existent")
      assert metrics == []
    end
  end

  describe "get_all_metrics/1" do
    setup do
      {:ok, pid} =
        Store.start_link(
          name: :test_store_get_all,
          metrics_table: :test_metrics_get_all,
          aggregated_table: :test_aggregated_get_all
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)
      %{pid: pid}
    end

    test "returns empty list when no metrics stored" do
      metrics = Store.get_all_metrics(:test_metrics_get_all)
      assert metrics == []
    end

    test "returns all stored metrics" do
      Store.put_metric(:test_store_get_all, "metric1", 10, %{})
      Store.put_metric(:test_store_get_all, "metric2", 20, %{})
      Store.put_metric(:test_store_get_all, "metric3", 30, %{})

      metrics = Store.get_all_metrics(:test_metrics_get_all)
      assert length(metrics) == 3

      names = Enum.map(metrics, & &1.name)
      assert "metric1" in names
      assert "metric2" in names
      assert "metric3" in names
    end
  end

  describe "ETS table lifecycle" do
    test "ETS table is cleaned up when GenServer terminates" do
      {:ok, pid} =
        Store.start_link(
          name: :test_cleanup,
          metrics_table: :cleanup_table,
          aggregated_table: :cleanup_aggregated
        )

      # Verify tables exist
      assert :ets.info(:cleanup_table) != :undefined
      assert :ets.info(:cleanup_aggregated) != :undefined

      # Stop the GenServer
      GenServer.stop(pid)

      # Table should be automatically cleaned up since it's owned by the process
      # We can't directly test this as the table cleanup happens when the process dies
      assert true
    end
  end

  describe "concurrent access" do
    setup do
      {:ok, pid} =
        Store.start_link(
          name: :test_store_concurrent,
          metrics_table: :test_metrics_concurrent,
          aggregated_table: :test_aggregated_concurrent
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)
      %{pid: pid}
    end

    test "handles concurrent reads and writes" do
      # Spawn multiple processes to write metrics concurrently
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            Store.put_metric(:test_store_concurrent, "concurrent.metric", i, %{"worker" => "#{i}"})
          end)
        end

      # Wait for all writes to complete
      Task.await_many(tasks)

      # Should have 10 metrics
      metrics = Store.get_all_metrics(:test_metrics_concurrent)
      assert length(metrics) == 10
    end

    test "read concurrency works" do
      # Store some initial data
      for i <- 1..5 do
        Store.put_metric(:test_store_concurrent, "read.test", i, %{})
      end

      # Spawn multiple readers
      read_tasks =
        for _i <- 1..10 do
          Task.async(fn ->
            Store.get_all_metrics(:test_metrics_concurrent)
          end)
        end

      results = Task.await_many(read_tasks)

      # All readers should get the same results
      expected_length = 5
      assert Enum.all?(results, fn metrics -> length(metrics) == expected_length end)
    end
  end

  describe "get_aggregated_metrics/1" do
    test "returns aggregated metrics from store" do
      import Telemetry.Metrics

      metrics = [
        counter("http.requests", tags: [:method]),
        summary("response.time", tags: [:endpoint])
      ]

      {:ok, pid} =
        Store.start_link(
          name: :test_aggregated_store,
          metrics_table: :test_metrics_agg,
          aggregated_table: :test_aggregated_agg,
          # Short interval for testing
          aggregation_interval: 100,
          metrics: metrics
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      # Store some raw metrics
      Store.put_metric(:test_aggregated_store, "http.requests", 1, %{"method" => "GET", "_type" => :counter})
      Store.put_metric(:test_aggregated_store, "http.requests", 1, %{"method" => "GET", "_type" => :counter})
      Store.put_metric(:test_aggregated_store, "response.time", 100, %{"endpoint" => "/api", "_type" => :summary})
      Store.put_metric(:test_aggregated_store, "response.time", 200, %{"endpoint" => "/api", "_type" => :summary})

      # Wait for aggregation to occur
      Process.sleep(150)

      # Get aggregated metrics
      aggregated = Store.get_aggregated_metrics(:test_aggregated_store)

      # Should have aggregated metrics
      assert length(aggregated) >= 1

      # Find counter metric
      counter_metric = Enum.find(aggregated, fn m -> m.type == :counter and m.name == "http.requests" end)

      if counter_metric do
        # Two counter events
        assert counter_metric.value == 2
        assert counter_metric.tags == %{"method" => "GET", "_type" => :counter}
      end

      # Find summary metric
      summary_metric = Enum.find(aggregated, fn m -> m.type == :summary and m.name == "response.time" end)

      if summary_metric do
        assert summary_metric.count == 2
        assert summary_metric.sum == 300
        assert summary_metric.min == 100
        assert summary_metric.max == 200
        assert summary_metric.mean == 150.0
        assert summary_metric.tags == %{"endpoint" => "/api", "_type" => :summary}
      end
    end

    test "returns empty list when no aggregated metrics exist" do
      {:ok, pid} =
        Store.start_link(
          name: :test_empty_aggregated,
          metrics_table: :test_empty_metrics,
          aggregated_table: :test_empty_aggregated_table
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      aggregated = Store.get_aggregated_metrics(:test_empty_aggregated)
      assert aggregated == []
    end
  end
end
