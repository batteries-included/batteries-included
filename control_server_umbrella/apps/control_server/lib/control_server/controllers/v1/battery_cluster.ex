defmodule ControlServer.Controller.V1.BatteryCluster do
  @moduledoc """
  ControlServer: BatteryCluster CRD.
  """
  use Bonny.Controller

  alias ControlServer.ConfigGenerator
  alias ControlServer.KubeExt
  alias ControlServer.Services

  @scope :cluster
  @names %{
    plural: "batteryclusters",
    singular: "batterycluster",
    kind: "BatteryCluster"
  }

  # @rule {"", ["pods", "configmap"], ["create"]}
  # @rule {"", ["secrets"], ["create"]}

  require Logger

  @doc """
  Handles an `ADDED` event
  """
  @spec add(map()) :: :ok | :error
  @impl Bonny.Controller
  def add(%{} = batterycluster), do: reconcile(batterycluster)

  @doc """
  Handles a `MODIFIED` event
  """
  @spec modify(map()) :: :ok | :error
  @impl Bonny.Controller
  def modify(%{} = batterycluster), do: reconcile(batterycluster)

  @doc """
  Handles a `DELETED` event
  """
  @spec delete(map()) :: :ok | :error
  @impl Bonny.Controller
  def delete(%{} = _batterycluster) do
    :ok
  end

  @spec reconcile(map) :: :ok | :error
  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @impl Bonny.Controller
  def reconcile(%{"metadata" => %{"name" => name}} = _batterycluster) do
    Logger.debug("Starting a reconcile for cluster #{name}")
    base_services = Services.list_base_services()

    configs =
      base_services
      |> Enum.flat_map(fn service -> ConfigGenerator.materialize(service) end)
      |> Enum.sort(fn {a, _av}, {b, _bv} -> a <= b end)

    resources =
      configs
      |> Enum.map(fn {path, r} ->
        Logger.debug("Applying new config to #{path}")
        {:ok, _} = KubeExt.apply(r)
        r
      end)

    Logger.debug("Completed reconcile with #{length(resources)} resources")
    :ok
  end

  @impl Bonny.Controller
  def reconcile(%{} = _batterycluster) do
    :ok
  end
end
