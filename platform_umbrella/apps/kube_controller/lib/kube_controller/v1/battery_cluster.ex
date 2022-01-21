defmodule KubeController.V1.BatteryCluster do
  @moduledoc """
  ControlServer: BatteryCluster CRD.
  """
  use Bella.Controller

  require Logger

  @doc """
  Handles an `ADDED` event
  """
  @spec add(map()) :: :ok | :error
  @impl Bella.Controller
  def add(%{} = batterycluster), do: reconcile(batterycluster)

  @doc """
  Handles a `MODIFIED` event
  """
  @spec modify(map()) :: :ok | :error
  @impl Bella.Controller
  def modify(%{} = batterycluster), do: reconcile(batterycluster)

  @doc """
  Handles a `DELETED` event
  """
  @spec delete(map()) :: :ok | :error
  @impl Bella.Controller
  def delete(%{} = _batterycluster) do
    :ok
  end

  @spec reconcile(map) :: :ok | :error
  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @impl Bella.Controller
  def reconcile(%{"metadata" => %{"name" => name}} = _batterycluster) do
    Logger.debug("Starting a reconcile for cluster #{name}")
    KubeServices.apply()
    :ok
  end

  @impl Bella.Controller
  def reconcile(%{} = _batterycluster) do
    :ok
  end

  @impl Bella.Controller
  def operation do
    K8s.Operation.build(:list, "v1", "batteryclusters.batteriesincl.com",
      namespace: "battery-core"
    )
  end
end
