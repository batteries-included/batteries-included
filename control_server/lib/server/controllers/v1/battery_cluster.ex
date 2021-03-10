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
    shortNames: []
  }

  # @rule {"", ["pods", "configmap"], ["create"]}
  # @rule {"", ["secrets"], ["create"]}

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
  def delete(%{} = batterycluster) do
    IO.inspect(batterycluster)
    :ok
  end

  @spec reconcile(map) :: :ok | :error
  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @impl Bonny.Controller
  def reconcile(%{"metadata" => %{"name" => name}} = batterycluster) do
    IO.inspect(batterycluster)
    IO.inspect(name)
    :ok
  end

  @impl Bonny.Controller
  def reconcile(%{} = batterycluster) do
    IO.inspect(batterycluster)
    :ok
  end
end
