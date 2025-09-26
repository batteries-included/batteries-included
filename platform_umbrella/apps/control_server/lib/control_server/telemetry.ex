defmodule ControlServer.Telemetry do
  @moduledoc false
  use Supervisor

  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      {CommonCore.Metrics.Store,
       name: ControlServer.MetricsStore,
       metrics_table: :control_server_metrics,
       aggregated_table: :control_server_metrics_aggregated,
       metrics: metrics()},
      {CommonCore.Metrics.Reporter,
       name: ControlServer.MetricsReporter, store_target: ControlServer.MetricsStore, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Database Metrics
      summary("control_server.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("control_server.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("control_server.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("control_server.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("control_server.repo.query.idle_time",
        unit: {:native, :millisecond},
        description: "The time the connection spent waiting before being checked out for the query"
      )
    ]
  end

  defp periodic_measurements do
    []
  end
end
