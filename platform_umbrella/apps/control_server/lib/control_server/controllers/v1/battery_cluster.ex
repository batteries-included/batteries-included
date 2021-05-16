defmodule ControlServer.Controller.V1.BatteryCluster do
  @moduledoc """
  ControlServer: BatteryCluster CRD.
  """
  use Bonny.Controller

  alias ControlServer.KubeServices

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
    KubeServices.apply()
    :ok
  end

  @impl Bonny.Controller
  def reconcile(%{} = _batterycluster) do
    :ok
  end
end
