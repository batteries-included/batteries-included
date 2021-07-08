defmodule KubeController.V1.BatteryCluster do
  @moduledoc """
  ControlServer: BatteryCluster CRD.
  """
  use Bonny.Controller

  require Logger

  @scope :cluster
  @names %{
    plural: "batteryclusters",
    singular: "batterycluster",
    kind: "BatteryCluster"
  }

  @rule {"",
         ["secrets", "pods", "configmap", "deployment", "serviceaccounts", "service", "events"],
         ["*"]}
  @rule {"apiextensions.k8s.io", ["customresourcedefinitions"], ["*"]}
  @rule {"apps", ["deployment", "statefulsets"], ["*"]}
  @rule {"batch", ["job"], ["*"]}
  @rule {"rbac.authorization.k8s.io", ["clusterroles", "clusterrolebindings"], ["*"]}

  @additional_printer_columns [
    %{
      name: "subscription",
      type: "string",
      description: "subscription",
      JSONPath: ".spec.subscription"
    },
    %{
      name: "clustertype",
      type: "string",
      description: "cluster type",
      JSONPath: ".spec.clustertype"
    }
  ]

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
