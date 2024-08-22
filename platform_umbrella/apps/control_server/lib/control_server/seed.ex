defmodule ControlServer.Seed do
  @moduledoc false
  import CommonCore.SeedArgsConverter

  alias ControlServer.Batteries.Installer
  alias ControlServer.MetalLB
  alias ControlServer.Postgres
  alias ControlServer.Redis
  alias ControlServer.TraditionalServices

  require Logger

  def seed_from_path(path) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> seed_from_summary()
  end

  def seed_from_summary(%{} = summary) do
    :ok = seed_postgres(summary)
    :ok = seed_redis(summary)
    :ok = seed_postgres(summary)
    :ok = seed_ip_address_pools(summary)
    :ok = seed_batteries(summary)
    :ok = seed_traditional_services(summary)
  end

  defp seed_batteries(summary) do
    {:ok, _} =
      summary
      |> Map.get("batteries")
      |> Enum.map(&to_fresh_battery_args/1)
      |> Installer.install_all()

    :ok
  end

  defp seed_postgres(%{} = summary) do
    Logger.debug("Seeding Postgresql clusters")

    summary
    |> Map.get("postgres_clusters")
    |> Enum.map(&to_fresh_args/1)
    |> Enum.each(fn cluster ->
      {:ok, _} = Postgres.find_or_create(cluster)
    end)

    :ok
  end

  defp seed_redis(%{} = summary) do
    Logger.debug("Seeding Redis failover clusters")

    summary
    |> Map.get("redis_instances")
    |> Enum.map(&to_fresh_args/1)
    |> Enum.each(fn redis_instance ->
      {:ok, _} = Redis.find_or_create(redis_instance)
    end)

    :ok
  end

  def seed_ip_address_pools(summary) do
    Logger.debug("Seeding IP Address pools potentially from docker.")

    summary
    |> Map.get("ip_address_pools")
    |> Enum.map(&to_fresh_args/1)
    |> Enum.each(fn pool ->
      case MetalLB.create_ip_address_pool(pool) do
        {:ok, created_pool} ->
          Logger.debug("Created new ip address pool", pool: created_pool)

        res ->
          Logger.debug("IP address creation skipped", pool: pool, result: res)
      end
    end)

    :ok
  end

  def seed_traditional_services(summary) do
    Logger.debug("Seeding traditional services.")

    summary
    |> Map.get("traditional_services")
    |> Enum.map(&to_fresh_args/1)
    |> Enum.each(fn svc -> {:ok, _} = TraditionalServices.find_or_create_service(svc) end)
  end
end
