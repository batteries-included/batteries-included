defmodule ControlServerWeb.Resource do
  @moduledoc """
  Helper functions for resources (pods, deployments, stateful sets and services).
  """

  alias KubeServices.KubeState

  defdelegate name(resource), to: K8s.Resource
  defdelegate namespace(resource), to: K8s.Resource
  defdelegate kind(resource), to: K8s.Resource
  defdelegate labels(resource), to: K8s.Resource

  def get_resource!(type, namespace, name) do
    KubeState.get!(type, namespace, name)
  end

  def id(resource), do: String.downcase(kind(resource)) <> namespace(resource) <> name(resource)

  def owned_resources(resource, wanted_type) do
    KubeState.get_owned_resources(wanted_type, resource)
  end

  def events(resource) do
    KubeState.get_events(resource)
  end

  def replicasets(resource) do
    owned_resources(resource, :replicaset)
  end

  def pods_from_replicasets(resource) do
    Enum.flat_map(replicasets(resource), fn rs -> owned_resources(rs, :pod) end)
  end

  def conditions(resource) do
    get_in(resource, ~w|status conditions|) || []
  end

  def status(resource) do
    get_in(resource, ["status"])
  end

  def ports(resource) do
    get_in(resource, ~w|spec ports|) || []
  end

  def container_statuses(resource) do
    container_statuses = get_in(resource, ["status", "containerStatuses"]) || []
    init_container_statuses = get_in(resource, ["status", "initContainerStatuses"]) || []
    Enum.concat(init_container_statuses, container_statuses)
  end
end
