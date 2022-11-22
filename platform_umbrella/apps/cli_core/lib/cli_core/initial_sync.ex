defmodule CLICore.InitialSync do
  alias KubeExt.ApplyResource
  require Logger

  @num_retries 10

  defp do_apply(%{} = _resource_map, 0 = _retries, _connection) do
    Logger.error("Unable to sync the initial resources needed for bootstrap.")
    :err
  end

  defp do_apply(%{} = resource_map, retries, connection) do
    if apply_reduce_result(resource_map, connection) do
      {:ok, retries: retries}
    else
      :timer.sleep(1000 * (@num_retries - retries + 1))
      # Now retry if this isn't fully successful.
      do_apply(resource_map, retries - 1, connection)
    end
  end

  defp apply_reduce_result(resource_map, connection) do
    # Iterate over every resource in the map.
    # Trying to make sure that everone is really fully successful and the results are expected.
    resource_map
    |> Enum.map(fn {path, resource} ->
      Logger.debug("Pushing #{inspect(path)}")
      {ApplyResource.apply(connection, resource), path}
    end)
    |> Enum.map(fn {result, path} ->
      apply_result = ApplyResource.ResourceState.ok?(result)
      Logger.info("Initial sync result for #{path} = #{apply_result}")
      apply_result
    end)
    |> Enum.reduce(true, fn res, acc -> acc && res end)
  end

  def sync do
    KubeExt.cluster_type()
    |> KubeExt.SystemState.SeedState.seed()
    |> sync()
  end

  def sync(state_summary) do
    state_summary
    |> KubeResources.ConfigGenerator.materialize()
    |> do_apply(@num_retries, KubeExt.ConnectionPool.get())
  end
end
