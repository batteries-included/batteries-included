defmodule KubeResources.PostgresPod do
  alias KubeExt.Builder, as: B

  @app "postgres-operator"

  @service_account "postgres-pod"
  @pod_role "postres-pod"
  @pod_cluster_role "battery-postres-pod"

  @spec common(any(), any()) :: map()
  def common(_battery, _state) do
    %{
      "/cluster_role/postgres-pod" => cluster_role()
    }
  end

  @spec per_namespace(binary()) :: map()
  def per_namespace(namespace) do
    %{
      "/service_account/postgres-pod" => service_account(namespace),
      "/role/postgres-pod" => role(namespace),
      "/cluster_role_binding/postgres-pod" => cluster_role_binding(namespace),
      "/role_binding/postgres-pod" => role_binding(namespace)
    }
  end

  @spec service_account_name() :: binary()
  def service_account_name, do: @service_account

  @spec cluster_role_binding(binary()) :: map()
  def cluster_role_binding(namespace) do
    B.build_resource(:cluster_role_binding)
    |> B.name("#{namespace}-postgres-pod")
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@pod_cluster_role))
    |> B.subject(B.build_service_account("postgres-pod", namespace))
  end

  @spec role_binding(binary()) :: map()
  def role_binding(namespace) do
    B.build_resource(:role_binding)
    |> B.name("postgres-pod")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_role_ref(@pod_role))
    |> B.subject(B.build_service_account("postgres-pod", namespace))
  end

  @spec cluster_role() :: map()
  def cluster_role do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["endpoints"],
        "verbs" => [
          "create",
          "delete",
          "deletecollection",
          "get",
          "list",
          "patch",
          "update",
          "watch"
        ]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["pods"],
        "verbs" => ["get", "list", "patch", "update", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["create"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name(@pod_cluster_role)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  @spec role(binary()) :: map()
  def role(namespace) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["endpoints"],
        "verbs" => [
          "create",
          "delete",
          "deletecollection",
          "get",
          "list",
          "patch",
          "update",
          "watch"
        ]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["pods"],
        "verbs" => ["get", "list", "patch", "update", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["create"]}
    ]

    B.build_resource(:role)
    |> B.name(@pod_role)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  @spec service_account(binary()) :: map()
  def service_account(namespace) do
    B.build_resource(:service_account)
    |> B.name("postgres-pod")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end
end
