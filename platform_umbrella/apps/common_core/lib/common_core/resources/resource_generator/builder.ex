defmodule CommonCore.Resources.Builder do
  @moduledoc false
  alias CommonCore.ApiVersionKind

  @spec build_resource(atom | {String.t(), String.t()}) :: map()
  def build_resource(:secret = resource_type) do
    resource_type
    |> ApiVersionKind.from_resource_type!()
    |> build_resource()
    |> Map.put("type", "Opaque")
  end

  def build_resource(:job = resource_type) do
    resource_type
    |> ApiVersionKind.from_resource_type!()
    |> build_resource()
    |> label("sidecar.istio.io/inject", "false")
  end

  def build_resource(resource_type) when is_atom(resource_type) do
    resource_type
    |> ApiVersionKind.from_resource_type!()
    |> build_resource()
  end

  def build_resource({api_version, kind}) do
    %{"apiVersion" => api_version, "kind" => kind, "metadata" => %{}}
  end

  @spec annotation(map(), binary(), any()) :: map()
  def annotation(resource, key, value) do
    resource
    |> Map.put_new("metadata", %{})
    |> update_in(~w(metadata annotations), fn anno -> anno || %{} end)
    |> put_in(["metadata", "annotations", key], value)
  end

  @spec annotations(map(), map()) :: map()
  def annotations(resource, %{} = anno_map) do
    resource
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
    |> label("app", app_name)
    |> label("app.kubernetes.io/name", app_name)
    |> label("battery/app", app_name)
    |> label("app.kubernetes.io/version", "latest")
    |> label("version", "latest")
  end

  def managed_labels(resource) do
    resource
    |> label("battery/managed", "true")
    |> label("battery/managed.direct", "true")
    |> label("app.kubernetes.io/managed-by", "batteries-included")
  end

  @spec add_owner(map(), String.t() | map() | nil) :: any
  def add_owner(resource, %{id: id} = _id_backed_strut), do: owner_label(resource, id)
  def add_owner(resource, owner_binary) when is_binary(owner_binary), do: owner_label(resource, owner_binary)
  def add_owner(resource, _), do: resource

  @spec owner_label(map(), binary() | nil) :: map()
  def owner_label(resource, nil = _owner_id) do
    resource
  end

  def owner_label(resource, owner_id) do
    label(resource, "battery/owner", owner_id)
  end

  @spec component_labels(map(), binary()) :: map()
  def component_labels(resource, component_name) do
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
  def match_labels_selector(resource, app_name), do: match_labels_selector(resource, "battery/app", app_name)

  @spec match_labels_selector(map(), binary(), binary()) :: map()
  def match_labels_selector(resource, key, value) do
    resource
    |> Map.get("selector", %{})
    |> Map.get("matchLabels", %{})
    |> Map.put(key, value)
    |> then(&short_selector(resource, "matchLabels", &1))
  end

  @spec short_selector(map(), binary()) :: map()
  def short_selector(resource, app_name), do: short_selector(resource, "battery/app", app_name)

  @spec short_selector(map(), binary(), term()) :: map()
  def short_selector(resource, key, value) do
    resource
    |> Map.put_new("selector", %{})
    |> put_in(["selector", key], value)
  end

  def spec(resource, spec), do: Map.put(resource, "spec", spec)

  @doc """
  Add the data field to a resource. Data is a map of key value pairs.
  """
  @spec data(map(), any()) :: map()
  def data(resource, data) when is_struct(data), do: data(resource, Map.from_struct(data))

  def data(resource, data) do
    Map.put(resource, "data", Map.new(data, fn {k, v} -> {to_data_key(k), v} end))
  end

  defp to_data_key(key) when is_binary(key), do: key
  defp to_data_key(key) when is_atom(key), do: Atom.to_string(key)
  defp to_data_key(key), do: to_string(key)

  def template(resource, %{} = template), do: Map.put(resource, "template", template)
  def ports(resource, ports), do: Map.put(resource, "ports", ports)
  def rules(resource, rules), do: Map.put(resource, "rules", rules)

  @spec role_ref(map, map) :: map
  def role_ref(resource, role_ref), do: Map.put(resource, "roleRef", role_ref)

  def subject(resource, subject) do
    resource
    |> Map.put_new("subjects", [])
    |> update_in(~w(subjects), fn subjects -> [subject | subjects] end)
  end

  def aggregation_rule(resource, rule_map), do: Map.put(resource, "aggregationRule", rule_map)

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

  def configmap_key_ref(name, key) do
    %{
      configMapKeyRef: %{
        name: name,
        key: key
      }
    }
  end

  def issuer_ref(group, kind, name) do
    %{
      "group" => group,
      "kind" => kind,
      "name" => name
    }
  end

  def secret_type(resource, type), do: Map.put(resource, "type", type)
end
