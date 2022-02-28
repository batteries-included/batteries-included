defmodule Bootstrap.InitialSync do
  alias Bootstrap.ServiceConfigs
  alias KubeExt.ConnectionPool
  alias KubeRawResources.ConfigGenerator
  alias KubeRawResources.Resource

  require Logger

  @default_timeout 90 * 1000

  defp gen_for_service_type(service_type) do
    service_type
    |> ConfigGenerator.materialize()
    |> Enum.map(fn {key, value} -> {Path.join("/#{Atom.to_string(service_type)}", key), value} end)
    |> Enum.into(%{})
  end

  defp timeout do
    @default_timeout
  end

  defp do_apply(%{} = _resource_map, true = _fully_successful, retries, _connection) do
    Logger.info("Fully successful with #{retries} retries remaining")
    :ok
  end

  defp do_apply(%{} = _resource_map, false = _fully_successful, 0 = _retries, _connection) do
    Logger.error("Unable to sync the initial resources needed for bootstrap.")
    :err
  end

  defp do_apply(%{} = resource_map, false = _fully_successful, retries, connection) do
    :timer.sleep(1000 * (5 - retries) + 1)

    # Iterate over every resource in the map.
    # Trying to make sure that everone is really fully successful and the results are expected.
    was_success =
      resource_map
      |> Enum.map(fn {path, resource} ->
        Logger.debug("Pushing #{inspect(path)}")
        {Resource.apply(connection, resource), path}
      end)
      |> Enum.map(fn {result, path} ->
        apply_result = Resource.ResourceState.ok?(result)
        Logger.info("Initial sync result for #{path} = #{apply_result}")
        {apply_result, path}
      end)
      |> Enum.reduce(true, fn {res, _path}, acc -> acc && res end)

    # Now retry if this isn't fully successful.
    do_apply(
      resource_map,
      was_success,
      retries - 1,
      connection
    )
  end

  def run_sync do
    Logger.debug("Starting sync")

    ServiceConfigs.default_services()
    |> Enum.map(&gen_for_service_type/1)
    |> Enum.reduce(%{}, fn r_map, acc -> Map.merge(acc, r_map) end)
    |> Map.delete("/battery/cluster_role_binding")
    |> Map.delete("/istio/gateway")
    |> do_apply(false, 5, ConnectionPool.get(Bootstrap.ConnectionPool))

    Logger.debug("done sync")
    :ok
  end

  def sync do
    args = []
    opts = [restart: :transient]

    Bootstrap.TaskSupervisor
    |> Task.Supervisor.async(Bootstrap.InitialSync, :run_sync, args, opts)
    |> Task.await(timeout())
  end
end
