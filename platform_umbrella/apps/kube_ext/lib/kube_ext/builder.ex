defmodule KubeExt.Builder do
  def build_resource(:virtual_service) do
    build_resource("networking.istio.io/v1alpha3", "VirtualService")
  end

  def build_resource(:gateway) do
    build_resource("networking.istio.io/v1alpha3", "Gateway")
  end

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

  def build_resource(:job) do
    build_resource("batch/v1", "Job")
  end

  def build_resource(:role_binding) do
    build_resource("rbac.authorization.k8s.io/v1", "RoleBinding")
  end

  def build_resource(:role) do
    build_resource("rbac.authorization.k8s.io/v1", "Role")
  end

  def build_resource(:cluster_role) do
    build_resource("rbac.authorization.k8s.io/v1", "ClusterRole")
  end

  def build_resource(:cluster_role_binding) do
    build_resource("rbac.authorization.k8s.io/v1", "ClusterRoleBinding")
  end

  def build_resource(:service_monitor) do
    build_resource("monitoring.coreos.com/v1", "ServiceMonitor")
  end

  def build_resource(:pod_monitor) do
    build_resource("monitoring.coreos.com/v1", "PodMonitor")
  end

  def build_resource(:secret) do
    Map.put(build_resource("v1", "Secret"), "type", "Opaque")
  end

  def build_resource(:knative_serving) do
    build_resource("operator.knative.dev/v1alpha1", "KnativeServing")
  end

  def build_resource(:postgresql) do
    build_resource("acid.zalan.do/v1", "postgresql")
  end

  def build_resource(:ingress) do
    "networking.k8s.io/v1"
    |> build_resource("Ingress")
    |> annotation("kubernetes.io/ingress.class", "battery-nginx")
  end

  def build_resource(:pod_disruption_budget) do
    build_resource("policy/v1beta1", "PodDisruptionBudget")
  end

  def build_resource(:ingress, path, service_name, port) do
    build_resource("networking.k8s.io/v1", "Ingress")
    |> annotation("kubernetes.io/ingress.class", "battery-nginx")
    |> spec(%{"rules" => [build_rule(:http, [build_path(path, service_name, port)])]})
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
    |> label("battery/managed", "true")
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

  def rewriting_ingress(resouce) do
    resouce
    |> annotation("nginx.ingress.kubernetes.io/rewrite-target", "/$2")
    |> annotation("nginx.ingress.kubernetes.io/use-regex", "true")
    |> update_in(~w(spec rules), fn rules ->
      Enum.map(rules || [], &add_capture_to_rule/1)
    end)
  end

  def spec(resource, spec), do: Map.put(resource, "spec", spec)
  def template(resource, %{} = template), do: Map.put(resource, "template", template)
  def ports(resource, ports), do: Map.put(resource, "ports", ports)

  defp build_rule(:http, paths) do
    %{
      "http" => %{
        "paths" => paths
      }
    }
  end

  defp build_path(path, service_name, port_name) when is_binary(port_name) do
    %{
      "path" => path,
      "pathType" => "Prefix",
      "backend" => %{
        "service" => %{
          "name" => service_name,
          "port" => %{"name" => port_name}
        }
      }
    }
  end

  defp build_path(path, service_name, port_number) when is_number(port_number) do
    %{
      "path" => path,
      "pathType" => "Prefix",
      "backend" => %{
        "service" => %{
          "name" => service_name,
          "port" => %{"number" => port_number}
        }
      }
    }
  end

  def add_capture_to_rule(rule) do
    update_in(rule, ~w(http paths), fn paths ->
      Enum.map(paths || [], &add_capture_to_path/1)
    end)
  end

  def add_capture_to_path(path) do
    update_in(path, ~w(path), fn p -> p <> "(/|$)(.*)" end)
  end

  def secret_key_ref(name, key) do
    %{
      secretKeyRef: %{
        name: name,
        key: key
      }
    }
  end
end
