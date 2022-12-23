defmodule KubeResources.NodeExporter do
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "node-exporter"

  resource(:service_account_battery_prometheus_node_exporter, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> Map.put("imagePullSecrets", [])
    |> B.name("battery-prometheus-node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_battery_prometheus_node_exporter, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service)
    |> B.name("battery-prometheus-node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "ports" => [
        %{"name" => "http-metrics", "port" => 9100, "protocol" => "TCP", "targetPort" => 9100}
      ],
      "selector" => %{
        "battery/app" => @app_name,
        "battery/component" => "prometheus-node-exporter"
      },
      "type" => "ClusterIP"
    })
  end

  resource(:daemon_set_battery_prometheus_node_exporter, battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:daemon_set)
    |> B.name("battery-prometheus-node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("prometheus-node-exporter")
    |> B.spec(%{
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "battery/component" => "prometheus-node-exporter"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app_name,
            "battery/component" => "prometheus-node-exporter",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "automountServiceAccountToken" => false,
          "containers" => [
            %{
              "args" => [
                "--path.procfs=/host/proc",
                "--path.sysfs=/host/sys",
                "--path.rootfs=/host/root",
                "--web.listen-address=[$(HOST_IP)]:9100",
                "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)",
                "--collector.filesystem.fs-types-exclude=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
              ],
              "env" => [%{"name" => "HOST_IP", "value" => "0.0.0.0"}],
              "image" => battery.config.image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{
                  "httpHeaders" => nil,
                  "path" => "/",
                  "port" => 9100,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 0,
                "periodSeconds" => 10,
                "successThreshold" => 1,
                "timeoutSeconds" => 1
              },
              "name" => "node-exporter",
              "ports" => [
                %{"containerPort" => 9100, "name" => "http-metrics", "protocol" => "TCP"}
              ],
              "readinessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{
                  "httpHeaders" => nil,
                  "path" => "/",
                  "port" => 9100,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 0,
                "periodSeconds" => 10,
                "successThreshold" => 1,
                "timeoutSeconds" => 1
              },
              "resources" => %{},
              "volumeMounts" => [
                %{"mountPath" => "/host/proc", "name" => "proc", "readOnly" => true},
                %{"mountPath" => "/host/sys", "name" => "sys", "readOnly" => true},
                %{
                  "mountPath" => "/host/root",
                  # "mountPropagation" => "HostToContainer",
                  "name" => "root",
                  "readOnly" => true
                }
              ]
            }
          ],
          "hostNetwork" => true,
          "hostPID" => true,
          "securityContext" => %{
            "fsGroup" => 65_534,
            "runAsGroup" => 65_534,
            "runAsNonRoot" => true,
            "runAsUser" => 65_534
          },
          "serviceAccountName" => "battery-prometheus-node-exporter",
          "tolerations" => [%{"effect" => "NoSchedule", "operator" => "Exists"}],
          "volumes" => [
            %{"hostPath" => %{"path" => "/proc"}, "name" => "proc"},
            %{"hostPath" => %{"path" => "/sys"}, "name" => "sys"},
            %{"hostPath" => %{"path" => "/"}, "name" => "root"}
          ]
        }
      },
      "updateStrategy" => %{
        "rollingUpdate" => %{"maxUnavailable" => 1},
        "type" => "RollingUpdate"
      }
    })
  end

  resource(:prometheus_rule_battery_kube_st_node_exporter_rules, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-node-exporter.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "node-exporter.rules",
          "rules" => [
            %{
              "expr" =>
                "count without (cpu, mode) (\n  node_cpu_seconds_total{job=\"node-exporter\",mode=\"idle\"}\n)",
              "record" => "instance:node_num_cpu:sum"
            },
            %{
              "expr" =>
                "1 - avg without (cpu) (\n  sum without (mode) (rate(node_cpu_seconds_total{job=\"node-exporter\", mode=~\"idle|iowait|steal\"}[5m]))\n)",
              "record" => "instance:node_cpu_utilisation:rate5m"
            },
            %{
              "expr" =>
                "(\n  node_load1{job=\"node-exporter\"}\n/\n  instance:node_num_cpu:sum{job=\"node-exporter\"}\n)",
              "record" => "instance:node_load1_per_cpu:ratio"
            },
            %{
              "expr" =>
                "1 - (\n  (\n    node_memory_MemAvailable_bytes{job=\"node-exporter\"}\n    or\n    (\n      node_memory_Buffers_bytes{job=\"node-exporter\"}\n      +\n      node_memory_Cached_bytes{job=\"node-exporter\"}\n      +\n      node_memory_MemFree_bytes{job=\"node-exporter\"}\n      +\n      node_memory_Slab_bytes{job=\"node-exporter\"}\n    )\n  )\n/\n  node_memory_MemTotal_bytes{job=\"node-exporter\"}\n)",
              "record" => "instance:node_memory_utilisation:ratio"
            },
            %{
              "expr" => "rate(node_vmstat_pgmajfault{job=\"node-exporter\"}[5m])",
              "record" => "instance:node_vmstat_pgmajfault:rate5m"
            },
            %{
              "expr" =>
                "rate(node_disk_io_time_seconds_total{job=\"node-exporter\", device=~\"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+)\"}[5m])",
              "record" => "instance_device:node_disk_io_time_seconds:rate5m"
            },
            %{
              "expr" =>
                "rate(node_disk_io_time_weighted_seconds_total{job=\"node-exporter\", device=~\"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+)\"}[5m])",
              "record" => "instance_device:node_disk_io_time_weighted_seconds:rate5m"
            },
            %{
              "expr" =>
                "sum without (device) (\n  rate(node_network_receive_bytes_total{job=\"node-exporter\", device!=\"lo\"}[5m])\n)",
              "record" => "instance:node_network_receive_bytes_excluding_lo:rate5m"
            },
            %{
              "expr" =>
                "sum without (device) (\n  rate(node_network_transmit_bytes_total{job=\"node-exporter\", device!=\"lo\"}[5m])\n)",
              "record" => "instance:node_network_transmit_bytes_excluding_lo:rate5m"
            },
            %{
              "expr" =>
                "sum without (device) (\n  rate(node_network_receive_drop_total{job=\"node-exporter\", device!=\"lo\"}[5m])\n)",
              "record" => "instance:node_network_receive_drop_excluding_lo:rate5m"
            },
            %{
              "expr" =>
                "sum without (device) (\n  rate(node_network_transmit_drop_total{job=\"node-exporter\", device!=\"lo\"}[5m])\n)",
              "record" => "instance:node_network_transmit_drop_excluding_lo:rate5m"
            }
          ]
        }
      ]
    })
  end

  resource(:service_monitor, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_monitor)
    |> B.name("battery-prometheus-node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "endpoints" => [%{"port" => "http-metrics", "scheme" => "http"}],
      "jobLabel" => "battery/app",
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app_name
        }
      }
    })
  end
end
