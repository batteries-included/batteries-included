defmodule CommonCore.Resources.FieldAccessors do
  @moduledoc """
  Provides accessor functions for common fields in Kubernetes resources.
  """

  defdelegate name(resource), to: K8s.Resource
  defdelegate namespace(resource), to: K8s.Resource
  defdelegate kind(resource), to: K8s.Resource
  defdelegate label(resource, label), to: K8s.Resource
  defdelegate labels(resource), to: K8s.Resource
  defdelegate has_label?(resource, label), to: K8s.Resource
  defdelegate annotations(resource), to: K8s.Resource
  defdelegate metadata(resource), to: K8s.Resource
  defdelegate api_version(resource), to: K8s.Resource

  def uid(resource) when is_nil(resource), do: nil

  def uid(resource) do
    resource |> metadata() |> Kernel.||(%{}) |> Map.get("uid")
  end

  def conditions(resource) when is_nil(resource), do: []

  def conditions(resource) do
    resource |> status() |> Map.get("conditions", [])
  end

  def creation_timestamp(nil), do: nil

  def creation_timestamp(resource) do
    Map.get(metadata(resource) || %{}, "creationTimestamp")
  end

  def spec(resource) when is_nil(resource), do: %{}

  def spec(resource) do
    Map.get(resource, "spec", %{})
  end

  def status(resource) when is_nil(resource), do: %{}

  def status(resource) do
    Map.get(resource, "status", %{})
  end

  def ports(resource) when is_nil(resource), do: []

  def ports(resource) do
    resource |> spec() |> Map.get("ports", [])
  end

  def phase(resource) when is_nil(resource), do: nil

  def phase(resource) do
    resource |> status() |> Map.get("phase")
  end

  def replicas(resource) when is_nil(resource), do: nil

  def replicas(resource) do
    resource |> spec() |> Map.get("replicas")
  end

  def available_replicas(resource) when is_nil(resource), do: nil

  def available_replicas(resource) do
    resource |> status() |> Map.get("availableReplicas")
  end

  def labeled_owner(resource) when is_nil(resource), do: nil

  def labeled_owner(resource) do
    resource |> labels() |> Map.get("battery/owner")
  end

  def container_statuses(resource) when is_nil(resource), do: []

  def container_statuses(resource) do
    resource
    |> status()
    |> Map.take(~w(containerStatuses initContainerStatuses))
    |> Map.values()
    |> List.flatten()
  end

  def pod_ip(resource) when is_nil(resource), do: nil

  def pod_ip(resource) do
    resource |> status() |> Map.get("podIP")
  end

  def node_name(resource) when is_nil(resource), do: nil

  def node_name(resource) do
    resource |> spec() |> Map.get("nodeName")
  end

  def qos_class(resource) when is_nil(resource), do: nil

  def qos_class(resource) do
    resource |> status() |> Map.get("qosClass")
  end

  def service_account(resource) when is_nil(resource), do: nil

  def service_account(resource) do
    resource |> spec() |> Map.get("serviceAccount")
  end

  def group(resource) when is_nil(resource), do: nil
  def group(%{"apiVersion" => api_version} = _resource) when api_version === "v1", do: "core"

  def group(resource) do
    resource |> api_version() |> group_from_api_version()
  end

  def group_from_api_version(apiversion), do: apiversion |> String.split("/") |> List.first()

  def summary(resource) do
    %{
      api_version: api_version(resource),
      kind: kind(resource),
      name: name(resource),
      namespace: namespace(resource)
    }
  end
end
