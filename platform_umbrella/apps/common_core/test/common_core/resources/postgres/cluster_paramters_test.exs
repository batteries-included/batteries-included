defmodule CommonCore.Resources.CloudNativePGClusterParamtersTest do
  use ExUnit.Case, async: true

  import CommonCore.Factory

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Resources.CloudNativePGClusterParamters
  alias CommonCore.Util.Memory

  describe "params/1" do
    test "includes all parameter categories" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB), cpu_requested: 4000)
      params = CloudNativePGClusterParamters.params(cluster)

      # Basic params
      assert params["timezone"] == "UTC"
      assert params["autovacuum"] == "on"

      # Memory tuning params
      assert Map.has_key?(params, "shared_buffers")
      assert Map.has_key?(params, "work_mem")
      assert Map.has_key?(params, "maintenance_work_mem")
      assert Map.has_key?(params, "effective_cache_size")

      # WAL params
      assert Map.has_key?(params, "wal_buffers")
      assert params["min_wal_size"] == "1GB"
      assert params["max_wal_size"] == "4GB"
      assert params["checkpoint_completion_target"] == "0.9"

      # Connection params
      assert params["max_connections"] == "200"
      assert Map.has_key?(params, "max_worker_processes")

      # Performance params
      assert params["random_page_cost"] == "1.1"
      assert params["default_statistics_target"] == "100"
      assert params["effective_io_concurrency"] == "200"
    end
  end

  describe "memory_params/1" do
    test "returns empty map when memory_requested is nil" do
      cluster = %Cluster{memory_requested: nil}
      assert CloudNativePGClusterParamters.memory_params(cluster) == %{}
    end

    test "calculates memory parameters for valid cluster" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB))
      params = CloudNativePGClusterParamters.memory_params(cluster)

      assert Map.has_key?(params, "shared_buffers")
      assert Map.has_key?(params, "work_mem")
      assert Map.has_key?(params, "maintenance_work_mem")
      assert Map.has_key?(params, "effective_cache_size")
    end
  end

  describe "shared_buffers_params/1" do
    test "calculates 25% of memory for shared_buffers" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB))
      params = CloudNativePGClusterParamters.shared_buffers_params(cluster)

      # 4GB * 0.25 = 1GB = 1048576kB
      assert params["shared_buffers"] == "1048576kB"
    end

    test "handles small memory allocations" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(512, :MB))
      params = CloudNativePGClusterParamters.shared_buffers_params(cluster)

      # 512MB * 0.25 = 128MB = 131072kB
      assert params["shared_buffers"] == "131072kB"
    end
  end

  describe "work_mem_params/1" do
    test "calculates work_mem based on available memory" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB))
      params = CloudNativePGClusterParamters.work_mem_params(cluster)

      # Formula: (4GB - 1GB) / ((200 + 8) * 3) = 3GB / 624 ≈ 4883kB
      work_mem_value = String.to_integer(String.replace(params["work_mem"], "kB", ""))
      # Above minimum
      assert work_mem_value > 64
      # Reasonable range
      assert work_mem_value < 10_000
    end

    test "enforces minimum work_mem of 64kB" do
      # Use very small memory to trigger minimum
      cluster = build(:postgres, memory_requested: Memory.to_bytes(16, :MB))
      params = CloudNativePGClusterParamters.work_mem_params(cluster)

      assert params["work_mem"] == "64kB"
    end
  end

  describe "maintenance_work_mem_params/1" do
    test "calculates 1/16 of memory for maintenance_work_mem" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB))
      params = CloudNativePGClusterParamters.maintenance_work_mem_params(cluster)

      # 4GB / 16 = 256MB = 262144kB
      assert params["maintenance_work_mem"] == "262144kB"
    end

    test "caps maintenance_work_mem at 2GB" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(64, :GB))
      params = CloudNativePGClusterParamters.maintenance_work_mem_params(cluster)

      # Should be capped at 2GB = 2097152kB
      assert params["maintenance_work_mem"] == "2097152kB"
    end
  end

  describe "effective_cache_size_params/1" do
    test "calculates 75% of memory for effective_cache_size" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB))
      params = CloudNativePGClusterParamters.effective_cache_size_params(cluster)

      # 4GB * 0.75 = 3GB = 3145728kB
      assert params["effective_cache_size"] == "3145728kB"
    end
  end

  describe "wal_params/1" do
    test "includes all WAL parameters" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB), cpu_requested: 4000)
      params = CloudNativePGClusterParamters.wal_params(cluster)

      assert Map.has_key?(params, "wal_buffers")
      assert params["min_wal_size"] == "1GB"
      assert params["max_wal_size"] == "4GB"
      assert params["checkpoint_completion_target"] == "0.9"
    end
  end

  describe "wal_buffers_params/1" do
    test "calculates 3% of shared_buffers for wal_buffers" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB))
      params = CloudNativePGClusterParamters.wal_buffers_params(cluster)

      # shared_buffers = 1GB = 1048576kB
      # wal_buffers = 3% = 31457kB, but capped at 16MB = 16384kB per PostgreSQL spec
      assert params["wal_buffers"] == "16384kB"
    end

    test "caps wal_buffers at 16MB" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(128, :GB))
      params = CloudNativePGClusterParamters.wal_buffers_params(cluster)

      # Should be capped at 16MB = 16384kB
      assert params["wal_buffers"] == "16384kB"
    end

    test "enforces minimum wal_buffers of 32kB" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :MB))
      params = CloudNativePGClusterParamters.wal_buffers_params(cluster)

      assert params["wal_buffers"] == "32kB"
    end
  end

  describe "wal_size_params/1" do
    test "returns larger WAL sizes for clusters with more than 512MB memory" do
      # 8GB memory
      cluster = build(:postgres, memory_requested: Memory.to_bytes(8, :GB), cpu_requested: 4000)
      params = CloudNativePGClusterParamters.wal_size_params(cluster)

      assert params["min_wal_size"] == "1GB"
      assert params["max_wal_size"] == "4GB"
    end

    test "returns smaller WAL sizes for clusters with 512MB or less memory" do
      # 512MB memory
      cluster =
        build(:postgres,
          memory_requested: Memory.to_bytes(512, :MB),
          memory_limits: Memory.to_bytes(512, :MB),
          cpu_requested: 400,
          cpu_limits: 400
        )

      params = CloudNativePGClusterParamters.wal_size_params(cluster)

      assert params["min_wal_size"] == "128MB"
      assert params["max_wal_size"] == "512MB"
    end
  end

  describe "connection_params/1" do
    test "includes max_connections and parallel workers for sufficient CPU" do
      # 4 cores
      cluster = build(:postgres, cpu_requested: 4000, memory_requested: Memory.to_bytes(4, :GB))
      params = CloudNativePGClusterParamters.connection_params(cluster)

      assert params["max_connections"] == "200"
      assert params["max_worker_processes"] == "4"
      assert params["max_parallel_workers_per_gather"] == "2"
      assert params["max_parallel_workers"] == "4"
      assert params["max_parallel_maintenance_workers"] == "2"
    end

    test "only includes max_connections for low CPU" do
      # 0.5 cores - use small preset which has 500 cpu_requested
      cluster = build(:postgres, cpu_requested: 500, memory_requested: Memory.to_bytes(512, :MB))
      params = CloudNativePGClusterParamters.connection_params(cluster)

      assert params["max_connections"] == "100"
      refute Map.has_key?(params, "max_worker_processes")
    end
  end

  describe "parallel_worker_params/1" do
    test "returns empty map for nil cpu_requested" do
      cluster = %Cluster{cpu_requested: nil}
      assert CloudNativePGClusterParamters.parallel_worker_params(cluster) == %{}
    end

    test "returns empty map for low CPU" do
      # 2 cores
      cluster = build(:postgres, cpu_requested: 2000)
      assert CloudNativePGClusterParamters.parallel_worker_params(cluster) == %{}
    end

    test "calculates parallel workers for 8 cores" do
      # 8 cores - use large preset which has 8000 cpu_requested
      cluster =
        build(:postgres,
          cpu_requested: 8000,
          cpu_limits: 8000,
          memory_requested: Memory.to_bytes(8, :GB),
          memory_limits: Memory.to_bytes(8, :GB)
        )

      params = CloudNativePGClusterParamters.parallel_worker_params(cluster)

      assert params["max_worker_processes"] == "8"
      # Capped at 4 for web
      assert params["max_parallel_workers_per_gather"] == "4"
      assert params["max_parallel_workers"] == "8"
      # Capped at 4
      assert params["max_parallel_maintenance_workers"] == "4"
    end

    test "caps workers_per_gather at 4 for web workloads" do
      # 16 cores
      cluster = build(:postgres, cpu_requested: 16_000, memory_requested: Memory.to_bytes(16, :GB))
      params = CloudNativePGClusterParamters.parallel_worker_params(cluster)

      assert params["max_worker_processes"] == "16"
      # Still capped
      assert params["max_parallel_workers_per_gather"] == "4"
      assert params["max_parallel_workers"] == "16"
      # Still capped
      assert params["max_parallel_maintenance_workers"] == "4"
    end
  end

  describe "performance_params/1" do
    test "returns SSD-optimized performance parameters" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(4, :GB), cpu_requested: 4000)
      params = CloudNativePGClusterParamters.performance_params(cluster)

      assert params["random_page_cost"] == "1.1"
      assert params["default_statistics_target"] == "100"
      assert params["effective_io_concurrency"] == "200"
    end
  end

  describe "parameter integration" do
    test "tuning parameters override basic parameters when merged" do
      cluster = build(:postgres, memory_requested: Memory.to_bytes(8, :GB), cpu_requested: 4000)
      params = CloudNativePGClusterParamters.params(cluster)

      # Ensure tuning parameters are present and properly formatted
      assert is_binary(params["shared_buffers"])
      assert String.ends_with?(params["shared_buffers"], "kB")

      assert is_binary(params["work_mem"])
      assert String.ends_with?(params["work_mem"], "kB")

      assert params["random_page_cost"] == "1.1"
      assert params["max_connections"] == "200"
    end

    test "handles edge case cluster configurations gracefully" do
      # Very small cluster that triggers minimum work_mem
      small_cluster =
        build(:postgres,
          memory_requested: Memory.to_bytes(32, :MB),
          # 0.1 cores
          cpu_requested: 100
        )

      params = CloudNativePGClusterParamters.params(small_cluster)

      # Should still have basic parameters
      assert params["timezone"] == "UTC"
      assert params["max_connections"] == "100"

      # Should handle small memory allocation
      assert Map.has_key?(params, "shared_buffers")
      # For 32MB memory, work_mem should be calculated (not minimum)
      assert params["work_mem"] == "75kB"
    end
  end
end
