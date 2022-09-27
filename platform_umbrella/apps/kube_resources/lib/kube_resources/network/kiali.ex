defmodule KubeResources.Kiali do
  use KubeExt.IncludeResource, kialis_kiali_io: "priv/manifests/kiali/kialis_kiali_io.yaml"
  use KubeExt.ResourceGenerator

  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeExt.KubeState.Hosts
  alias KubeRawResources.NetworkSettings, as: Settings
  alias KubeResources.IstioConfig.VirtualService
  alias KubeResources.Grafana

  @app "kiali"
  @url_base "/x/kiali"

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: "/services/network/kiali"

  def url, do: "//#{Hosts.control_host()}#{@url_base}"

  def virtual_service(config) do
    namespace = Settings.istio_namespace(config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("kiali")
    |> B.spec(VirtualService.prefix(@url_base, "kiali", port: 20_001))
  end

  resource(:cluster_role_binding_operator, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name("kiali-kiali-operator")
    |> B.app_labels(@app)
    |> B.component_label("kiali-operator")
    |> B.role_ref(B.build_cluster_role_ref("kiali-kiali-operator"))
    |> B.subject(B.build_service_account("kiali-kiali-operator", namespace))
  end

  resource(:cluster_role_operator) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => [
          "configmaps",
          "endpoints",
          "pods",
          "serviceaccounts",
          "services",
          "services/finalizers"
        ],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get", "list", "patch"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["create", "list", "watch"]},
      %{
        "apiGroups" => [""],
        "resourceNames" => ["cacerts", "istio-ca-secret"],
        "resources" => ["secrets"],
        "verbs" => ["get"]
      },
      %{
        "apiGroups" => [""],
        "resourceNames" => ["kiali-signing-key"],
        "resources" => ["secrets"],
        "verbs" => ["delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments", "replicasets"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["autoscaling"],
        "resources" => ["horizontalpodautoscalers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["monitoring.coreos.com"],
        "resources" => ["servicemonitors"],
        "verbs" => ["create", "get"]
      },
      %{
        "apiGroups" => ["apps"],
        "resourceNames" => ["kiali-operator"],
        "resources" => ["deployments/finalizers"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["kiali.io"],
        "resources" => ["*"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["authorization.k8s.io"],
        "resources" => ["selfsubjectaccessreviews"],
        "verbs" => ["list"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterrolebindings", "clusterroles", "rolebindings", "roles"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["extensions", "networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["route.openshift.io"],
        "resources" => ["routes"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["oauth.openshift.io"],
        "resources" => ["oauthclients"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["config.openshift.io"],
        "resources" => ["clusteroperators"],
        "verbs" => ["list", "watch"]
      },
      %{
        "apiGroups" => ["config.openshift.io"],
        "resourceNames" => ["kube-apiserver"],
        "resources" => ["clusteroperators"],
        "verbs" => ["get"]
      },
      %{
        "apiGroups" => ["console.openshift.io"],
        "resources" => ["consolelinks"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "endpoints", "pods/log"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces", "pods", "replicationcontrollers", "services"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{"apiGroups" => [""], "resources" => ["pods/portforward"], "verbs" => ["create", "post"]},
      %{
        "apiGroups" => ["extensions", "apps"],
        "resources" => ["daemonsets", "deployments", "replicasets", "statefulsets"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["cronjobs", "jobs"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{
        "apiGroups" => [
          "config.istio.io",
          "networking.istio.io",
          "authentication.istio.io",
          "rbac.istio.io",
          "security.istio.io",
          "extensions.istio.io",
          "telemetry.istio.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch", "create", "delete", "patch"]
      },
      %{
        "apiGroups" => ["apps.openshift.io"],
        "resources" => ["deploymentconfigs"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{"apiGroups" => ["project.openshift.io"], "resources" => ["projects"], "verbs" => ["get"]},
      %{"apiGroups" => ["route.openshift.io"], "resources" => ["routes"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("kiali-kiali-operator")
    |> B.app_labels(@app)
    |> B.component_label("kiali-operator")
    |> B.rules(rules)
  end

  resource(:crd_kialis_io) do
    yaml(get_resource(:kialis_kiali_io))
  end

  resource(:deployment_operator, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:deployment)
    |> B.name("kiali-kiali-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label("kiali-operator")
    |> B.spec(%{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{"battery/app" => "kiali", "battery/component" => "kiali-operator"}
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "app" => "kiali-operator",
            "battery/app" => "kiali",
            "battery/component" => "kiali-operator",
            "battery/managed" => "true",
            "name" => "kiali-kiali-operator"
          },
          "name" => "kiali-kiali-operator",
          "namespace" => "battery-core"
        },
        "spec" => %{
          "affinity" => %{},
          "containers" => [
            %{
              "args" => ["--zap-log-level=info", "--leader-election-id=kiali-kiali-operator"],
              "env" => [
                %{"name" => "WATCH_NAMESPACE", "value" => ""},
                %{
                  "name" => "POD_NAME",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                },
                %{
                  "name" => "POD_NAMESPACE",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                },
                %{"name" => "ALLOW_AD_HOC_KIALI_NAMESPACE", "value" => "true"},
                %{"name" => "ALLOW_AD_HOC_KIALI_IMAGE", "value" => "true"},
                %{"name" => "PROFILE_TASKS_TASK_OUTPUT_LIMIT", "value" => "100"},
                %{"name" => "ANSIBLE_DEBUG_LOGS", "value" => "true"},
                %{"name" => "ANSIBLE_VERBOSITY_KIALI_KIALI_IO", "value" => "1"},
                %{"name" => "ANSIBLE_CONFIG", "value" => "/etc/ansible/ansible.cfg"}
              ],
              "image" => "quay.io/kiali/kiali-operator:v1.56.1",
              "imagePullPolicy" => "Always",
              "name" => "operator",
              "ports" => [%{"containerPort" => 8080, "name" => "http-metrics"}],
              "resources" => %{"requests" => %{"cpu" => "10m", "memory" => "64Mi"}},
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "privileged" => false,
                "runAsNonRoot" => true
              },
              "volumeMounts" => [
                %{"mountPath" => "/tmp/ansible-operator/runner", "name" => "runner"}
              ]
            }
          ],
          "serviceAccountName" => "kiali-kiali-operator",
          "volumes" => [%{"emptyDir" => %{}, "name" => "runner"}]
        }
      }
    })
  end

  resource(:kiali_main, config) do
    namespace = Settings.istio_namespace(config)

    spec = %{
      "auth" => %{"strategy" => "anonymous"},
      "deployment" => %{
        "accessible_namespaces" => ["**"],
        "image_version" => "v1.56.1",
        "logger" => %{"log_level" => "TRACE"},
        "pod_labels" => %{"battery/app" => @app}
      },
      "external_services" => %{
        "prometheus" => %{
          "url" => "http://battery-prometheus-prometheus.battery-core.svc.cluster.local:9090/"
        },
        "grafana" => %{
          "in_cluster_url" =>
            "http://battery-grafana.battery-core.svc.cluster.local:3000/x/grafana/",
          "url" => Grafana.url()
        }
      },
      "istio_namespace" => namespace,
      "server" => %{"web_root" => "/x/kiali"}
    }

    B.build_resource(:kiali)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  resource(:service_account_operator, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("kiali-kiali-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label("kiali-operator")
  end
end
