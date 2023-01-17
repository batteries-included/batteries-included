defmodule KubeResources.VMOperator do
  use CommonCore.IncludeResource,
    vmagents_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmagents_operator_victoriametrics_com.yaml",
    vmalertmanagerconfigs_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmalertmanagerconfigs_operator_victoriametrics_com.yaml",
    vmalertmanagers_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmalertmanagers_operator_victoriametrics_com.yaml",
    vmalerts_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmalerts_operator_victoriametrics_com.yaml",
    vmauths_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmauths_operator_victoriametrics_com.yaml",
    vmclusters_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmclusters_operator_victoriametrics_com.yaml",
    vmnodescrapes_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmnodescrapes_operator_victoriametrics_com.yaml",
    vmpodscrapes_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmpodscrapes_operator_victoriametrics_com.yaml",
    vmprobes_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmprobes_operator_victoriametrics_com.yaml",
    vmrules_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmrules_operator_victoriametrics_com.yaml",
    vmservicescrapes_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmservicescrapes_operator_victoriametrics_com.yaml",
    vmsingles_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmsingles_operator_victoriametrics_com.yaml",
    vmstaticscrapes_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmstaticscrapes_operator_victoriametrics_com.yaml",
    vmusers_operator_victoriametrics_com:
      "priv/manifests/vcitoria_metrics/vmusers_operator_victoriametrics_com.yaml"

  use KubeExt.ResourceGenerator, app_name: "victoria-metrics-operator"
  import CommonCore.Yaml
  import CommonCore.SystemState.Namespaces
  alias KubeExt.Builder, as: B

  @service_account_name "victoria-metrics-operator"

  resource(:crd_vmagents_operator_victoriametrics_com) do
    yaml(get_resource(:vmagents_operator_victoriametrics_com))
  end

  resource(:crd_vmalertmanagerconfigs_operator_victoriametrics_com) do
    yaml(get_resource(:vmalertmanagerconfigs_operator_victoriametrics_com))
  end

  resource(:crd_vmalertmanagers_operator_victoriametrics_com) do
    yaml(get_resource(:vmalertmanagers_operator_victoriametrics_com))
  end

  resource(:crd_vmalerts_operator_victoriametrics_com) do
    yaml(get_resource(:vmalerts_operator_victoriametrics_com))
  end

  resource(:crd_vmauths_operator_victoriametrics_com) do
    yaml(get_resource(:vmauths_operator_victoriametrics_com))
  end

  resource(:crd_vmclusters_operator_victoriametrics_com) do
    yaml(get_resource(:vmclusters_operator_victoriametrics_com))
  end

  resource(:crd_vmnodescrapes_operator_victoriametrics_com) do
    yaml(get_resource(:vmnodescrapes_operator_victoriametrics_com))
  end

  resource(:crd_vmpodscrapes_operator_victoriametrics_com) do
    yaml(get_resource(:vmpodscrapes_operator_victoriametrics_com))
  end

  resource(:crd_vmprobes_operator_victoriametrics_com) do
    yaml(get_resource(:vmprobes_operator_victoriametrics_com))
  end

  resource(:crd_vmrules_operator_victoriametrics_com) do
    yaml(get_resource(:vmrules_operator_victoriametrics_com))
  end

  resource(:crd_vmservicescrapes_operator_victoriametrics_com) do
    yaml(get_resource(:vmservicescrapes_operator_victoriametrics_com))
  end

  resource(:crd_vmsingles_operator_victoriametrics_com) do
    yaml(get_resource(:vmsingles_operator_victoriametrics_com))
  end

  resource(:crd_vmstaticscrapes_operator_victoriametrics_com) do
    yaml(get_resource(:vmstaticscrapes_operator_victoriametrics_com))
  end

  resource(:crd_vmusers_operator_victoriametrics_com) do
    yaml(get_resource(:vmusers_operator_victoriametrics_com))
  end

  resource(:cluster_role_binding_victoria_metrics_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("victoria-metrics-operator")
    |> B.role_ref(B.build_cluster_role_ref("victoria-metrics-operator"))
    |> B.subject(B.build_service_account(@service_account_name, namespace))
  end

  resource(:cluster_role_victoria_metrics_operator) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "configmaps/finalizers"],
        "verbs" => ["*"]
      },
      %{"apiGroups" => [""], "resources" => ["endpoints"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["persistentvolumeclaims", "persistentvolumeclaims/finalizers"],
        "verbs" => ["*"]
      },
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["secrets", "secrets/finalizers"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["services/finalizers"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments", "deployments/finalizers"],
        "verbs" => ["*"]
      },
      %{"apiGroups" => ["apps"], "resources" => ["replicasets"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["apps"],
        "resources" => ["statefulsets", "statefulsets/finalizers", "statefulsets/status"],
        "verbs" => ["*"]
      },
      %{"apiGroups" => ["monitoring.coreos.com"], "resources" => ["*"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmagents", "vmagents/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmagents/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmalertmanagers", "vmalertmanagers/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmalertmanagers/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmalertmanagerconfigs", "vmalertmanagerconfigs/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmalertmanagerconfigss/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmalerts", "vmalerts/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmalerts/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmclusters", "vmclusters/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmclusters/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmpodscrapes", "vmprobscrapes/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmpodscrapes/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmrules", "vmrules/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmrules/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmservicescrapes", "vmservicescrapes/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmservicescrapes/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmprobes"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmprobes/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmsingles", "vmsingles/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmsingles/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "nodes",
          "nodes/proxy",
          "services",
          "endpoints",
          "pods",
          "endpointslices",
          "configmaps",
          "nodes/metrics",
          "namespaces"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["extensions", "networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "nonResourceURLs" => ["/metrics", "/metrics/resources"],
        "verbs" => ["get", "watch", "list"]
      },
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
        "verbs" => ["get", "list", "create", "patch", "update", "watch", "delete"]
      },
      %{
        "apiGroups" => ["policy"],
        "resources" => ["podsecuritypolicies", "podsecuritypolicies/finalizers"],
        "verbs" => ["get", "list", "create", "patch", "update", "use", "watch", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["serviceaccounts", "serviceaccounts/finalizers"],
        "verbs" => ["get", "list", "create", "watch", "update", "delete"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmnodescrapes", "vmnodescrapes/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmnodescrapes/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmstaticscrapes", "vmstaticscrapes/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmstaticscrapes/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmauths", "vmauths/finalizers", "vmusers", "vmusers/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => ["vmusers/status", "vmauths/status"],
        "verbs" => ["get", "patch", "update"]
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
        "verbs" => ["list", "get", "delete", "create", "update", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io", "extensions"],
        "resources" => ["ingresses", "ingresses/finalizers"],
        "verbs" => ["create", "delete", "get", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("victoria-metrics-operator")
    |> B.rules(rules)
  end

  resource(:role_binding_victoria_metrics_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("victoria-metrics-operator")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("victoria-metrics-operator"))
    |> B.subject(B.build_service_account(@service_account_name, namespace))
  end

  resource(:role_victoria_metrics_operator, _battery, state) do
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

    B.build_resource(:role)
    |> B.name("victoria-metrics-operator")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:service_account_victoria_metrics_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name(@service_account_name)
    |> B.namespace(namespace)
  end

  resource(:deployment_victoria_metrics_operator, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name
          }
        }
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => ["--zap-log-level=info", "--enable-leader-election"],
                "command" => ["manager"],
                "env" => [
                  %{"name" => "WATCH_NAMESPACE", "value" => ""},
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{"name" => "OPERATOR_NAME", "value" => "victoria-metrics-operator"},
                  %{"name" => "VM_ENABLEDPROMETHEUSCONVERTER_PODMONITOR", "value" => "true"},
                  %{"name" => "VM_ENABLEDPROMETHEUSCONVERTER_SERVICESCRAPE", "value" => "true"},
                  %{"name" => "VM_ENABLEDPROMETHEUSCONVERTER_PROMETHEUSRULE", "value" => "true"},
                  %{"name" => "VM_ENABLEDPROMETHEUSCONVERTER_PROBE", "value" => "true"},
                  %{
                    "name" => "VM_ENABLEDPROMETHEUSCONVERTER_ALERTMANAGERCONFIG",
                    "value" => "true"
                  },
                  %{"name" => "VM_PSPAUTOCREATEENABLED", "value" => "false"},
                  %{"name" => "VM_ENABLEDPROMETHEUSCONVERTEROWNERREFERENCES", "value" => "false"},
                  %{
                    "name" => "VM_DEFAULTLABELS",
                    "value" => "managed-by=vm-operator,battery/managed.indirect=true"
                  }
                ],
                "image" => battery.config.vmoperator_image,
                "imagePullPolicy" => "IfNotPresent",
                "name" => "victoria-metrics-operator",
                "ports" => [
                  %{"containerPort" => 8080, "name" => "http", "protocol" => "TCP"},
                  %{"containerPort" => 9443, "name" => "webhook", "protocol" => "TCP"}
                ],
                "resources" => %{},
                "volumeMounts" => nil
              }
            ],
            "serviceAccountName" => @service_account_name,
            "volumes" => nil
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("victoria-metrics-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_victoria_metrics_operator, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 8080, "protocol" => "TCP", "targetPort" => 8080},
        %{"name" => "webhook", "port" => 443, "targetPort" => 9443}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("victoria-metrics-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_operator, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"port" => "http"}])
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})

    B.build_resource(:monitoring_service_monitor)
    |> B.name("victoria-metrics-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end
end
