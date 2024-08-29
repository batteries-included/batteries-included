defmodule CommonCore.Resources.VMOperator do
  @moduledoc false
  use CommonCore.IncludeResource,
    vmagents_operator_victoriametrics_com: "priv/manifests/vm_operator/vmagents_operator_victoriametrics_com.yaml",
    vmalertmanagerconfigs_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmalertmanagerconfigs_operator_victoriametrics_com.yaml",
    vmalertmanagers_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmalertmanagers_operator_victoriametrics_com.yaml",
    vmalerts_operator_victoriametrics_com: "priv/manifests/vm_operator/vmalerts_operator_victoriametrics_com.yaml",
    vmauths_operator_victoriametrics_com: "priv/manifests/vm_operator/vmauths_operator_victoriametrics_com.yaml",
    vmclusters_operator_victoriametrics_com: "priv/manifests/vm_operator/vmclusters_operator_victoriametrics_com.yaml",
    vmnodescrapes_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmnodescrapes_operator_victoriametrics_com.yaml",
    vmpodscrapes_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmpodscrapes_operator_victoriametrics_com.yaml",
    vmprobes_operator_victoriametrics_com: "priv/manifests/vm_operator/vmprobes_operator_victoriametrics_com.yaml",
    vmrules_operator_victoriametrics_com: "priv/manifests/vm_operator/vmrules_operator_victoriametrics_com.yaml",
    vmscrapeconfigs_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmscrapeconfigs_operator_victoriametrics_com.yaml",
    vmservicescrapes_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmservicescrapes_operator_victoriametrics_com.yaml",
    vmsingles_operator_victoriametrics_com: "priv/manifests/vm_operator/vmsingles_operator_victoriametrics_com.yaml",
    vmstaticscrapes_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmstaticscrapes_operator_victoriametrics_com.yaml",
    vmusers_operator_victoriametrics_com: "priv/manifests/vm_operator/vmusers_operator_victoriametrics_com.yaml"

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
      %{"apiGroups" => [""], "resources" => ["configmaps", "configmaps/finalizers"], "verbs" => ["*"]},
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
      %{"apiGroups" => [""], "resources" => ["services", "services/finalizers"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["serviceaccounts", "serviceaccounts/finalizers"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create"]},
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
        "apiGroups" => ["apps"],
        "resources" => [
          "deployments",
          "deployments/finalizers",
          "replicasets",
          "statefulsets",
          "statefulsets/finalizers",
          "statefulsets/status"
        ],
        "verbs" => ["*"]
      },
      %{"apiGroups" => ["monitoring.coreos.com"], "resources" => ["*"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => [
          "vmagents",
          "vmagents/finalizers",
          "vmalertmanagers",
          "vmalertmanagers/finalizers",
          "vmalertmanagerconfigs",
          "vmalertmanagerconfigs/finalizers",
          "vmalerts",
          "vmalerts/finalizers",
          "vmauths",
          "vmauths/finalizers",
          "vmusers",
          "vmusers/finalizers",
          "vmclusters",
          "vmclusters/finalizers",
          "vmpodscrapes",
          "vmpodscrapes/finalizers",
          "vmrules",
          "vmrules/finalizers",
          "vmservicescrapes",
          "vmservicescrapes/finalizers",
          "vmprobes",
          "vmprobes/finalizers",
          "vmsingles",
          "vmsingles/finalizers",
          "vmnodescrapes",
          "vmnodescrapes/finalizers",
          "vmstaticscrapes",
          "vmstaticscrapes/finalizers",
          "vmscrapeconfigs",
          "vmscrapeconfigs/finalizers"
        ],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["operator.victoriametrics.com"],
        "resources" => [
          "vmagents/status",
          "vmalertmanagers/status",
          "vmalertmanagerconfigss/status",
          "vmalerts/status",
          "vmclusters/status",
          "vmpodscrapes/status",
          "vmscrapeconfigs/status",
          "vmrules/status",
          "vmservicescrapes/status",
          "vmprobes/status",
          "vmsingles/status",
          "vmscrapeconfig/status",
          "vmusers/status",
          "vmauths/status",
          "vmstaticscrapes/status",
          "vmnodescrapes/status"
        ],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["extensions", "networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"nonResourceURLs" => ["/metrics", "/metrics/resources"], "verbs" => ["get", "watch", "list"]},
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
      %{"apiGroups" => ["storage.k8s.io"], "resources" => ["storageclasses"], "verbs" => ["list", "get", "watch"]},
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
      },
      %{"apiGroups" => ["discovery.k8s.io"], "resources" => ["endpointslices"], "verbs" => ["list", "watch", "get"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("vm-operator")
    |> B.rules(rules)
  end

  resource(:crd_vmagents_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmagents_operator_victoriametrics_com))
  end

  resource(:crd_vmalertmanagerconfigs_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmalertmanagerconfigs_operator_victoriametrics_com))
  end

  resource(:crd_vmalertmanagers_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmalertmanagers_operator_victoriametrics_com))
  end

  resource(:crd_vmalerts_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmalerts_operator_victoriametrics_com))
  end

  resource(:crd_vmauths_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmauths_operator_victoriametrics_com))
  end

  resource(:crd_vmclusters_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmclusters_operator_victoriametrics_com))
  end

  resource(:crd_vmnodescrapes_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmnodescrapes_operator_victoriametrics_com))
  end

  resource(:crd_vmpodscrapes_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmpodscrapes_operator_victoriametrics_com))
  end

  resource(:crd_vmprobes_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmprobes_operator_victoriametrics_com))
  end

  resource(:crd_vmrules_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmrules_operator_victoriametrics_com))
  end

  resource(:crd_vmscrapeconfigs_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmscrapeconfigs_operator_victoriametrics_com))
  end

  resource(:crd_vmservicescrapes_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmservicescrapes_operator_victoriametrics_com))
  end

  resource(:crd_vmsingles_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmsingles_operator_victoriametrics_com))
  end

  resource(:crd_vmstaticscrapes_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmstaticscrapes_operator_victoriametrics_com))
  end

  resource(:crd_vmusers_operator_victoriametrics_com) do
    YamlElixir.read_all_from_string!(get_resource(:vmusers_operator_victoriametrics_com))
  end

  resource(:deployment_vm_operator, battery, state) do
    namespace = core_namespace(state)

    template =
      %{
        "metadata" => %{
          "labels" => %{"battery/managed" => "true"}
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => ["--zap-log-level=info", "--enable-leader-election"],
              "command" => ["manager"],
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
              "name" => "operator",
              "ports" => [
                %{"containerPort" => 8080, "name" => "http", "protocol" => "TCP"},
                %{"containerPort" => 9443, "name" => "webhook", "protocol" => "TCP"}
              ],
              "resources" => %{},
              "volumeMounts" => nil
            }
          ],
          "serviceAccountName" => "vm-operator",
          "volumes" => nil
        }
      }
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

  resource(:role_binding_vm_operator, _battery, state) do
    namespace = core_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("vm-operator")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("vm-operator"))
    |> B.subject(B.build_service_account("vm-operator", namespace))
  end

  resource(:role_vm_operator, _battery, state) do
    namespace = core_namespace(state)

    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["configmaps/status"], "verbs" => ["get", "update", "patch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["create", "get", "update"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("vm-operator")
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

  resource(:service_vm_operator, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 8080, "protocol" => "TCP", "targetPort" => 8080},
        %{"name" => "webhook", "port" => 443, "targetPort" => 9443}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("vm-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end
end
