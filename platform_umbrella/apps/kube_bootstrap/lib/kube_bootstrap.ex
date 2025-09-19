defmodule KubeBootstrap do
  @moduledoc """
  Documentation for `KubeBootstrap`.
  """
  alias CommonCore.Resources.RootResourceGenerator, as: RRG
  alias CommonCore.StateSummary

  require Logger

  # This is the list of batteries that are necessary to get control server running.
  # It will finish bootstrapping and running remaining resources
  # See: https://github.com/batteries-included/batteries-included/issues/1790
  # styler:sort
  @allowed_bootstrap_batteries ~w(
    aws_load_balancer_controller
    battery_ca
    battery_core
    cert_manager
    cloudnative_pg
    gateway_api
    istio
    istio_csr
    istio_gateway
    karpenter
    metallb
    victoria_metrics
    vm_agent
  )a

  @spec bootstrap_from_summary(StateSummary.t()) :: :ok | {:error, :retries_exhausted | list()}
  def bootstrap_from_summary(summary) do
    {:ok, conn} = CommonCore.ConnectionPool.get(KubeBootstrap.ConnectionPool, :default)

    {resources, with_control_server} =
      summary
      # Use the given summary to generate the resources
      |> materialize()
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
         {:ok, _} <- KubeBootstrap.Kube.ensure_exists(conn, with_control_server) do
      # Now if we were starting a control server we need to wait for it to be ready
      # before we can consider the bootstrap complete
      if length(with_control_server) == length(resources) do
        Logger.info("No Control Server found to wait for")
      else
        Logger.info("Waiting for Control Server to be ready")
        :ok = KubeBootstrap.ControlServer.wait_for_control_server(conn, summary)
        Logger.info("Control Server is ready")
        Logger.debug("Waiting for MetalLB to be ready")
        # Sometimes metallb's speaker pod can take a while.
        # There are 4 containers and they each take a second.
        # So rather than get un-explained network errors
        # we'll take our time here.
        :ok = KubeBootstrap.MetalLB.wait_for_metallb(conn, summary)
      end

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

  # This filters to only bootstrap-able batteries then delegates to the main resource generator.
  defp materialize(%StateSummary{batteries: batteries} = state) do
    generators = RRG.default_generators()

    batteries
    |> Enum.filter(&(&1.type in @allowed_bootstrap_batteries))
    |> Enum.map(fn %{type: type} = sb ->
      RRG.materialize_system_battery(sb, state, Keyword.fetch!(generators, type))
    end)
    |> Enum.reduce(%{}, &Map.merge/2)
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
    CommonCore.ApiVersionKind.resource_type!(resource) == :stateful_set &&
      CommonCore.Resources.FieldAccessors.name(resource) == "controlserver"
  end
end
