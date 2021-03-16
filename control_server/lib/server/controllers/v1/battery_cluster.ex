defmodule Server.Controller.V1.BatteryCluster do
  @moduledoc """
  Server: BatteryCluster CRD.
  """
  use Bonny.Controller
  @scope :cluster
  @names %{
    plural: "batteryclusters",
    singular: "batterycluster",
    kind: "BatteryCluster",
    shortNames: nil
  }

  # @rule {"", ["pods", "configmap"], ["create"]}
  # @rule {"", ["secrets"], ["create"]}

  require Logger
  alias Server.Services.Prometheus


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
  def reconcile(%{"metadata" => %{"name" => name}} = batterycluster) do
    Logger.debug("Starting a reconcile for cluster #{name}")
    Prometheus.sync(batterycluster)
    :ok
  end

  @impl Bonny.Controller
  def reconcile(%{} = _batterycluster) do
    :ok
  end
end
