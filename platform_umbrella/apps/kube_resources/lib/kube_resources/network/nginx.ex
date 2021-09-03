defmodule KubeResources.Nginx do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeResources.NetworkSettings

  @app_name "ingress-nginx"

  def service_account(config) do
    namespace = NetworkSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.namespace(namespace)
    |> B.name("battery-ingress-nginx")
    |> B.app_labels(@app_name)
    |> Map.put("automountServiceAccountToken", true)
  end

  def config_map(config) do
    namespace = NetworkSettings.namespace(config)

    B.build_resource(:config_map)
    |> B.name("ingress-nginx-controller")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx"
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps", "endpoints", "nodes", "pods", "secrets"],
          "verbs" => ["list", "watch"]
        },
        %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["get"]},
        %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["get", "list", "watch"]},
        %{
          "apiGroups" => ["extensions", "networking.k8s.io"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
        %{
          "apiGroups" => ["extensions", "networking.k8s.io"],
          "resources" => ["ingresses/status"],
          "verbs" => ["update"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingressclasses"],
          "verbs" => ["get", "list", "watch"]
        }
      ]
    }
  end

  def cluster_role_binding(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-ingress-nginx"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-ingress-nginx",
          "namespace" => namespace
        }
      ]
    }
  end

  def role(config) do
    namespace = NetworkSettings.namespace(config)

    B.build_resource(:role)
    |> B.name("battery-ingress-nginx")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> Map.put("rules", [
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get"]},
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "pods", "secrets", "endpoints"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["extensions", "networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["extensions", "networking.k8s.io"],
        "resources" => ["ingresses/status"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingressclasses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "resourceNames" => ["ingress-nginx-controller-leader-battery-nginx"],
        "verbs" => ["get", "update"]
      },
      %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["create"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ])
  end

  def role_binding(config) do
    namespace = NetworkSettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name("battery-ingress-nginx")
    |> B.namespace(namespace)
    |> Map.put("roleRef", %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "Role",
      "name" => "battery-ingress-nginx"
    })
    |> Map.put("subjects", [
      %{
        "kind" => "ServiceAccount",
        "name" => "battery-ingress-nginx",
        "namespace" => namespace
      }
    ])
  end

  def service(config) do
    namespace = NetworkSettings.namespace(config)

    spec =
      %{}
      |> B.short_selector(@app_name)
      |> B.ports([
        %{"name" => "http", "port" => 80, "protocol" => "TCP", "targetPort" => "http"},
        %{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => "https"}
      ])
      |> Map.put("type", "LoadBalancer")

    B.build_resource(:service)
    |> B.namespace(namespace)
    |> B.name("ingress-nginx-controller")
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def deployment(config) do
    namespace = NetworkSettings.namespace(config)

    template =
      %{}
      |> B.app_labels(@app_name)
      |> B.spec(%{
        "dnsPolicy" => "ClusterFirst",
        "containers" => [controller_container(config)],
        "nodeSelector" => %{"kubernetes.io/os" => "linux"},
        "serviceAccountName" => "battery-ingress-nginx",
        "terminationGracePeriodSeconds" => 300
      })

    spec =
      %{}
      |> B.match_labels_selector(@app_name)
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put("minReadySeconds", 0)
      |> B.template(template)

    B.build_resource(:deployment)
    |> B.name("ingress-nginx")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  defp controller_container(_config) do
    %{
      "name" => "controller",
      "image" =>
        "k8s.gcr.io/ingress-nginx/controller:v0.48.1@sha256:e9fb216ace49dfa4a5983b183067e97496e7a8b307d2093f4278cd550c303899",
      "imagePullPolicy" => "IfNotPresent",
      "lifecycle" => %{"preStop" => %{"exec" => %{"command" => ["/wait-shutdown"]}}},
      "args" => [
        "/nginx-ingress-controller",
        "--publish-service=$(POD_NAMESPACE)/ingress-nginx-controller",
        "--election-id=ingress-nginx-controller-leader",
        "--ingress-class=battery-nginx",
        "--configmap=$(POD_NAMESPACE)/ingress-nginx-controller"
      ],
      "securityContext" => %{
        "capabilities" => %{"drop" => ["ALL"], "add" => ["NET_BIND_SERVICE"]},
        "runAsUser" => 101,
        "allowPrivilegeEscalation" => true
      },
      "env" => [
        %{
          "name" => "POD_NAME",
          "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
        },
        %{
          "name" => "POD_NAMESPACE",
          "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
        },
        %{"name" => "LD_PRELOAD", "value" => "/usr/local/lib/libmimalloc.so"}
      ],
      "livenessProbe" => %{
        "failureThreshold" => 5,
        "httpGet" => %{"path" => "/healthz", "port" => 10_254, "scheme" => "HTTP"},
        "initialDelaySeconds" => 10,
        "periodSeconds" => 10,
        "successThreshold" => 1,
        "timeoutSeconds" => 1
      },
      "readinessProbe" => %{
        "failureThreshold" => 3,
        "httpGet" => %{"path" => "/healthz", "port" => 10_254, "scheme" => "HTTP"},
        "initialDelaySeconds" => 10,
        "periodSeconds" => 10,
        "successThreshold" => 1,
        "timeoutSeconds" => 1
      },
      "ports" => [
        %{"name" => "http", "containerPort" => 80, "protocol" => "TCP"},
        %{"name" => "https", "containerPort" => 443, "protocol" => "TCP"}
      ],
      "resources" => %{"requests" => %{"cpu" => "100m", "memory" => "90Mi"}}
    }
  end
end
