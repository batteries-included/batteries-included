defmodule KubeExt.Builder do
  def build_resource(:namespace) do
    build_resource("v1", "Namespace")
  end

  def build_resource(:service_account) do
    build_resource("v1", "ServiceAccount")
  end

  def build_resource(:stateful_set) do
    build_resource("apps/v1", "StatefulSet")
  end

  def build_resource(:deployment) do
    build_resource("apps/v1", "Deployment")
  end

  def build_resource(:config_map) do
    build_resource("v1", "ConfigMap")
  end

  def build_resource(:service) do
    build_resource("v1", "Service")
  end

  def build_resource(:service_monitor) do
    build_resource("monitoring.coreos.com/v1", "ServiceMonitor")
  end

  def build_resource(api_version, kind) do
    %{"apiVersion" => api_version, "kind" => kind, "metadata" => %{}}
  end

  def annotation(resouce, key, value) do
    resouce
    |> Map.put_new("metadata", %{})
    |> update_in(~w(metadata annotations), fn anno -> anno || %{} end)
    |> put_in(["metadata", "annotations", key], value)
  end

  def label(resource, key, value) do
    resource
    |> Map.put_new("metadata", %{})
    |> update_in(~w[metadata labels], fn l -> l || %{} end)
    |> put_in(
      ["metadata", "labels", key],
      value
    )
  end

  def app_labels(resource, app_name) do
    resource
    |> label("battery/app", app_name)
    |> label("battery/managed", "True")
  end

  def name(%{} = resource, name) do
    put_in(resource, ~w[metadata name], name)
  end

  def namespace(resource, namespace) do
    put_in(resource, ~w[metadata namespace], namespace)
  end

  def match_labels_selector(resource, app_name) do
    resource
    |> Map.put_new("selector", %{})
    |> put_in(~w[selector matchLabels], %{"battery/app" => app_name})
  end

  def short_selector(resource, app_name), do: short_selector(resource, "battery/app", app_name)

  def short_selector(resource, key, value) do
    resource
    |> Map.put_new("selector", %{})
    |> put_in(["selector", key], value)
  end

  def spec(resource, %{} = spec), do: Map.put(resource, "spec", spec)
  def template(resource, %{} = template), do: Map.put(resource, "template", template)
  def ports(resource, ports), do: Map.put(resource, "ports", ports)
end
