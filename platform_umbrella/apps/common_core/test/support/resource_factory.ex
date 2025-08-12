defmodule CommonCore.ResourceFactory do
  @moduledoc false
  use ExMachina

  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.Resources.Builder, as: B

  def namespace_factory(attrs \\ %{}) do
    name =
      Map.get_lazy(attrs, :name, fn -> sequence(:namespace_name, ["app-ns", "service-ns", "data-ns", "monitoring-ns"]) end)

    owner = Map.get_lazy(attrs, :owner, fn -> BatteryUUID.autogenerate() end)

    app_name =
      Map.get_lazy(attrs, :app_name, fn -> sequence(:app_name, ["web-app", "api-service", "worker", "scheduler"]) end)

    :namespace
    |> B.build_resource()
    |> B.name(name)
    |> B.add_owner(owner)
    |> B.app_labels(app_name)
    |> Map.put("spec", %{
      "finalizers" => ["kubernetes"]
    })
    |> Map.put("status", %{
      "phase" => "Active"
    })
    |> merge_attributes(attrs)
  end

  def service_factory(attrs \\ %{}) do
    app_name =
      Map.get_lazy(attrs, :app_name, fn -> sequence(:service_app, ["web-app", "api-service", "worker", "cache"]) end)

    namespace =
      Map.get_lazy(attrs, :namespace, fn -> sequence(:service_namespace, ["app-ns", "service-ns", "data-ns"]) end)

    name =
      Map.get_lazy(attrs, :name, fn -> sequence(:service_name, &"test-service-#{&1}") end)

    owner =
      Map.get_lazy(attrs, :owner, fn -> BatteryUUID.autogenerate() end)

    component =
      Map.get_lazy(attrs, :component, fn -> sequence(:service_component, ["frontend", "backend", "database", "cache"]) end)

    :service
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(app_name)
    |> B.add_owner(owner)
    |> B.component_labels(component)
    |> Map.put("spec", %{
      "clusterIP" => sequence(:cluster_ip, ["10.96.100.1", "10.96.100.2", "10.96.100.3"]),
      "clusterIPs" => [sequence(:cluster_ips, ["10.96.100.1", "10.96.100.2", "10.96.100.3"])],
      "internalTrafficPolicy" => "Cluster",
      "ipFamilies" => ["IPv4"],
      "ipFamilyPolicy" => "SingleStack",
      "ports" => [
        %{
          "name" => sequence(:port_name, ["http", "https", "metrics", "grpc"]),
          "port" => sequence(:port_number, [80, 443, 8080, 9090]),
          "protocol" => "TCP",
          "targetPort" => sequence(:target_port, [8080, 8443, 3000, 9090])
        }
      ],
      "selector" => %{
        "app" => app_name
      },
      "sessionAffinity" => "None",
      "type" => sequence(:service_type, ["ClusterIP", "NodePort", "LoadBalancer"])
    })
    |> merge_attributes(attrs)
  end

  def node_factory(attrs \\ %{}) do
    zone = sequence(:zone, ["zone-a", "zone-b", "zone-c"])

    name = Map.get_lazy(attrs, :name, fn -> sequence(:node_name, &"test-worker-#{&1}") end)

    :node
    |> B.build_resource()
    |> B.name(name)
    |> B.label("kubernetes.io/arch", "amd64")
    |> B.label("kubernetes.io/hostname", name)
    |> B.label("kubernetes.io/os", "linux")
    |> B.label("node-role.kubernetes.io/worker", "")
    |> B.label("topology.kubernetes.io/zone", zone)
    |> B.label("instance-type", sequence(:instance_type, ["m5.large", "m5.xlarge", "c5.large"]))
    |> Map.put("spec", %{
      "podCIDR" => sequence(:pod_cidr, ["10.244.1.0/24", "10.244.2.0/24", "10.244.3.0/24"]),
      "podCIDRs" => [sequence(:pod_cidrs, ["10.244.1.0/24", "10.244.2.0/24", "10.244.3.0/24"])],
      "providerID" => sequence(:provider_id, &"aws:///#{zone}/i-#{String.duplicate("0", 8)}#{&1}")
    })
    |> Map.put("status", %{
      "addresses" => [
        %{
          "address" => sequence(:internal_ip, ["192.168.1.10", "192.168.1.11", "192.168.1.12"]),
          "type" => "InternalIP"
        },
        %{
          "address" => name,
          "type" => "Hostname"
        }
      ],
      "allocatable" => %{
        "cpu" => sequence(:allocatable_cpu, ["4", "8", "16"]),
        "ephemeral-storage" => sequence(:ephemeral_storage, ["100Gi", "200Gi", "500Gi"]),
        "memory" => sequence(:allocatable_memory, ["8Gi", "16Gi", "32Gi"]),
        "pods" => "110"
      },
      "capacity" => %{
        "cpu" => sequence(:capacity_cpu, ["4", "8", "16"]),
        "ephemeral-storage" => sequence(:total_storage, ["120Gi", "240Gi", "600Gi"]),
        "memory" => sequence(:capacity_memory, ["8Gi", "16Gi", "32Gi"]),
        "pods" => "110"
      },
      "conditions" => [
        %{
          "lastHeartbeatTime" => "2025-08-13T10:00:00Z",
          "lastTransitionTime" => "2025-08-13T09:00:00Z",
          "message" => "kubelet has sufficient memory available",
          "reason" => "KubeletHasSufficientMemory",
          "status" => "False",
          "type" => "MemoryPressure"
        },
        %{
          "lastHeartbeatTime" => "2025-08-13T10:00:00Z",
          "lastTransitionTime" => "2025-08-13T09:00:00Z",
          "message" => "kubelet is posting ready status",
          "reason" => "KubeletReady",
          "status" => "True",
          "type" => "Ready"
        }
      ],
      "nodeInfo" => %{
        "architecture" => "amd64",
        "bootID" =>
          sequence(
            :boot_id,
            &"#{String.duplicate("a", 8)}-#{String.duplicate("b", 4)}-#{String.duplicate("c", 4)}-#{String.duplicate("d", 4)}-#{String.duplicate("e", 12)}#{&1}"
          ),
        "containerRuntimeVersion" => "containerd://1.7.2",
        "kernelVersion" => sequence(:kernel_version, ["5.15.0-72-generic", "5.19.0-45-generic"]),
        "kubeProxyVersion" => sequence(:kube_version, ["v1.28.1", "v1.29.2"]),
        "kubeletVersion" => sequence(:kubelet_version, ["v1.28.1", "v1.29.2"]),
        "machineID" => sequence(:machine_id, &"#{String.duplicate("f", 32)}#{&1}"),
        "operatingSystem" => "linux",
        "osImage" => sequence(:os_image, ["Ubuntu 22.04.3 LTS", "Ubuntu 20.04.6 LTS"]),
        "systemUUID" => Ecto.UUID.autogenerate()
      }
    })
    |> merge_attributes(attrs)
  end

  def deployment_factory(attrs \\ %{}) do
    app_name =
      Map.get_lazy(attrs, :app_name, fn ->
        sequence(:deployment_app, ["web-app", "api-service", "worker", "scheduler"])
      end)

    namespace =
      Map.get_lazy(attrs, :namespace, fn -> sequence(:deployment_namespace, ["app-ns", "service-ns", "data-ns"]) end)

    name = Map.get_lazy(attrs, :name, fn -> sequence(:deployment_name, &"#{app_name}-#{&1}") end)
    owner = Map.get_lazy(attrs, :owner, fn -> BatteryUUID.autogenerate() end)

    :deployment
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(app_name)
    |> B.add_owner(owner)
    |> Map.put("spec", %{
      "progressDeadlineSeconds" => 600,
      "replicas" => sequence(:replicas, [1, 2, 3]),
      "revisionHistoryLimit" => 10,
      "selector" => %{
        "matchLabels" => %{
          "app" => app_name
        }
      },
      "strategy" => %{
        "rollingUpdate" => %{
          "maxSurge" => "25%",
          "maxUnavailable" => "25%"
        },
        "type" => "RollingUpdate"
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "app" => app_name,
            "app.kubernetes.io/name" => app_name,
            "version" => sequence(:pod_version, ["v1.0.0", "v1.1.0", "v2.0.0"])
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "name" => app_name,
              "image" => sequence(:container_image, ["nginx:1.21", "redis:7.0", "postgres:15"]),
              "imagePullPolicy" => "Always",
              "ports" => [
                %{
                  "containerPort" => sequence(:container_port, [8080, 3000, 9090]),
                  "name" => sequence(:container_port_name, ["http", "api", "metrics"]),
                  "protocol" => "TCP"
                }
              ],
              "resources" => %{
                "limits" => %{
                  "cpu" => sequence(:cpu_limit, ["500m", "1000m", "2000m"]),
                  "memory" => sequence(:memory_limit, ["512Mi", "1Gi", "2Gi"])
                },
                "requests" => %{
                  "cpu" => sequence(:cpu_request, ["100m", "250m", "500m"]),
                  "memory" => sequence(:memory_request, ["128Mi", "256Mi", "512Mi"])
                }
              }
            }
          ],
          "restartPolicy" => "Always",
          "terminationGracePeriodSeconds" => 30
        }
      }
    })
    |> Map.put("status", %{
      "availableReplicas" => sequence(:available_replicas, [1, 2, 3]),
      "conditions" => [
        %{
          "lastTransitionTime" => "2025-08-13T09:00:00Z",
          "lastUpdateTime" => "2025-08-13T09:00:00Z",
          "message" => "Deployment has minimum availability.",
          "reason" => "MinimumReplicasAvailable",
          "status" => "True",
          "type" => "Available"
        },
        %{
          "lastTransitionTime" => "2025-08-13T09:00:00Z",
          "lastUpdateTime" => "2025-08-13T09:00:00Z",
          "message" => "ReplicaSet has successfully progressed.",
          "reason" => "NewReplicaSetAvailable",
          "status" => "True",
          "type" => "Progressing"
        }
      ],
      "observedGeneration" => 1,
      "readyReplicas" => sequence(:ready_replicas, [1, 2, 3]),
      "replicas" => sequence(:status_replicas, [1, 2, 3]),
      "updatedReplicas" => sequence(:updated_replicas, [1, 2, 3])
    })
    |> merge_attributes(attrs)
  end

  def stateful_set_factory(attrs \\ %{}) do
    app_name =
      Map.get_lazy(attrs, :app_name, fn -> sequence(:statefulset_app, ["database", "cache", "queue", "storage"]) end)

    namespace =
      Map.get_lazy(attrs, :namespace, fn -> sequence(:statefulset_namespace, ["app-ns", "data-ns", "cache-ns"]) end)

    name =
      Map.get_lazy(attrs, :name, fn -> sequence(:statefulset_name, &"#{app_name}-#{&1}") end)

    owner = Map.get_lazy(attrs, :owner, fn -> BatteryUUID.autogenerate() end)

    :stateful_set
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(app_name)
    |> B.add_owner(owner)
    |> Map.put("spec", %{
      "persistentVolumeClaimRetentionPolicy" => %{
        "whenDeleted" => "Retain",
        "whenScaled" => "Retain"
      },
      "podManagementPolicy" => "OrderedReady",
      "replicas" => sequence(:statefulset_replicas, [1, 3, 5]),
      "revisionHistoryLimit" => 10,
      "selector" => %{
        "matchLabels" => %{
          "app" => app_name
        }
      },
      "serviceName" => app_name,
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "app" => app_name,
            "app.kubernetes.io/name" => app_name,
            "version" => sequence(:statefulset_pod_version, ["v1.0.0", "v1.1.0", "v2.0.0"])
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "name" => app_name,
              "image" => sequence(:statefulset_image, ["postgres:15", "redis:7.0", "mongodb:6.0"]),
              "imagePullPolicy" => "Always",
              "ports" => [
                %{
                  "containerPort" => sequence(:statefulset_port, [5432, 6379, 27_017]),
                  "name" => sequence(:statefulset_port_name, ["postgres", "redis", "mongodb"]),
                  "protocol" => "TCP"
                }
              ],
              "resources" => %{
                "limits" => %{
                  "cpu" => sequence(:statefulset_cpu_limit, ["1000m", "2000m", "4000m"]),
                  "memory" => sequence(:statefulset_memory_limit, ["1Gi", "2Gi", "4Gi"])
                },
                "requests" => %{
                  "cpu" => sequence(:statefulset_cpu_request, ["250m", "500m", "1000m"]),
                  "memory" => sequence(:statefulset_memory_request, ["256Mi", "512Mi", "1Gi"])
                }
              },
              "volumeMounts" => [
                %{
                  "mountPath" => sequence(:mount_path, ["/var/lib/postgresql/data", "/data", "/var/lib/mongodb"]),
                  "name" => "data"
                }
              ]
            }
          ],
          "restartPolicy" => "Always",
          "terminationGracePeriodSeconds" => 30
        }
      },
      "updateStrategy" => %{
        "rollingUpdate" => %{
          "partition" => 0
        },
        "type" => "RollingUpdate"
      },
      "volumeClaimTemplates" => [
        %{
          "metadata" => %{
            "name" => "data"
          },
          "spec" => %{
            "accessModes" => ["ReadWriteOnce"],
            "resources" => %{
              "requests" => %{
                "storage" => sequence(:storage_size, ["10Gi", "20Gi", "50Gi"])
              }
            },
            "storageClassName" => sequence(:storage_class, ["standard", "fast-ssd", "slow-hdd"])
          }
        }
      ]
    })
    |> Map.put("status", %{
      "availableReplicas" => sequence(:statefulset_available, [1, 3, 5]),
      "currentReplicas" => sequence(:statefulset_current, [1, 3, 5]),
      "currentRevision" => sequence(:current_revision, &"#{name}-#{String.duplicate("a", 10)}#{&1}"),
      "observedGeneration" => 1,
      "readyReplicas" => sequence(:statefulset_ready, [1, 3, 5]),
      "replicas" => sequence(:statefulset_status_replicas, [1, 3, 5]),
      "updateRevision" => sequence(:update_revision, &"#{name}-#{String.duplicate("b", 10)}#{&1}"),
      "updatedReplicas" => sequence(:statefulset_updated, [1, 3, 5])
    })
    |> merge_attributes(attrs)
  end

  def pod_factory(attrs \\ %{}) do
    app_name =
      Map.get_lazy(attrs, :app_name, fn -> sequence(:pod_app, ["web-app", "api-service", "worker", "cache"]) end)

    namespace =
      Map.get_lazy(attrs, :namespace, fn -> sequence(:pod_namespace, ["app-ns", "service-ns", "data-ns"]) end)

    name =
      Map.get_lazy(attrs, :name, fn ->
        sequence(:pod_name, &"#{app_name}-#{String.duplicate("a", 5)}#{&1}-#{String.duplicate("x", 5)}")
      end)

    owner = Map.get_lazy(attrs, :owner, fn -> BatteryUUID.autogenerate() end)

    node_name =
      Map.get_lazy(attrs, :node_name, fn -> sequence(:pod_node, ["worker-1", "worker-2", "worker-3"]) end)

    :pod
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(app_name)
    |> B.add_owner(owner)
    |> B.label("pod-template-hash", sequence(:pod_template_hash, &"#{String.duplicate("a", 8)}#{&1}"))
    |> B.label("version", sequence(:pod_label_version, ["v1.0.0", "v1.1.0", "v2.0.0"]))
    |> Map.put("spec", %{
      "containers" => [
        %{
          "name" => app_name,
          "image" => sequence(:pod_image, ["nginx:1.21", "redis:7.0", "postgres:15", "node:18-alpine"]),
          "imagePullPolicy" => sequence(:image_pull_policy, ["Always", "IfNotPresent", "Never"]),
          "ports" => [
            %{
              "containerPort" => sequence(:pod_container_port, [8080, 3000, 9090, 5432]),
              "name" => sequence(:pod_port_name, ["http", "api", "metrics", "database"]),
              "protocol" => "TCP"
            }
          ],
          "env" => [
            %{
              "name" => sequence(:env_name, ["NODE_ENV", "DATABASE_URL", "REDIS_URL", "LOG_LEVEL"]),
              "value" =>
                sequence(:env_value, ["production", "postgres://localhost:5432/app", "redis://localhost:6379", "info"])
            }
          ],
          "resources" => %{
            "limits" => %{
              "cpu" => sequence(:pod_cpu_limit, ["500m", "1000m", "2000m"]),
              "memory" => sequence(:pod_memory_limit, ["512Mi", "1Gi", "2Gi"])
            },
            "requests" => %{
              "cpu" => sequence(:pod_cpu_request, ["100m", "250m", "500m"]),
              "memory" => sequence(:pod_memory_request, ["128Mi", "256Mi", "512Mi"])
            }
          },
          "livenessProbe" => %{
            "httpGet" => %{
              "path" => sequence(:liveness_path, ["/health", "/healthz", "/ping"]),
              "port" => sequence(:liveness_port, [8080, 3000, 9090]),
              "scheme" => "HTTP"
            },
            "initialDelaySeconds" => sequence(:liveness_delay, [10, 15, 30]),
            "periodSeconds" => 10,
            "timeoutSeconds" => 1,
            "failureThreshold" => 3,
            "successThreshold" => 1
          },
          "readinessProbe" => %{
            "httpGet" => %{
              "path" => sequence(:readiness_path, ["/ready", "/readiness", "/status"]),
              "port" => sequence(:readiness_port, [8080, 3000, 9090]),
              "scheme" => "HTTP"
            },
            "initialDelaySeconds" => sequence(:readiness_delay, [5, 10, 15]),
            "periodSeconds" => 10,
            "timeoutSeconds" => 1,
            "failureThreshold" => 3,
            "successThreshold" => 1
          },
          "terminationMessagePath" => "/dev/termination-log",
          "terminationMessagePolicy" => "File",
          "volumeMounts" => [
            %{
              "mountPath" => "/var/run/secrets/kubernetes.io/serviceaccount",
              "name" => sequence(:service_account_volume, &"kube-api-access-#{String.duplicate("x", 5)}#{&1}"),
              "readOnly" => true
            }
          ]
        }
      ],
      "dnsPolicy" => "ClusterFirst",
      "enableServiceLinks" => true,
      "nodeName" => node_name,
      "nodeSelector" => %{
        "kubernetes.io/os" => "linux"
      },
      "preemptionPolicy" => "PreemptLowerPriority",
      "priority" => 0,
      "restartPolicy" => "Always",
      "schedulerName" => "default-scheduler",
      "securityContext" => %{
        "runAsNonRoot" => true,
        "runAsUser" => sequence(:run_as_user, [1000, 1001, 65_534]),
        "fsGroup" => sequence(:fs_group, [1000, 1001, 65_534])
      },
      "serviceAccount" => "#{app_name}-service-account",
      "serviceAccountName" => "#{app_name}-service-account",
      "terminationGracePeriodSeconds" => sequence(:termination_grace, [30, 60, 120]),
      "tolerations" => [
        %{
          "effect" => "NoExecute",
          "key" => "node.kubernetes.io/not-ready",
          "operator" => "Exists",
          "tolerationSeconds" => 300
        },
        %{
          "effect" => "NoExecute",
          "key" => "node.kubernetes.io/unreachable",
          "operator" => "Exists",
          "tolerationSeconds" => 300
        }
      ],
      "volumes" => [
        %{
          "name" => sequence(:volume_name, &"kube-api-access-#{String.duplicate("x", 5)}#{&1}"),
          "projected" => %{
            "defaultMode" => 420,
            "sources" => [
              %{
                "serviceAccountToken" => %{
                  "expirationSeconds" => 3607,
                  "path" => "token"
                }
              },
              %{
                "configMap" => %{
                  "items" => [
                    %{
                      "key" => "ca.crt",
                      "path" => "ca.crt"
                    }
                  ],
                  "name" => "kube-root-ca.crt"
                }
              }
            ]
          }
        }
      ]
    })
    |> Map.put("status", %{
      "conditions" => [
        %{
          "lastProbeTime" => nil,
          "lastTransitionTime" => "2025-08-13T09:00:00Z",
          "status" => "True",
          "type" => "PodReadyToStartContainers"
        },
        %{
          "lastProbeTime" => nil,
          "lastTransitionTime" => "2025-08-13T09:00:00Z",
          "status" => "True",
          "type" => "Initialized"
        },
        %{
          "lastProbeTime" => nil,
          "lastTransitionTime" => "2025-08-13T09:00:30Z",
          "status" => "True",
          "type" => "Ready"
        },
        %{
          "lastProbeTime" => nil,
          "lastTransitionTime" => "2025-08-13T09:00:30Z",
          "status" => "True",
          "type" => "ContainersReady"
        },
        %{
          "lastProbeTime" => nil,
          "lastTransitionTime" => "2025-08-13T09:00:00Z",
          "status" => "True",
          "type" => "PodScheduled"
        }
      ],
      "containerStatuses" => [
        %{
          "containerID" => sequence(:container_id, &"containerd://#{String.duplicate("a", 64)}#{&1}"),
          "image" => sequence(:status_image, ["nginx:1.21", "redis:7.0", "postgres:15", "node:18-alpine"]),
          "imageID" => sequence(:image_id, &"docker.io/library/nginx@sha256:#{String.duplicate("a", 64)}#{&1}"),
          "lastState" => %{},
          "name" => app_name,
          "ready" => true,
          "restartCount" => sequence(:restart_count, [0, 1, 2]),
          "started" => true,
          "state" => %{
            "running" => %{
              "startedAt" => "2025-08-13T09:00:15Z"
            }
          }
        }
      ],
      "hostIP" => sequence(:host_ip, ["172.18.0.2", "172.18.0.3", "172.18.0.4"]),
      "hostIPs" => [
        %{
          "ip" => sequence(:host_ips, ["172.18.0.2", "172.18.0.3", "172.18.0.4"])
        }
      ],
      "phase" => sequence(:pod_phase, ["Running", "Pending", "Succeeded", "Failed"]),
      "podIP" => sequence(:pod_ip, ["10.244.0.7", "10.244.1.8", "10.244.2.9"]),
      "podIPs" => [
        %{
          "ip" => sequence(:pod_ips, ["10.244.0.7", "10.244.1.8", "10.244.2.9"])
        }
      ],
      "qosClass" => sequence(:qos_class, ["BestEffort", "Burstable", "Guaranteed"]),
      "startTime" => "2025-08-13T09:00:00Z"
    })
    |> merge_attributes(attrs)
  end
end
