defmodule CommonCore.Resources.FieldAccessors do
  @moduledoc """
  Provides accessor functions for common fields in Kubernetes resources.
  """

  defdelegate name(resource), to: K8s.Resource
  defdelegate namespace(resource), to: K8s.Resource
  defdelegate kind(resource), to: K8s.Resource
  defdelegate labels(resource), to: K8s.Resource
  defdelegate annotations(resource), to: K8s.Resource
  defdelegate metadata(resource), to: K8s.Resource
  defdelegate api_version(resource), to: K8s.Resource

  def uid(resource) do
    resource |> metadata() |> Map.get("uid")
  end

  def conditions(resource) do
    resource |> status() |> Map.get("conditions", [])
  end

  def creation_timestamp(resource) do
    resource |> metadata() |> Map.get("creationTimestamp")
  end

  def spec(resource) do
    Map.get(resource, "spec", %{})
  end

  def status(resource) do
    Map.get(resource, "status", %{})
  end

  def ports(resource) do
    resource |> spec() |> Map.get("ports", [])
  end

  def phase(resource) do
    resource |> status() |> Map.get("phase")
  end

  def replicas(resource) do
    resource |> spec() |> Map.get("replicas")
  end

  def available_replicas(resource) do
    resource |> status() |> Map.get("availableReplicas")
  end

  def labeled_owner(resource) do
    resource |> labels() |> Map.get("battery/owner", nil)
  end

  def container_statuses(resource) do
    resource
    |> status()
    |> Map.take(~w(containerStatuses initContainerStatuses))
    |> Map.values()
    |> List.flatten()
  end

  def pod_ip(resource) do
    resource |> status() |> Map.get("podIP")
  end

  def node_name(resource) do
    resource |> spec() |> Map.get("nodeName")
  end

  def qos_class(resource) do
    resource |> status() |> Map.get("qosClass")
  end

  def service_account(resource) do
    resource |> spec() |> Map.get("serviceAccount")
  end

  def group(%{"apiVersion" => api_version} = _resource) when api_version === "v1", do: "core"

  def group(resource) do
    resource |> api_version() |> String.split("/") |> List.first()
  end
end
