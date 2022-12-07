defmodule ControlServer.Seed do
  alias ControlServer.Batteries.Installer
  alias ControlServer.MetalLB

  require Logger

  def seed_from_snapshot(snapshot) do
    :ok = seed_batteries(snapshot)
    :ok = seed_ip_address_pools(snapshot)
  end

  defp seed_batteries(snapshot) do
    {:ok, _} = Installer.install_all(snapshot.batteries)
    :ok
  end

  def seed_ip_address_pools(snapshot) do
    Enum.each(snapshot.ip_address_pools, fn pool ->
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
