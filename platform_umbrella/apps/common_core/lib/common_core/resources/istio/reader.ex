defmodule CommonCore.Resources.Istio.Reader do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "istio-reader"

  alias CommonCore.Resources.Builder, as: B

  resource(:cluster_role_istio_reader_clusterrole, battery, _state) do
    rules = [
      %{
        "apiGroups" => [
          "config.istio.io",
          "security.istio.io",
          "networking.istio.io",
          "authentication.istio.io",
          "rbac.istio.io",
          "telemetry.istio.io",
          "extensions.istio.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "endpoints",
          "pods",
          "services",
          "nodes",
          "replicationcontrollers",
          "namespaces",
          "secrets",
          "configmaps"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["networking.x-k8s.io", "gateway.networking.k8s.io"],
        "resources" => ["gateways"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceexports"],
        "verbs" => ["get", "list", "watch", "create", "delete"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceimports"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["replicasets"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => ["authorization.k8s.io"],
        "resources" => ["subjectaccessreviews"],
        "verbs" => ["create"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("istio-reader-clusterrole-#{battery.config.namespace}")
    |> B.rules(rules)
  end

  resource(:cluster_role_binding_istio_reader_clusterrole, battery, _state) do
    namespace = battery.config.namespace

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istio-reader-clusterrole-#{namespace}")
    |> B.role_ref(B.build_cluster_role_ref("istio-reader-clusterrole-#{namespace}"))
    |> B.subject(B.build_service_account("istio-reader-service-account", namespace))
  end

  resource(:service_account_istio_reader, battery, _state) do
    :service_account
    |> B.build_resource()
    |> B.name("istio-reader-service-account")
    |> B.namespace(battery.config.namespace)
  end
end
