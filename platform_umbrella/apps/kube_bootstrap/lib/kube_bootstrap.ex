defmodule KubeBootstrap do
  @moduledoc """
  Documentation for `KubeBootstrap`.
  """
  alias CommonCore.StateSummary

  alias CommonCore.Resources.RootResourceGenerator
  require Logger

  @spec bootstrap_from_summary(StateSummary.t()) :: :ok | {:error, :retries_exhausted | list()}
  def bootstrap_from_summary(summary) do
    conn = CommonCore.ConnectionPool.get(KubeBootstrap.ConnectionPool, :default)

    {resources, with_control_server} =
      summary
      # Use the given summary to generate the resources
      |> RootResourceGenerator.materialize()
      |> Map.values()
      # Split the resources into two groups
      # One with the control server the other without
      |> split_resources()

    # Create the first group of resources with no control server
    with {:ok, _} <- KubeBootstrap.Kube.ensure_exists(conn, resources),
         # Wait for the postgres clusters to be ready
         :ok <- KubeBootstrap.Postgres.wait_for_postgres(conn, summary),
         # Create the second group of resources with the control server
         # This allows the user and passwords to be set before trying to boot.
         {:ok, _} <-
           KubeBootstrap.Kube.ensure_exists(conn, with_control_server) do
      Logger.info("Bootstrap complete")
      :ok
    end
  end

  @spec read_summary(binary()) :: {:ok, StateSummary.t()} | File.posix() | Jason.DecodeError.t()
  def read_summary(path) do
    with {:ok, file_contents} <- File.read(path),
         {:ok, decoded_content} <- Jason.decode(file_contents) do
      # Decode everything from string keyed map to struct
      StateSummary.new(decoded_content)
    else
      {:error, _} = error -> error
    end
  end

  defp split_resources(resources) do
    split =
      Enum.group_by(resources, fn res -> control_server?(res) end)

    # We want to ensure that the control server is created last
    before = Map.get(split, false, [])

    # Return both sets however the control server might not even be present
    {before, before ++ Map.get(split, true, [])}
  end

  defp control_server?(resource) do
    CommonCore.ApiVersionKind.resource_type!(resource) == :deployment &&
      CommonCore.Resources.FieldAccessors.name(resource) == "controlserver"
  end
end
