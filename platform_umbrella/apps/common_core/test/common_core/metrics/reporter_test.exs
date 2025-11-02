defmodule CommonCore.Metrics.ReporterTest do
  use ExUnit.Case, async: true

  import Mox
  import Telemetry.Metrics

  alias CommonCore.Metrics.MockStore
  alias CommonCore.Metrics.Reporter

  setup :verify_on_exit!

  describe "initialization" do
    test "starts with basic configuration" do
      metrics = [
        counter("test.events.count"),
        summary("test.events.duration")
      ]

      assert {:ok, pid} =
               Reporter.start_link(
                 name: :test_reporter_default,
                 metrics: metrics,
                 store_module: MockStore
               )

      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "starts with custom store table" do
      metrics = [counter("custom.events.count")]

      assert {:ok, pid} =
               Reporter.start_link(
                 name: :test_reporter_custom,
                 metrics: metrics,
                 store_module: MockStore,
                 store_table: :custom_metrics
               )

      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "telemetry event handling" do
    setup do
      metrics = [
        counter("test.web.request.count", tags: [:route]),
        summary("test.web.request.duration", tags: [:route]),
        counter("test.custom.events.count")
      ]

      {:ok, pid} =
        Reporter.start_link(
          name: :test_reporter_events,
          metrics: metrics,
          store_module: MockStore
        )

      Mox.allow(MockStore, self(), pid)

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      %{pid: pid, metrics: metrics}
    end

    test "handles counter metrics", %{metrics: _metrics} do
      expect(MockStore, :put_metric, fn table, name, value, tags ->
        assert table == :metrics_store
        assert name == "test.web.request.count"
        assert value == 1
        assert tags == %{"route" => "/api/test", "_type" => :counter}
        :ok
      end)

      :telemetry.execute(
        [:test, :web, :request],
        %{count: 1, duration: 1000},
        %{route: "/api/test"}
      )
    end

    test "handles summary metrics", %{metrics: _metrics} do
      expect(MockStore, :put_metric, fn table, name, value, tags ->
        assert table == :metrics_store
        assert name == "test.web.request.duration"
        assert value == 1000
        assert tags == %{"route" => "/api/test", "_type" => :summary}
        :ok
      end)

      :telemetry.execute(
        [:test, :web, :request],
        %{count: 1, duration: 1000},
        %{route: "/api/test"}
      )
    end

    test "handles metrics without tags", %{metrics: _metrics} do
      expect(MockStore, :put_metric, fn table, name, value, tags ->
        assert table == :metrics_store
        assert name == "test.custom.events.count"
        assert value == 5
        assert tags == %{"_type" => :counter}
        :ok
      end)

      :telemetry.execute(
        [:test, :custom, :events],
        %{count: 5},
        %{some_metadata: "ignored"}
      )
    end

    test "ignores events with missing measurements" do
      # Don't expect any calls to MockStore since measurement is missing
      # No expectations set since we expect 0 calls

      :telemetry.execute(
        [:test, :web, :request],
        # count and duration are missing
        %{other_measurement: 1000},
        %{route: "/api/test"}
      )
    end

    test "handles events with measurement functions" do
      measurement_fn = fn measurements -> Map.get(measurements, :total_time, 0) end

      metrics = [
        summary("db.query.time",
          event_name: [:db, :query],
          measurement: measurement_fn
        )
      ]

      {:ok, pid} =
        Reporter.start_link(
          name: :test_reporter_measure_func,
          metrics: metrics,
          store_module: MockStore
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      expect(MockStore, :put_metric, fn table, name, value, tags ->
        assert table == :metrics_store
        assert name == "db.query.time"
        assert value == 150
        assert tags == %{"_type" => :summary}
        :ok
      end)

      :telemetry.execute(
        [:db, :query],
        %{decode_time: 50, query_time: 100, total_time: 150},
        %{}
      )
    end

    test "applies keep functions" do
      keep_fn = fn _measurements, metadata -> metadata[:status] == :ok end

      metrics = [
        counter("http.requests.count",
          tags: [:status],
          keep: keep_fn
        )
      ]

      {:ok, pid} =
        Reporter.start_link(
          name: :test_reporter_keep,
          metrics: metrics,
          store_module: MockStore
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      # Should store metric when keep function returns true
      expect(MockStore, :put_metric, fn table, name, value, tags ->
        assert table == :metrics_store
        assert name == "http.requests.count"
        assert value == 1
        assert tags == %{"status" => "ok", "_type" => :counter}
        :ok
      end)

      :telemetry.execute(
        [:http, :requests],
        %{count: 1},
        %{status: :ok}
      )

      # Should not store metric when keep function returns false
      # No expectations set since we expect 0 calls

      :telemetry.execute(
        [:http, :requests],
        %{count: 1},
        %{status: :error}
      )
    end
  end

  describe "handler lifecycle" do
    test "attaches and detaches handlers properly" do
      metrics = [
        counter("lifecycle.test.events.count")
      ]

      {:ok, pid} =
        Reporter.start_link(
          name: :test_reporter_lifecycle,
          metrics: metrics,
          store_module: MockStore
        )

      # Verify handler is attached by checking it can receive events
      expect(MockStore, :put_metric, fn _, _, _, _ -> :ok end)

      :telemetry.execute([:lifecycle, :test, :events], %{count: 1}, %{})

      # Stop the reporter
      GenServer.stop(pid)

      # After stopping, handler should be detached and events ignored
      # No expectations set since we expect 0 calls after detach

      :telemetry.execute([:lifecycle, :test, :events], %{count: 1}, %{})
    end
  end

  describe "error handling" do
    test "handles store errors gracefully" do
      metrics = [counter("error.test.events.count")]

      {:ok, pid} =
        Reporter.start_link(
          name: :test_reporter_errors,
          metrics: metrics,
          store_module: MockStore
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      # Mock store to raise an error
      expect(MockStore, :put_metric, fn _, _, _, _ ->
        raise "Storage error"
      end)

      # Event should not crash the reporter
      :telemetry.execute([:error, :test, :events], %{count: 1}, %{})

      # Reporter should still be alive
      assert Process.alive?(pid)
    end

    test "continues processing after handler errors" do
      metrics = [
        counter("error.first.events.count"),
        counter("error.second.events.count")
      ]

      {:ok, pid} =
        Reporter.start_link(
          name: :test_reporter_continue,
          metrics: metrics,
          store_module: MockStore
        )

      on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)

      # First call fails, second succeeds
      expect(MockStore, :put_metric, fn _, name, _, _ ->
        if String.contains?(name, "first") do
          raise "First storage error"
        else
          :ok
        end
      end)

      expect(MockStore, :put_metric, fn _, name, _, _ ->
        assert String.contains?(name, "second")
        :ok
      end)

      # Both events should be processed despite first one failing
      :telemetry.execute([:error, :first, :events], %{count: 1}, %{})
      :telemetry.execute([:error, :second, :events], %{count: 1}, %{})
    end
  end
end
