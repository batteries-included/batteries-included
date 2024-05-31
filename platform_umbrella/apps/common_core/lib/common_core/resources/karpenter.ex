defmodule CommonCore.Resources.Karpenter do
  @moduledoc false
  use CommonCore.IncludeResource,
    ec2nodeclasses_karpenter_k8s_aws: "priv/manifests/karpenter/ec2nodeclasses_karpenter_k8s_aws.yaml",
    nodeclaims_karpenter_sh: "priv/manifests/karpenter/nodeclaims_karpenter_sh.yaml",
    nodepools_karpenter_sh: "priv/manifests/karpenter/nodepools_karpenter_sh.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "karpenter"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Core

  resource(:crd_ec2nodeclasses_karpenter_k8s_aws) do
    YamlElixir.read_all_from_string!(get_resource(:ec2nodeclasses_karpenter_k8s_aws))
  end

  resource(:crd_nodeclaims_karpenter_sh) do
    YamlElixir.read_all_from_string!(get_resource(:nodeclaims_karpenter_sh))
  end

  resource(:crd_nodepools_karpenter_sh) do
    YamlElixir.read_all_from_string!(get_resource(:nodepools_karpenter_sh))
  end

  resource(:pod_disruption_budget_main, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("maxUnavailable", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})

    :pod_disruption_budget
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_account_main, battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.annotation("eks.amazonaws.com/role-arn", battery.config.service_role_arn)
  end

  resource(:cluster_role_admin) do
    rules = [
      %{
        "apiGroups" => ["karpenter.sh"],
        "resources" => ["nodepools", "nodepools/status", "nodeclaims", "nodeclaims/status"],
        "verbs" => ["get", "list", "watch", "create", "delete", "patch"]
      },
      %{
        "apiGroups" => ["karpenter.k8s.aws"],
        "resources" => ["ec2nodeclasses"],
        "verbs" => ["get", "list", "watch", "create", "delete", "patch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("karpenter-admin")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_core) do
    rules = [
      %{
        "apiGroups" => ["karpenter.sh"],
        "resources" => ["nodepools", "nodepools/status", "nodeclaims", "nodeclaims/status"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "pods",
          "nodes",
          "persistentvolumes",
          "persistentvolumeclaims",
          "replicationcontrollers",
          "namespaces"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["storage.k8s.io"],
        "resources" => ["storageclasses", "csinodes"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["daemonsets", "deployments", "replicasets", "statefulsets"],
        "verbs" => ["list", "watch"]
      },
      %{"apiGroups" => ["policy"], "resources" => ["poddisruptionbudgets"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["karpenter.sh"],
        "resources" => ["nodeclaims", "nodeclaims/status"],
        "verbs" => ["create", "delete", "update", "patch"]
      },
      %{
        "apiGroups" => ["karpenter.sh"],
        "resources" => ["nodepools", "nodepools/status"],
        "verbs" => ["update", "patch"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["patch", "delete"]},
      %{"apiGroups" => [""], "resources" => ["pods/eviction"], "verbs" => ["create"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("karpenter-core")
    |> B.rules(rules)
  end

  resource(:cluster_role_main) do
    rules = [
      %{"apiGroups" => ["karpenter.k8s.aws"], "resources" => ["ec2nodeclasses"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["karpenter.k8s.aws"],
        "resources" => ["ec2nodeclasses", "ec2nodeclasses/status"],
        "verbs" => ["patch", "update"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.rules(rules)
  end

  resource(:cluster_role_binding_core, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("karpenter-core")
    |> B.role_ref(B.build_cluster_role_ref("karpenter-core"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_main, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.role_ref(B.build_cluster_role_ref(@app_name))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:role_main, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["get", "watch"]},
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resourceNames" => ["karpenter-leader-election"],
        "resources" => ["leases"],
        "verbs" => ["patch", "update"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["create"]}
    ]

    :role
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_dns, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resourceNames" => ["kube-dns"], "resources" => ["services"], "verbs" => ["get"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("karpenter-dns")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_lease) do
    # NODE(jdt): this isn't configurable
    namespace = "kube-node-lease"

    rules = [
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["delete"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("karpenter-lease")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_binding_main, _battery, state) do
    # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@app_name))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:role_binding_dns, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("karpenter-dns")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("karpenter-dns"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:role_binding_lease, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("karpenter-lease")
    |> B.namespace("kube-node-lease")
    |> B.role_ref(B.build_role_ref("karpenter-lease"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:service_main, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 8000, "protocol" => "TCP", "targetPort" => "http-metrics"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})
      |> Map.put("type", "ClusterIP")

    :service
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:deployment_main, battery, state) do
    namespace = base_namespace(state)

    template =
      %{}
      |> Map.put(
        "metadata",
        %{
          "annotations" => nil,
          "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
        }
      )
      |> Map.put(
        "spec",
        %{
          "affinity" => %{
            "nodeAffinity" => %{
              "requiredDuringSchedulingIgnoredDuringExecution" => %{
                "nodeSelectorTerms" => [
                  %{"matchExpressions" => [%{"key" => "karpenter.sh/nodepool", "operator" => "DoesNotExist"}]}
                ]
              }
            },
            "podAntiAffinity" => %{
              "requiredDuringSchedulingIgnoredDuringExecution" => [
                %{
                  "labelSelector" => %{
                    "matchLabels" => %{
                      "battery/app" => @app_name
                    }
                  },
                  "topologyKey" => "kubernetes.io/hostname"
                }
              ]
            }
          },
          "containers" => [
            %{
              "env" => [
                %{"name" => "KUBERNETES_MIN_VERSION", "value" => "1.19.0-0"},
                %{"name" => "KARPENTER_SERVICE", "value" => @app_name},
                %{"name" => "LOG_LEVEL", "value" => "info"},
                %{"name" => "METRICS_PORT", "value" => "8000"},
                %{"name" => "HEALTH_PROBE_PORT", "value" => "8081"},
                %{"name" => "SYSTEM_NAMESPACE", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}},
                %{
                  "name" => "MEMORY_LIMIT",
                  "valueFrom" => %{
                    "resourceFieldRef" => %{
                      "containerName" => "controller",
                      "divisor" => "0",
                      "resource" => "limits.memory"
                    }
                  }
                },
                %{"name" => "FEATURE_GATES", "value" => "Drift=true,SpotToSpotConsolidation=false"},
                %{"name" => "BATCH_MAX_DURATION", "value" => "10s"},
                %{"name" => "BATCH_IDLE_DURATION", "value" => "1s"},
                %{"name" => "ASSUME_ROLE_DURATION", "value" => "15m"},
                %{"name" => "CLUSTER_NAME", "value" => Core.config_field(state, :cluster_name)},
                %{"name" => "VM_MEMORY_OVERHEAD_PERCENT", "value" => "0.075"},
                %{"name" => "INTERRUPTION_QUEUE", "value" => battery.config.queue_name},
                %{"name" => "RESERVED_ENIS", "value" => "0"}
              ],
              "image" => battery.config.image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{"path" => "/healthz", "port" => "http"},
                "initialDelaySeconds" => 30,
                "timeoutSeconds" => 30
              },
              "name" => "controller",
              "ports" => [
                %{"containerPort" => 8000, "name" => "http-metrics", "protocol" => "TCP"},
                %{"containerPort" => 8081, "name" => "http", "protocol" => "TCP"}
              ],
              "readinessProbe" => %{
                "httpGet" => %{"path" => "/readyz", "port" => "http"},
                "initialDelaySeconds" => 5,
                "timeoutSeconds" => 30
              },
              "resources" => %{
                "limits" => %{"cpu" => 1, "memory" => "1Gi"},
                "requests" => %{"cpu" => 1, "memory" => "1Gi"}
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "readOnlyRootFilesystem" => true,
                "runAsGroup" => 65_536,
                "runAsNonRoot" => true,
                "runAsUser" => 65_536,
                "seccompProfile" => %{"type" => "RuntimeDefault"}
              }
            }
          ],
          "dnsPolicy" => "ClusterFirst",
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "priorityClassName" => "system-cluster-critical",
          "securityContext" => %{"fsGroup" => 65_536},
          "serviceAccountName" => @app_name,
          "tolerations" => [%{"key" => "CriticalAddonsOnly", "operator" => "Exists"}],
          "topologySpreadConstraints" => [
            %{
              "labelSelector" => %{
                "matchLabels" => %{"battery/app" => @app_name}
              },
              "maxSkew" => 1,
              "topologyKey" => "topology.kubernetes.io/zone",
              "whenUnsatisfiable" => "ScheduleAnyway"
            }
          ]
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 2)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )
      |> Map.put("strategy", %{"rollingUpdate" => %{"maxUnavailable" => 1}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:node_class, battery, state) do
    cluster_name = Core.config_field(state, :cluster_name)

    spec = %{
      "amiFamily" => "AL2",
      "role" => battery.config.node_role_name,
      "securityGroupSelectorTerms" => [%{"tags" => %{"karpenter.sh/discovery" => cluster_name}}],
      "subnetSelectorTerms" => [%{"tags" => %{"karpenter.sh/discovery" => cluster_name}}],
      "tags" => %{
        "karpenter.sh/discovery" => cluster_name,
        "batteriesincl.com/managed" => "true",
        "batteriesincl.com/environment" => "organization/bi/#{cluster_name}",
        "Name" => "#{cluster_name}-fleet"
      }
    }

    :karpenter_ec2node_class
    |> B.build_resource()
    |> B.name("default")
    |> B.spec(spec)
  end

  resource(:node_pool) do
    spec = %{
      "disruption" => %{"consolidateAfter" => "30s", "consolidationPolicy" => "WhenEmpty", "expireAfter" => "12h"},
      "limits" => %{"cpu" => 1000},
      "template" => %{
        "spec" => %{
          "nodeClassRef" => %{"name" => "default"},
          "requirements" => [
            %{"key" => "kubernetes.io/arch", "operator" => "In", "values" => ["amd64"]},
            %{"key" => "karpenter.sh/capacity-type", "operator" => "In", "values" => ["spot", "on-demand"]},
            %{"key" => "karpenter.k8s.aws/instance-family", "operator" => "In", "values" => ["t3", "t3a", "m7a", "m7i"]},
            %{
              "key" => "karpenter.k8s.aws/instance-size",
              "operator" => "In",
              # TODO(jdt): base this list on the default cluster size?
              "values" => [
                "small",
                "medium",
                "large",
                "xlarge",
                "2xlarge",
                "4xlarge",
                "8xlarge",
                "12xlarge",
                "16xlarge",
                "24xlarge",
                "32xlarge",
                "48xlarge"
              ]
            },
            %{"key" => "karpenter.k8s.aws/instance-hypervisor", "operator" => "In", "values" => ["nitro"]}
          ]
        }
      }
    }

    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("default")
    |> B.spec(spec)
  end
end
