defmodule ControlServer.Seed do
  alias ControlServer.Batteries.Installer
  alias ControlServer.MetalLB
  alias ControlServer.Postgres
  alias ControlServer.Redis

  alias CommonCore.SystemState.StateSummary

  import CommonCore.SeedArgsConverter

  require Logger

  def seed_from_snapshot(%StateSummary{} = summary) do
    :ok = seed_postgres(summary)
    :ok = seed_redis(summary)
    :ok = seed_postgres(summary)
    :ok = seed_ip_address_pools(summary)
    :ok = seed_batteries(summary)
  end

  defp seed_batteries(summary) do
    {:ok, _} =
      summary.batteries
      |> Enum.map(&to_fresh_args/1)
      |> Installer.install_all()

    :ok
  end

  defp seed_postgres(%StateSummary{} = summary) do
    Logger.debug("Seeding Postgresql clusters")

    summary.postgres_clusters
    |> Enum.map(&to_fresh_args/1)
    |> Enum.each(fn cluster ->
      {:ok, _} = Postgres.find_or_create(cluster)
    end)

    :ok
  end

  defp seed_redis(%StateSummary{} = summary) do
    Logger.debug("Seeding Redis failover clusters")

    summary.redis_clusters
    |> Enum.map(&to_fresh_args/1)
    |> Enum.each(fn failover_cluster ->
      {:ok, _} = Redis.find_or_create(failover_cluster)
    end)

    :ok
  end

  def seed_ip_address_pools(summary) do
    Logger.debug("Seeding IP Address pools potentially from docker.")

    summary.ip_address_pools
    |> Enum.map(&to_fresh_args/1)
    |> Enum.each(fn pool ->
      case MetalLB.create_ip_address_pool(pool) do
        {:ok, created_pool} ->
          Logger.debug("Created new ip address pool", pool: created_pool)

        res ->
          Logger.debug("Ip address creation skipped", pool: pool, result: res)
      end
    end)

    :ok
  end
end
