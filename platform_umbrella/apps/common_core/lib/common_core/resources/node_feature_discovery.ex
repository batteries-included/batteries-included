defmodule CommonCore.Resources.NodeFeatureDiscovery do
  @moduledoc false
  use CommonCore.IncludeResource,
    nodefeaturegroups_nfd_k8s_sigs_io: "priv/manifests/node_feature_discovery/nodefeaturegroups_nfd_k8s_sigs_io.yaml",
    nodefeaturerules_nfd_k8s_sigs_io: "priv/manifests/node_feature_discovery/nodefeaturerules_nfd_k8s_sigs_io.yaml",
    nodefeatures_nfd_k8s_sigs_io: "priv/manifests/node_feature_discovery/nodefeatures_nfd_k8s_sigs_io.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "node_feature_discovery"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  resource(:crd_nodefeaturegroups_nfd_k8s_sigs_io) do
    YamlElixir.read_all_from_string!(get_resource(:nodefeaturegroups_nfd_k8s_sigs_io))
  end

  resource(:crd_nodefeaturerules_nfd_k8s_sigs_io) do
    YamlElixir.read_all_from_string!(get_resource(:nodefeaturerules_nfd_k8s_sigs_io))
  end

  resource(:crd_nodefeatures_nfd_k8s_sigs_io) do
    YamlElixir.read_all_from_string!(get_resource(:nodefeatures_nfd_k8s_sigs_io))
  end

  resource(:cluster_role_binding_nfd_gc, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("nfd-gc")
    |> B.role_ref(B.build_cluster_role_ref("nfd-gc"))
    |> B.subject(B.build_service_account("nfd-gc", namespace))
  end

  resource(:cluster_role_binding_nfd_master, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("nfd-master")
    |> B.role_ref(B.build_cluster_role_ref("nfd-master"))
    |> B.subject(B.build_service_account("nfd-master", namespace))
  end

  resource(:cluster_role_nfd_gc) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["nodes/proxy"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["topology.node.k8s.io"],
        "resources" => ["noderesourcetopologies"],
        "verbs" => ["delete", "list"]
      },
      %{
        "apiGroups" => ["nfd.k8s-sigs.io"],
        "resources" => ["nodefeatures"],
        "verbs" => ["delete", "list"]
      }
    ]

    :cluster_role |> B.build_resource() |> B.name("nfd-gc") |> B.rules(rules)
  end

  resource(:cluster_role_nfd_master) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["watch", "list"]},
      %{
        "apiGroups" => [""],
        "resources" => ["nodes", "nodes/status"],
        "verbs" => ["get", "patch", "update", "list"]
      },
      %{
        "apiGroups" => ["nfd.k8s-sigs.io"],
        "resources" => ["nodefeatures", "nodefeaturerules", "nodefeaturegroups"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["nfd.k8s-sigs.io"],
        "resources" => ["nodefeaturegroup/status"],
        "verbs" => ["patch", "update"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["create"]},
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resourceNames" => ["nfd-master.nfd.kubernetes.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "update"]
      }
    ]

    :cluster_role |> B.build_resource() |> B.name("nfd-master") |> B.rules(rules)
  end

  resource(:role_nfd_worker, _battery, state) do
    namespace = core_namespace(state)

    rules = [
      %{
        "apiGroups" => ["nfd.k8s-sigs.io"],
        "resources" => ["nodefeatures"],
        "verbs" => ["create", "get", "update", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["get"]}
    ]

    :role |> B.build_resource() |> B.name("nfd-worker") |> B.namespace(namespace) |> B.rules(rules)
  end

  resource(:config_map_nfd_master, _battery, state) do
    namespace = core_namespace(state)
    data = Map.put(%{}, "nfd-master.conf", Ymlr.document!(%{}))

    :config_map
    |> B.build_resource()
    |> B.name("nfd-master-conf")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_nfd_worker, _battery, state) do
    namespace = core_namespace(state)

    data = Map.put(%{}, "nfd-worker.conf", Ymlr.document!(%{}))

    :config_map
    |> B.build_resource()
    |> B.name("nfd-worker-conf")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:daemon_set_nfd_worker, battery, state) do
    namespace = core_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{
        "labels" => %{"battery/component" => "nfd-worker", "battery/app" => @app_name, "battery/managed" => "true"}
      })
      |> Map.put("spec", %{
        "containers" => [
          %{
            "command" => ["nfd-worker"],
            "args" => [
              "-feature-gates=NodeFeatureGroupAPI=false",
              "-metrics=8081",
              "-grpc-health=8082"
            ],
            "env" => [
              %{
                "name" => "NODE_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
              },
              %{
                "name" => "POD_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
              },
              %{
                "name" => "POD_UID",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.uid"}}
              }
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "Always",
            "livenessProbe" => %{
              "grpc" => %{"port" => 8082},
              "initialDelaySeconds" => 10,
              "periodSeconds" => 10
            },
            "name" => "nfd-worker",
            "ports" => [%{"containerPort" => 8081, "name" => "metrics"}, %{"containerPort" => 8082, "name" => "health"}],
            "readinessProbe" => %{
              "failureThreshold" => 10,
              "grpc" => %{"port" => 8082},
              "initialDelaySeconds" => 5,
              "periodSeconds" => 10
            },
            "resources" => %{
              "limits" => %{"cpu" => "200m", "memory" => "256Mi"},
              "requests" => %{"cpu" => "5m", "memory" => "64Mi"}
            },
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true
            },
            "volumeMounts" => [
              %{"mountPath" => "/host-boot", "name" => "host-boot", "readOnly" => true},
              %{
                "mountPath" => "/host-etc/os-release",
                "name" => "host-os-release",
                "readOnly" => true
              },
              %{"mountPath" => "/host-sys", "name" => "host-sys", "readOnly" => true},
              %{
                "mountPath" => "/host-proc/swaps",
                "name" => "host-proc-swaps",
                "readOnly" => true
              },
              %{"mountPath" => "/host-usr/lib", "name" => "host-usr-lib", "readOnly" => true},
              %{"mountPath" => "/host-lib", "name" => "host-lib", "readOnly" => true},
              %{
                "mountPath" => "/etc/kubernetes/node-feature-discovery/features.d/",
                "name" => "features-d",
                "readOnly" => true
              },
              %{
                "mountPath" => "/etc/kubernetes/node-feature-discovery",
                "name" => "nfd-worker-conf",
                "readOnly" => true
              }
            ]
          }
        ],
        "dnsPolicy" => "ClusterFirstWithHostNet",
        "serviceAccount" => "nfd-worker",
        "tolerations" => [
          %{"key" => "CriticalAddonsOnly", "operator" => "Exists"},
          %{"key" => "nvidia.com/gpu", "operator" => "Exists", "effect" => "NoSchedule"}
        ],
        "volumes" => [
          %{"hostPath" => %{"path" => "/boot"}, "name" => "host-boot"},
          %{"hostPath" => %{"path" => "/proc/swaps"}, "name" => "host-proc-swaps"},
          %{"hostPath" => %{"path" => "/etc/os-release"}, "name" => "host-os-release"},
          %{"hostPath" => %{"path" => "/sys"}, "name" => "host-sys"},
          %{"hostPath" => %{"path" => "/usr/lib"}, "name" => "host-usr-lib"},
          %{"hostPath" => %{"path" => "/lib"}, "name" => "host-lib"},
          %{
            "hostPath" => %{"path" => "/etc/kubernetes/node-feature-discovery/features.d/"},
            "name" => "features-d"
          },
          %{"configMap" => %{"name" => "nfd-worker-conf"}, "name" => "nfd-worker-conf"}
        ]
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/component" => "nfd-worker", "battery/app" => @app_name}})
      |> B.template(template)

    :daemon_set
    |> B.build_resource()
    |> B.name("nfd-worker")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:deployment_nfd_gc, battery, state) do
    namespace = core_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{
        "labels" => %{"battery/component" => "nfd-gc", "battery/app" => @app_name, "battery/managed" => "true"}
      })
      |> Map.put("spec", %{
        "containers" => [
          %{
            "command" => ["nfd-gc"],
            "env" => [
              %{
                "name" => "NODE_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
              },
              %{
                "name" => "POD_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
              },
              %{
                "name" => "POD_UID",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.uid"}}
              }
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "Always",
            "name" => "nfd-gc",
            "ports" => [%{"containerPort" => 8081, "name" => "metrics"}],
            "resources" => %{
              "limits" => %{"cpu" => "20m", "memory" => "512Mi"},
              "requests" => %{"cpu" => "10m", "memory" => "128Mi"}
            },
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true
            }
          }
        ],
        "dnsPolicy" => "ClusterFirstWithHostNet",
        "serviceAccount" => "nfd-gc"
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "nfd-gc"}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("nfd-gc")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:deployment_nfd_master, battery, state) do
    namespace = core_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{
        "labels" => %{"battery/component" => "nfd-master", "battery/app" => @app_name, "battery/managed" => "true"}
      })
      |> Map.put("spec", %{
        "affinity" => %{
          "nodeAffinity" => %{
            "preferredDuringSchedulingIgnoredDuringExecution" => [
              %{
                "preference" => %{
                  "matchExpressions" => [
                    %{
                      "key" => "node-role.kubernetes.io/master",
                      "operator" => "In",
                      "values" => [""]
                    }
                  ]
                },
                "weight" => 1
              },
              %{
                "preference" => %{
                  "matchExpressions" => [
                    %{
                      "key" => "node-role.kubernetes.io/control-plane",
                      "operator" => "In",
                      "values" => [""]
                    }
                  ]
                },
                "weight" => 1
              }
            ]
          }
        },
        "containers" => [
          %{
            "command" => ["nfd-master"],
            "args" => [
              "-enable-leader-election",
              "-feature-gates=NodeFeatureGroupAPI=false",
              "-metrics=8081",
              "-grpc-health=8082"
            ],
            "env" => [
              %{
                "name" => "NODE_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
              },
              %{
                "name" => "POD_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
              },
              %{
                "name" => "POD_UID",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.uid"}}
              }
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "IfNotPresent",
            "livenessProbe" => %{"grpc" => %{"port" => 8082}},
            "name" => "nfd-master",
            "ports" => [%{"containerPort" => 8081, "name" => "metrics"}, %{"containerPort" => 8082, "name" => "health"}],
            "readinessProbe" => %{"failureThreshold" => 10, "grpc" => %{"port" => 8082}},
            "resources" => %{
              "limits" => %{"cpu" => "300m", "memory" => "1Gi"},
              "requests" => %{"cpu" => "100m", "memory" => "128Mi"}
            },
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true
            },
            "startupProbe" => %{"failureThreshold" => 30, "grpc" => %{"port" => 8082}},
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/kubernetes/node-feature-discovery",
                "name" => "nfd-master-conf",
                "readOnly" => true
              }
            ]
          }
        ],
        "enableServiceLinks" => false,
        "serviceAccount" => "nfd-master",
        "volumes" => [
          %{"configMap" => %{"name" => "nfd-master-conf"}, "name" => "nfd-master-conf"}
        ]
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "nfd-master"}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("nfd-master")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:role_binding_nfd_worker, _battery, state) do
    namespace = core_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("nfd-worker")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("nfd-worker"))
    |> B.subject(B.build_service_account("nfd-worker", namespace))
  end

  resource(:service_account_nfd_gc, _battery, state) do
    namespace = core_namespace(state)
    :service_account |> B.build_resource() |> B.name("nfd-gc") |> B.namespace(namespace)
  end

  resource(:service_account_nfd_master, _battery, state) do
    namespace = core_namespace(state)
    :service_account |> B.build_resource() |> B.name("nfd-master") |> B.namespace(namespace)
  end

  resource(:service_account_nfd_worker, _battery, state) do
    namespace = core_namespace(state)
    :service_account |> B.build_resource() |> B.name("nfd-worker") |> B.namespace(namespace)
  end
end
