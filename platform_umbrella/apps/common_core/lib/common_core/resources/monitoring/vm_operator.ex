defmodule CommonCore.Resources.VMOperator do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "vm_operator"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  resource(:cluster_role_binding_vm_operator, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("vm-operator")
    |> B.role_ref(B.build_cluster_role_ref("vm-operator"))
    |> B.subject(B.build_service_account("vm-operator", namespace))
  end

  resource(:cluster_role_vm_operator) do
    rules = [
      %{
        "nonResourceURLs" => ["/metrics", "/metrics/resources", "/metrics/slis"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "configmaps",
          "configmaps/finalizers",
          "endpoints",
          "events",
          "persistentvolumeclaims",
          "persistentvolumeclaims/finalizers",
          "pods/eviction",
          "secrets",
          "secrets/finalizers",
          "services",
          "services/finalizers",
          "serviceaccounts",
          "serviceaccounts/finalizers"
        ],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "configmaps/status",
          "pods",
          "nodes",
          "nodes/proxy",
          "nodes/metrics",
          "namespaces"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => [
          "deployments",
          "deployments/finalizers",
          "statefulsets",
          "statefulsets/finalizers",
          "daemonsets",
          "daemonsets/finalizers",
          "replicasets",
          "statefulsets",
          "statefulsets/finalizers",
          "statefulsets/status"
        ],
        "verbs" => ["*"]
      },
      %{"apiGroups" => ["monitoring.coreos.com"], "resources" => ["*"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => [
          "clusterrolebindings",
          "clusterrolebindings/finalizers",
          "clusterroles",
          "clusterroles/finalizers",
          "roles",
          "rolebindings"
        ],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => ["storage.k8s.io"],
        "resources" => ["storageclasses"],
        "verbs" => ["list", "get", "watch"]
      },
      %{
        "apiGroups" => ["policy"],
        "resources" => ["poddisruptionbudgets", "poddisruptionbudgets/finalizers"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => ["route.openshift.io", "image.openshift.io"],
        "resources" => ["routers/metrics", "registry/metrics"],
        "verbs" => ["get"]
      },
      %{
        "apiGroups" => ["autoscaling"],
        "resources" => ["horizontalpodautoscalers"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses", "ingresses/finalizers"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["list", "watch", "get"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => [
          "vlagents",
          "vlagents/finalizers",
          "vlagents/status",
          "vlogs",
          "vlogs/finalizers",
          "vlogs/status",
          "vlsingles",
          "vlsingles/finalizers",
          "vlsingles/status",
          "vlclusters",
          "vlclusters/finalizers",
          "vlclusters/status",
          "vmagents",
          "vmagents/finalizers",
          "vmagents/status",
          "vmalertmanagerconfigs",
          "vmalertmanagerconfigs/finalizers",
          "vmalertmanagerconfigs/status",
          "vmalertmanagers",
          "vmalertmanagers/finalizers",
          "vmalertmanagers/status",
          "vmalerts",
          "vmalerts/finalizers",
          "vmalerts/status",
          "vmauths",
          "vmauths/finalizers",
          "vmauths/status",
          "vmclusters",
          "vmclusters/finalizers",
          "vmclusters/status",
          "vmnodescrapes",
          "vmnodescrapes/finalizers",
          "vmnodescrapes/status",
          "vmpodscrapes",
          "vmpodscrapes/finalizers",
          "vmpodscrapes/status",
          "vmprobes",
          "vmprobes/finalizers",
          "vmprobes/status",
          "vmrules",
          "vmrules/finalizers",
          "vmrules/status",
          "vmscrapeconfigs",
          "vmscrapeconfigs/finalizers",
          "vmscrapeconfigs/status",
          "vmservicescrapes",
          "vmservicescrapes/finalizers",
          "vmservicescrapes/status",
          "vmsingles",
          "vmsingles/finalizers",
          "vmsingles/status",
          "vmstaticscrapes",
          "vmstaticscrapes/finalizers",
          "vmstaticscrapes/status",
          "vmusers",
          "vmusers/finalizers",
          "vmusers/status",
          "vmanomalies",
          "vmanomalies/finalizers",
          "vmanomalies/status"
        ],
        "verbs" => ["*"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("vm-operator")
    |> B.rules(rules)
  end

  resource(:deployment_vm_operator, battery, state) do
    namespace = core_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{
        "annotations" => %{"kubectl.kubernetes.io/default-container" => "operator"},
        "labels" => %{"battery/managed" => "true"}
      })
      |> Map.put("spec", %{
        "affinity" => %{
          "nodeAffinity" => %{
            "requiredDuringSchedulingIgnoredDuringExecution" => %{
              "nodeSelectorTerms" => [
                %{
                  "matchExpressions" => [
                    %{
                      "key" => "kubernetes.io/arch",
                      "operator" => "In",
                      "values" => ["amd64", "arm64", "ppc64le", "s390x"]
                    },
                    %{"key" => "kubernetes.io/os", "operator" => "In", "values" => ["linux"]}
                  ]
                }
              ]
            }
          }
        },
        "containers" => [
          %{
            "command" => ["/app"],
            "args" => [
              "--leader-elect",
              "--health-probe-bind-address=:8081",
              "--metrics-bind-address=:8080"
            ],
            "env" => [
              %{"name" => "WATCH_NAMESPACE", "value" => ""},
              %{"name" => "POD_NAME", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}},
              %{"name" => "OPERATOR_NAME", "value" => "vm-operator"},
              %{"name" => "VM_USECUSTOMCONFIGRELOADER", "value" => "true"},
              %{"name" => "VM_PSPAUTOCREATEENABLED", "value" => "false"},
              %{"name" => "VM_ENABLEDPROMETHEUSCONVERTEROWNERREFERENCES", "value" => "true"}
            ],
            "image" => battery.config.operator_image,
            "imagePullPolicy" => "IfNotPresent",
            "livenessProbe" => %{
              "httpGet" => %{"path" => "/health", "port" => 8081},
              "initialDelaySeconds" => 15,
              "periodSeconds" => 20
            },
            "name" => "operator",
            "ports" => [
              %{"containerPort" => 8080, "name" => "http", "protocol" => "TCP"},
              %{"containerPort" => 9443, "name" => "webhook-server", "protocol" => "TCP"}
            ],
            "readinessProbe" => %{
              "httpGet" => %{"path" => "/ready", "port" => 8081},
              "initialDelaySeconds" => 5,
              "periodSeconds" => 10
            },
            "resources" => %{},
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]}
            },
            "volumeMounts" => []
          }
        ],
        "securityContext" => %{
          "runAsNonRoot" => true,
          "seccompProfile" => %{"type" => "RuntimeDefault"}
        },
        "serviceAccountName" => "vm-operator",
        "terminationGracePeriodSeconds" => 10,
        "volumes" => []
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("vm-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:role_binding_vm_leader_election_rolebinding, _battery, state) do
    namespace = core_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("vm-leader-election-rolebinding")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("vm-leader-election-role"))
    |> B.subject(B.build_service_account("vm-operator", namespace))
  end

  resource(:role_vm_leader_election, _battery, state) do
    namespace = core_namespace(state)

    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps/status"],
        "verbs" => ["get", "update", "patch"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["create", "get", "update"]
      }
    ]

    :role
    |> B.build_resource()
    |> B.name("vm-leader-election-role")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:service_account_vm_operator, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("vm-operator")
    |> B.namespace(namespace)
  end

  resource(:service_vm_operator_metrics, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 8080, "protocol" => "TCP", "targetPort" => 8080}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("vm-operator-metrics-service")
    |> B.namespace(namespace)
    |> B.component_labels("victoria-metrics-operator")
    |> B.spec(spec)
  end

  resource(:service_vm_webhook, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"port" => 443, "targetPort" => 9443}])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("vm-webhook-service")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end
end
