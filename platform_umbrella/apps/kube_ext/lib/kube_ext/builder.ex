defmodule KubeExt.Builder do
  alias KubeExt.ApiVersionKind

  @spec build_resource(atom) :: map()
  def build_resource(:secret) do
    Map.put(build_resource("v1", "Secret"), "type", "Opaque")
  end

  def build_resource(resource_type) when is_atom(resource_type) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)
    build_resource(api_version, kind)
  end

  @spec build_resource(:ingress, any, any, binary | number) :: map
  def build_resource(:ingress, path, service_name, port) do
    build_resource("networking.k8s.io/v1", "Ingress")
    |> annotation("kubernetes.io/ingress.class", "battery-nginx")
    |> spec(%{"rules" => [build_rule(:http, [build_path(path, service_name, port)])]})
  end

  @spec build_resource(binary(), binary()) :: map()
  def build_resource(api_version, kind) do
    %{"apiVersion" => api_version, "kind" => kind, "metadata" => %{}}
  end

  @spec annotation(map(), binary(), any()) :: map()
  def annotation(resouce, key, value) do
    resouce
    |> Map.put_new("metadata", %{})
    |> update_in(~w(metadata annotations), fn anno -> anno || %{} end)
    |> put_in(["metadata", "annotations", key], value)
  end

  @spec annotations(map(), map()) :: map()
  def annotations(resouce, %{} = anno_map) do
    resouce
    |> Map.put_new("metadata", %{})
    |> update_in(~w(metadata annotations), fn anno -> Map.merge(anno || %{}, anno_map) end)
  end

  @spec label(map, binary(), binary()) :: map()
  def label(resource, key, value) do
    resource
    |> Map.put_new("metadata", %{})
    |> update_in(~w[metadata labels], fn l -> Map.put_new(l || %{}, key, value) end)
  end

  @spec app_labels(map(), binary()) :: map()
  def app_labels(resource, app_name) do
    resource
    |> label("battery/app", app_name)
    |> label("app", app_name)
    |> label("battery/managed", "true")
  end

  @spec owner_label(map(), binary()) :: map()
  def owner_label(resource, owner_id) do
    label(resource, "battery/owner", owner_id)
  end

  @spec component_label(map(), binary()) :: map()
  def component_label(resource, component_name) do
    resource
    |> label("battery/component", component_name)
    |> label("component", component_name)
    |> label("app.kubernetes.io/component", component_name)
  end

  @spec name(map(), binary()) :: map()
  def name(%{} = resource, name) do
    put_in(resource, ~w[metadata name], name)
  end

  @spec namespace(map(), binary()) :: map()
  def namespace(resource, namespace) do
    put_in(resource, ~w[metadata namespace], namespace)
  end

  @spec match_labels_selector(map(), binary()) :: map()
  def match_labels_selector(resource, app_name) do
    resource
    |> Map.put_new("selector", %{})
    |> put_in(~w[selector matchLabels], %{"battery/app" => app_name})
  end

  @spec short_selector(map(), binary()) :: map()
  def short_selector(resource, app_name), do: short_selector(resource, "battery/app", app_name)

  @spec short_selector(map(), binary(), binary()) :: map()
  def short_selector(resource, key, value) do
    resource
    |> Map.put_new("selector", %{})
    |> put_in(["selector", key], value)
  end

  def spec(resource, spec), do: Map.put(resource, "spec", spec)
  def data(resource, data), do: Map.put(resource, "data", data)
  def template(resource, %{} = template), do: Map.put(resource, "template", template)
  def ports(resource, ports), do: Map.put(resource, "ports", ports)
  def rules(resource, rules), do: Map.put(resource, "rules", rules)
  def role_ref(resource, role_ref), do: Map.put(resource, "roleRef", role_ref)

  def subject(resource, subject) do
    resource
    |> Map.put_new("subjects", [])
    |> update_in(~w(subjects), fn subjects -> [subject | subjects] end)
  end

  defp build_rule(:http, paths) do
    %{"http" => %{"paths" => paths}}
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

  def build_cluster_role_ref(cluster_role_name) do
    %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "ClusterRole",
      "name" => cluster_role_name
    }
  end

  def build_role_ref(role_name) do
    %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "Role",
      "name" => role_name
    }
  end

  def build_group(group_name) do
    %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "Group",
      "name" => group_name
    }
  end

  def build_group(group_name, namespace) do
    %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "Group",
      "name" => group_name,
      "namespace" => namespace
    }
  end

  def build_service_account(account_name, namespace) do
    %{
      "kind" => "ServiceAccount",
      "name" => account_name,
      "namespace" => namespace
    }
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
