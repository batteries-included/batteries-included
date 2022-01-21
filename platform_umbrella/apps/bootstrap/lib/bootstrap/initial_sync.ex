defmodule Bootstrap.InitialSync do
  alias KubeExt.ConnectionPool
  alias KubeRawResources.ConfigGenerator
  alias KubeRawResources.Resource

  require Logger

  @default_timeout 90 * 1000
  @app :bootstrap

  def run_sync do
    Logger.debug("Starting sync")

    resources_map =
      %{}
      |> Map.merge(ConfigGenerator.materialize(%{}, :battery))
      |> Map.merge(
        ConfigGenerator.materialize(
          %{"bootstrap.clusters" => [Bootstrap.Database.control_cluster()]},
          :database
        )
      )

    do_apply(false, 5, ConnectionPool.get(Bootstrap.ConnectionPool), resources_map)
    Logger.debug("done sync")
    :ok
  end

  defp timeout do
    @default_timeout
  end

  defp do_apply(true = _fully_successful, retries, _connection, _resource_map) do
    Logger.info("Fully successful with #{retries} retries remaining")
  end

  defp do_apply(false = _fully_successful, 0 = _retries, _connection, _resource_map) do
    Logger.error("Unable to sync the initial resources needed for bootstrap.")
    :err
  end

  defp do_apply(_, retries, connection, resource_map) do
    :timer.sleep(1000 * (5 - retries) + 1)
    # Iterate over every resource in the map.
    # Trying to make sure that everone is really fully successful and the results are expected.
    resource_map
    |> Enum.map(fn {path, resource} ->
      Logger.debug("Pushing #{path}")
      {Resource.apply(connection, resource), path}
    end)
    |> Enum.map(fn {result, path} ->
      apply_result = Resource.ResourceState.ok?(result)
      Logger.info("Initial sync result for #{path} = #{apply_result}")
      {apply_result, path}
    end)
    |> Enum.reduce(true, fn {res, _path}, acc -> acc && res end)
    |> do_apply(
      retries - 1,
      connection,
      resource_map
    )
  end

  defp sync do
    args = []
    opts = [restart: :transient]

    Bootstrap.TaskSupervisor
    |> Task.Supervisor.async(Bootstrap.InitialSync, :run_sync, args, opts)
    |> Task.await(timeout())
  end

  defp load_app do
    Logger.debug("Loading application #{@app}")
    Application.ensure_all_started(@app, :permanent)
  end

  def run do
    Logger.debug("Running")
    load_app()
    Logger.debug("Done starting application")
    sync()
  end
end
