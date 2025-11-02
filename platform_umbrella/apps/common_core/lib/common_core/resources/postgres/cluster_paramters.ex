defmodule CommonCore.Resources.CloudNativePGClusterParamters do
  @moduledoc false
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory

  def params(%Cluster{} = cluster) do
    [
      Task.async(fn -> basic_params(cluster) end),
      Task.async(fn -> autoexplain_params(cluster) end),
      Task.async(fn -> ferretdb_params(cluster) end),

      # Put tuned params here so they will be the last ones applied
      Task.async(fn -> memory_params(cluster) end),
      Task.async(fn -> wal_params(cluster) end),
      Task.async(fn -> connection_params(cluster) end),
      Task.async(fn -> performance_params(cluster) end)
    ]
    |> Task.await_many(5_000)
    |> Enum.reduce(%{}, fn map, acc -> Map.merge(acc, map) end)
  end

  def basic_params(%Cluster{} = _cluster) do
    %{
      "timezone" => "UTC",
      # Autovacuum
      "autovacuum" => "on"
    }
  end

  def autoexplain_params(%Cluster{} = _cluster) do
    %{
      # Stats for the dashboards
      "pg_stat_statements.max" => "10000",
      "pg_stat_statements.track" => "all",
      "pg_stat_statements.track_utility" => "false",

      # Auto explain long running queries.
      "auto_explain.log_min_duration" => "700ms",
      "auto_explain.log_analyze" => "true",
      "auto_explain.log_buffers" => "true",
      "auto_explain.log_timing" => "true",
      "auto_explain.sample_rate" => "0.1",
      "pgaudit.log" => "role, ddl, misc_set",
      "pgaudit.log_catalog" => "off"
    }
  end

  def ferretdb_params(%Cluster{} = _cluster) do
    %{
      # set up ferret / docdb
      "cron.database_name" => "postgres",
      "cron.host" => "",
      "documentdb.enableCompact" => "true",
      "documentdb.enableLetAndCollationForQueryMatch" => "true",
      "documentdb.enableNowSystemVariable" => "true",
      "documentdb.enableSortbyIdPushDownToPrimaryKey" => "true",
      "documentdb.enableSchemaValidation" => "true",
      "documentdb.enableBypassDocumentValidation" => "true",
      "documentdb.enableUserCrud" => "true",
      "documentdb.maxUserLimit" => "100"
    }
  end

  @doc """
  Memory-related parameters optimized for web database workloads.
  Based on pgtune.leopard.in.ua algorithm.
  """
  def memory_params(%Cluster{} = cluster) do
    if get_effective_memory(cluster) == nil do
      %{}
    else
      %{}
      |> Map.merge(shared_buffers_params(cluster))
      |> Map.merge(work_mem_params(cluster))
      |> Map.merge(maintenance_work_mem_params(cluster))
      |> Map.merge(effective_cache_size_params(cluster))
    end
  end

  @doc """
  Calculate shared_buffers parameter.
  For web applications, set to 25% of available memory.
  https://www.postgresql.org/docs/17/runtime-config-resource.html#GUC-SHARED-BUFFERS
  """
  def shared_buffers_params(%Cluster{} = cluster) do
    memory_bytes = get_effective_memory(cluster)
    shared_buffers_kb = div(memory_bytes, 1024 * 4)
    %{"shared_buffers" => "#{shared_buffers_kb}kB"}
  end

  @doc """
  Calculate work_mem parameter.
  Formula: (RAM - shared_buffers) / ((max_connections + max_worker_processes) * 3)
  https://www.postgresql.org/docs/17/runtime-config-resource.html#GUC-WORK-MEM
  """
  def work_mem_params(%Cluster{} = cluster) do
    memory_bytes = get_effective_memory(cluster)
    shared_buffers_bytes = div(memory_bytes, 4)
    # Default for web workload
    max_connections = calculate_max_connections(cluster)
    max_worker_processes = calculate_max_worker_processes(cluster)

    work_mem_kb =
      div(
        memory_bytes - shared_buffers_bytes,
        1024 * (max_connections + max_worker_processes) * 3
      )

    # Enforce minimum 64kB - if calculated value is less, use 64kB
    work_mem_kb = if work_mem_kb < 64, do: 64, else: work_mem_kb

    %{"work_mem" => "#{work_mem_kb}kB"}
  end

  @doc """
  Calculate maintenance_work_mem parameter.
  For web applications, set to 1/16 of available memory, capped at 2GB.
  https://www.postgresql.org/docs/17/runtime-config-resource.html#GUC-MAINTENANCE-WORK-MEM
  """
  def maintenance_work_mem_params(%Cluster{} = cluster) do
    memory_bytes = get_effective_memory(cluster)
    maintenance_work_mem_kb = div(memory_bytes, 1024 * 16)
    # Cap at 2GB = 2,097,152 kB
    maintenance_work_mem_kb = min(maintenance_work_mem_kb, 2_097_152)

    %{"maintenance_work_mem" => "#{maintenance_work_mem_kb}kB"}
  end

  @doc """
  Calculate effective_cache_size parameter.
  For web applications, set to 75% of available memory.
  https://www.postgresql.org/docs/17/runtime-config-query.html#GUC-EFFECTIVE-CACHE-SIZE
  """
  def effective_cache_size_params(%Cluster{} = cluster) do
    memory_bytes = get_effective_memory(cluster)
    effective_cache_size_kb = div(memory_bytes * 3, 1024 * 4)
    %{"effective_cache_size" => "#{effective_cache_size_kb}kB"}
  end

  @doc """
  WAL (Write-Ahead Log) tuning parameters for SSD storage.
  https://www.postgresql.org/docs/17/runtime-config-wal.html
  """
  def wal_params(%Cluster{} = cluster) do
    %{}
    |> Map.merge(wal_buffers_params(cluster))
    |> Map.merge(wal_size_params(cluster))
    |> Map.merge(checkpoint_params(cluster))
  end

  @doc """
  Calculate wal_buffers parameter.
  Set to 3% of shared_buffers, up to maximum of 16MB.
  https://www.postgresql.org/docs/17/runtime-config-wal.html#GUC-WAL-BUFFERS
  """
  def wal_buffers_params(%Cluster{} = cluster) do
    memory_bytes = get_effective_memory(cluster)
    shared_buffers_kb = div(memory_bytes, 1024 * 4)
    wal_buffers_kb = div(shared_buffers_kb * 3, 100)
    # 16MB
    max_wal_buffer_kb = 16 * 1024

    wal_buffers_kb = min(wal_buffers_kb, max_wal_buffer_kb)
    # Minimum 32kB
    wal_buffers_kb = max(wal_buffers_kb, 32)

    %{"wal_buffers" => "#{wal_buffers_kb}kB"}
  end

  @doc """
  WAL file sizing parameters optimized for web workloads on SSD.
  For clusters with 512MB or less memory, use smaller WAL sizes.
  https://www.postgresql.org/docs/17/runtime-config-wal.html#GUC-MIN-WAL-SIZE
  https://www.postgresql.org/docs/17/runtime-config-wal.html#GUC-MAX-WAL-SIZE
  """
  def wal_size_params(%Cluster{} = cluster) do
    memory = get_effective_memory(cluster)

    if memory && memory <= Memory.to_bytes(512, :MB) do
      %{
        "min_wal_size" => "128MB",
        "max_wal_size" => "512MB"
      }
    else
      %{
        "min_wal_size" => "1GB",
        "max_wal_size" => "4GB"
      }
    end
  end

  @doc """
  Checkpoint configuration optimized for performance.
  https://www.postgresql.org/docs/17/runtime-config-wal.html#GUC-CHECKPOINT-COMPLETION-TARGET
  """
  def checkpoint_params(%Cluster{}) do
    %{"checkpoint_completion_target" => "0.9"}
  end

  @doc """
  Connection and parallel worker parameters based on CPU resources.
  https://www.postgresql.org/docs/17/runtime-config-resource.html
  """
  def connection_params(%Cluster{} = cluster) do
    %{}
    |> Map.merge(max_connections_params(cluster))
    |> Map.merge(parallel_worker_params(cluster))
  end

  @doc """
  Maximum connections optimized for web workloads.
  https://www.postgresql.org/docs/17/runtime-config-connection.html#GUC-MAX-CONNECTIONS
  """
  def max_connections_params(%Cluster{} = cluster) do
    max_connections = calculate_max_connections(cluster)
    %{"max_connections" => to_string(max_connections)}
  end

  @doc """
  Parallel worker configuration based on CPU requests.
  https://www.postgresql.org/docs/17/runtime-config-resource.html#GUC-MAX-WORKER-PROCESSES
  https://www.postgresql.org/docs/17/runtime-config-resource.html#GUC-MAX-PARALLEL-WORKERS-PER-GATHER
  https://www.postgresql.org/docs/17/runtime-config-resource.html#GUC-MAX-PARALLEL-WORKERS
  https://www.postgresql.org/docs/17/runtime-config-resource.html#GUC-MAX-PARALLEL-MAINTENANCE-WORKERS
  """
  def parallel_worker_params(%Cluster{} = cluster) do
    cpu_millis = get_effective_cpu(cluster)

    case cpu_millis do
      nil ->
        %{}

      _ when cpu_millis >= 4000 ->
        cpu_cores = div(cpu_millis, 1000)

        max_workers = cpu_cores
        # Max 4 for web workloads
        workers_per_gather = min(div(cpu_cores, 2), 4)
        maintenance_workers = min(div(cpu_cores, 2), 4)

        %{
          "max_worker_processes" => to_string(max_workers),
          "max_parallel_workers_per_gather" => to_string(workers_per_gather),
          "max_parallel_workers" => to_string(max_workers),
          "max_parallel_maintenance_workers" => to_string(maintenance_workers)
        }

      _ ->
        %{}
    end
  end

  @doc """
  Performance tuning parameters optimized for SSD storage.
  """
  def performance_params(%Cluster{} = cluster) do
    %{}
    |> Map.merge(io_cost_params(cluster))
    |> Map.merge(statistics_params(cluster))
    |> Map.merge(io_concurrency_params(cluster))
  end

  @doc """
  Random page cost optimized for SSD storage.
  https://www.postgresql.org/docs/17/runtime-config-query.html#GUC-RANDOM-PAGE-COST
  """
  def io_cost_params(%Cluster{}) do
    # SSD optimized
    %{"random_page_cost" => "1.1"}
  end

  @doc """
  Statistics target for query planner optimization.
  https://www.postgresql.org/docs/17/runtime-config-query.html#GUC-DEFAULT-STATISTICS-TARGET
  """
  def statistics_params(%Cluster{}) do
    # Default for web workloads
    %{"default_statistics_target" => "100"}
  end

  @doc """
  IO concurrency optimized for SSD storage on Linux.
  https://www.postgresql.org/docs/17/runtime-config-resource.html#GUC-EFFECTIVE-IO-CONCURRENCY
  """
  def io_concurrency_params(%Cluster{}) do
    # SSD optimized
    %{"effective_io_concurrency" => "200"}
  end

  # Helper function to calculate max worker processes
  defp calculate_max_worker_processes(%Cluster{} = cluster) do
    cpu_millis = get_effective_cpu(cluster)

    if cpu_millis == nil do
      8
    else
      max(div(cpu_millis, 1000), 8)
    end
  end

  defp calculate_max_connections(%Cluster{} = cluster) do
    memory = get_effective_memory(cluster)

    if memory && memory <= Memory.to_bytes(512, :MB) do
      100
    else
      200
    end
  end

  # Helper functions to get the effective value between request and limit
  # Prioritize request when both are available, fallback to limit when request is nil
  defp get_effective_memory(%Cluster{memory_requested: req, memory_limits: lim}) do
    case {req, lim} do
      {nil, nil} -> nil
      {nil, limit} -> limit
      {request, _limit} -> request
    end
  end

  defp get_effective_cpu(%Cluster{cpu_requested: req, cpu_limits: lim}) do
    case {req, lim} do
      {nil, nil} -> nil
      {nil, limit} -> limit
      {request, _limit} -> request
    end
  end
end
