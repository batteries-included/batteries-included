defmodule CommonCore.Resources.FieldAccessors do
  @moduledoc """
  Provides accessor functions for common fields in Kubernetes resources.
  """

  defdelegate name(resource), to: K8s.Resource
  defdelegate namespace(resource), to: K8s.Resource
  defdelegate kind(resource), to: K8s.Resource
  defdelegate labels(resource), to: K8s.Resource

  def uid(resource) do
    get_in(resource, ~w(metadata uid))
  end

  def conditions(resource) do
    get_in(resource, ~w|status conditions|) || []
  end

  def creation_timestamp(resource) do
    get_in(resource, ~w(metadata creationTimestamp))
  end

  def status(resource) do
    Map.get(resource, "status", %{})
  end

  def ports(resource) do
    get_in(resource, ~w|spec ports|) || []
  end

  def phase(resource) do
    get_in(resource, ~w(status phase))
  end

  def replicas(resource) do
    get_in(resource, ~w(spec replicas))
  end

  def available_replicas(resource) do
    get_in(resource, ~w(status availableReplicas))
  end

  def labeled_owner(resource) do
    resource |> labels() |> Map.get("battery/owner", nil)
  end

  def container_statuses(resource) do
    container_statuses = get_in(resource, ["status", "containerStatuses"]) || []
    init_container_statuses = get_in(resource, ["status", "initContainerStatuses"]) || []
    Enum.concat(init_container_statuses, container_statuses)
  end
end
