defmodule KubeResources.NodeExporter do
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeResources.MonitoringSettings, as: Settings
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

    image = Settings.node_exporter_image(battery.config)

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
              "image" => image,
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

  resource(:prometheus_rule_battery_kube_st_node_exporter, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "node-exporter",
          "rules" => [
            %{
              "alert" => "NodeFilesystemSpaceFillingUp",
              "annotations" => %{
                "description" =>
                  "Filesystem on {{ $labels.device }} at {{ $labels.instance }} has only {{ printf \"%.2f\" $value }}% available space left and is filling up.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefilesystemspacefillingup",
                "summary" =>
                  "Filesystem is predicted to run out of space within the next 24 hours."
              },
              "expr" =>
                "(\n  node_filesystem_avail_bytes{job=\"node-exporter\",fstype!=\"\"} / node_filesystem_size_bytes{job=\"node-exporter\",fstype!=\"\"} * 100 < 15\nand\n  predict_linear(node_filesystem_avail_bytes{job=\"node-exporter\",fstype!=\"\"}[6h], 24*60*60) < 0\nand\n  node_filesystem_readonly{job=\"node-exporter\",fstype!=\"\"} == 0\n)",
              "for" => "1h",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeFilesystemSpaceFillingUp",
              "annotations" => %{
                "description" =>
                  "Filesystem on {{ $labels.device }} at {{ $labels.instance }} has only {{ printf \"%.2f\" $value }}% available space left and is filling up fast.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefilesystemspacefillingup",
                "summary" =>
                  "Filesystem is predicted to run out of space within the next 4 hours."
              },
              "expr" =>
                "(\n  node_filesystem_avail_bytes{job=\"node-exporter\",fstype!=\"\"} / node_filesystem_size_bytes{job=\"node-exporter\",fstype!=\"\"} * 100 < 10\nand\n  predict_linear(node_filesystem_avail_bytes{job=\"node-exporter\",fstype!=\"\"}[6h], 4*60*60) < 0\nand\n  node_filesystem_readonly{job=\"node-exporter\",fstype!=\"\"} == 0\n)",
              "for" => "1h",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "NodeFilesystemAlmostOutOfSpace",
              "annotations" => %{
                "description" =>
                  "Filesystem on {{ $labels.device }} at {{ $labels.instance }} has only {{ printf \"%.2f\" $value }}% available space left.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefilesystemalmostoutofspace",
                "summary" => "Filesystem has less than 5% space left."
              },
              "expr" =>
                "(\n  node_filesystem_avail_bytes{job=\"node-exporter\",fstype!=\"\"} / node_filesystem_size_bytes{job=\"node-exporter\",fstype!=\"\"} * 100 < 5\nand\n  node_filesystem_readonly{job=\"node-exporter\",fstype!=\"\"} == 0\n)",
              "for" => "30m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeFilesystemAlmostOutOfSpace",
              "annotations" => %{
                "description" =>
                  "Filesystem on {{ $labels.device }} at {{ $labels.instance }} has only {{ printf \"%.2f\" $value }}% available space left.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefilesystemalmostoutofspace",
                "summary" => "Filesystem has less than 3% space left."
              },
              "expr" =>
                "(\n  node_filesystem_avail_bytes{job=\"node-exporter\",fstype!=\"\"} / node_filesystem_size_bytes{job=\"node-exporter\",fstype!=\"\"} * 100 < 3\nand\n  node_filesystem_readonly{job=\"node-exporter\",fstype!=\"\"} == 0\n)",
              "for" => "30m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "NodeFilesystemFilesFillingUp",
              "annotations" => %{
                "description" =>
                  "Filesystem on {{ $labels.device }} at {{ $labels.instance }} has only {{ printf \"%.2f\" $value }}% available inodes left and is filling up.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefilesystemfilesfillingup",
                "summary" =>
                  "Filesystem is predicted to run out of inodes within the next 24 hours."
              },
              "expr" =>
                "(\n  node_filesystem_files_free{job=\"node-exporter\",fstype!=\"\"} / node_filesystem_files{job=\"node-exporter\",fstype!=\"\"} * 100 < 40\nand\n  predict_linear(node_filesystem_files_free{job=\"node-exporter\",fstype!=\"\"}[6h], 24*60*60) < 0\nand\n  node_filesystem_readonly{job=\"node-exporter\",fstype!=\"\"} == 0\n)",
              "for" => "1h",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeFilesystemFilesFillingUp",
              "annotations" => %{
                "description" =>
                  "Filesystem on {{ $labels.device }} at {{ $labels.instance }} has only {{ printf \"%.2f\" $value }}% available inodes left and is filling up fast.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefilesystemfilesfillingup",
                "summary" =>
                  "Filesystem is predicted to run out of inodes within the next 4 hours."
              },
              "expr" =>
                "(\n  node_filesystem_files_free{job=\"node-exporter\",fstype!=\"\"} / node_filesystem_files{job=\"node-exporter\",fstype!=\"\"} * 100 < 20\nand\n  predict_linear(node_filesystem_files_free{job=\"node-exporter\",fstype!=\"\"}[6h], 4*60*60) < 0\nand\n  node_filesystem_readonly{job=\"node-exporter\",fstype!=\"\"} == 0\n)",
              "for" => "1h",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "NodeFilesystemAlmostOutOfFiles",
              "annotations" => %{
                "description" =>
                  "Filesystem on {{ $labels.device }} at {{ $labels.instance }} has only {{ printf \"%.2f\" $value }}% available inodes left.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefilesystemalmostoutoffiles",
                "summary" => "Filesystem has less than 5% inodes left."
              },
              "expr" =>
                "(\n  node_filesystem_files_free{job=\"node-exporter\",fstype!=\"\"} / node_filesystem_files{job=\"node-exporter\",fstype!=\"\"} * 100 < 5\nand\n  node_filesystem_readonly{job=\"node-exporter\",fstype!=\"\"} == 0\n)",
              "for" => "1h",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeFilesystemAlmostOutOfFiles",
              "annotations" => %{
                "description" =>
                  "Filesystem on {{ $labels.device }} at {{ $labels.instance }} has only {{ printf \"%.2f\" $value }}% available inodes left.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefilesystemalmostoutoffiles",
                "summary" => "Filesystem has less than 3% inodes left."
              },
              "expr" =>
                "(\n  node_filesystem_files_free{job=\"node-exporter\",fstype!=\"\"} / node_filesystem_files{job=\"node-exporter\",fstype!=\"\"} * 100 < 3\nand\n  node_filesystem_readonly{job=\"node-exporter\",fstype!=\"\"} == 0\n)",
              "for" => "1h",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "NodeNetworkReceiveErrs",
              "annotations" => %{
                "description" =>
                  "{{ $labels.instance }} interface {{ $labels.device }} has encountered {{ printf \"%.0f\" $value }} receive errors in the last two minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodenetworkreceiveerrs",
                "summary" => "Network interface is reporting many receive errors."
              },
              "expr" =>
                "rate(node_network_receive_errs_total[2m]) / rate(node_network_receive_packets_total[2m]) > 0.01",
              "for" => "1h",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeNetworkTransmitErrs",
              "annotations" => %{
                "description" =>
                  "{{ $labels.instance }} interface {{ $labels.device }} has encountered {{ printf \"%.0f\" $value }} transmit errors in the last two minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodenetworktransmiterrs",
                "summary" => "Network interface is reporting many transmit errors."
              },
              "expr" =>
                "rate(node_network_transmit_errs_total[2m]) / rate(node_network_transmit_packets_total[2m]) > 0.01",
              "for" => "1h",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeHighNumberConntrackEntriesUsed",
              "annotations" => %{
                "description" =>
                  "{{ $value | humanizePercentage }} of conntrack entries are used.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodehighnumberconntrackentriesused",
                "summary" => "Number of conntrack are getting close to the limit."
              },
              "expr" => "(node_nf_conntrack_entries / node_nf_conntrack_entries_limit) > 0.75",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeTextFileCollectorScrapeError",
              "annotations" => %{
                "description" => "Node Exporter text file collector failed to scrape.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodetextfilecollectorscrapeerror",
                "summary" => "Node Exporter text file collector failed to scrape."
              },
              "expr" => "node_textfile_scrape_error{job=\"node-exporter\"} == 1",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeClockSkewDetected",
              "annotations" => %{
                "description" =>
                  "Clock on {{ $labels.instance }} is out of sync by more than 300s. Ensure NTP is configured correctly on this host.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodeclockskewdetected",
                "summary" => "Clock skew detected."
              },
              "expr" =>
                "(\n  node_timex_offset_seconds{job=\"node-exporter\"} > 0.05\nand\n  deriv(node_timex_offset_seconds{job=\"node-exporter\"}[5m]) >= 0\n)\nor\n(\n  node_timex_offset_seconds{job=\"node-exporter\"} < -0.05\nand\n  deriv(node_timex_offset_seconds{job=\"node-exporter\"}[5m]) <= 0\n)",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeClockNotSynchronising",
              "annotations" => %{
                "description" =>
                  "Clock on {{ $labels.instance }} is not synchronising. Ensure NTP is configured on this host.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodeclocknotsynchronising",
                "summary" => "Clock not synchronising."
              },
              "expr" =>
                "min_over_time(node_timex_sync_status{job=\"node-exporter\"}[5m]) == 0\nand\nnode_timex_maxerror_seconds{job=\"node-exporter\"} >= 16",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeRAIDDegraded",
              "annotations" => %{
                "description" =>
                  "RAID array '{{ $labels.device }}' on {{ $labels.instance }} is in degraded state due to one or more disks failures. Number of spare drives is insufficient to fix issue automatically.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/noderaiddegraded",
                "summary" => "RAID Array is degraded"
              },
              "expr" =>
                "node_md_disks_required{job=\"node-exporter\",device=~\"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+)\"} - ignoring (state) (node_md_disks{state=\"active\",job=\"node-exporter\",device=~\"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+)\"}) > 0",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "NodeRAIDDiskFailure",
              "annotations" => %{
                "description" =>
                  "At least one device in RAID array on {{ $labels.instance }} failed. Array '{{ $labels.device }}' needs attention and possibly a disk swap.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/noderaiddiskfailure",
                "summary" => "Failed device in RAID array"
              },
              "expr" =>
                "node_md_disks{state=\"failed\",job=\"node-exporter\",device=~\"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+)\"} > 0",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeFileDescriptorLimit",
              "annotations" => %{
                "description" =>
                  "File descriptors limit at {{ $labels.instance }} is currently at {{ printf \"%.2f\" $value }}%.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefiledescriptorlimit",
                "summary" => "Kernel is predicted to exhaust file descriptors limit soon."
              },
              "expr" =>
                "(\n  node_filefd_allocated{job=\"node-exporter\"} * 100 / node_filefd_maximum{job=\"node-exporter\"} > 70\n)",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "NodeFileDescriptorLimit",
              "annotations" => %{
                "description" =>
                  "File descriptors limit at {{ $labels.instance }} is currently at {{ printf \"%.2f\" $value }}%.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/node/nodefiledescriptorlimit",
                "summary" => "Kernel is predicted to exhaust file descriptors limit soon."
              },
              "expr" =>
                "(\n  node_filefd_allocated{job=\"node-exporter\"} * 100 / node_filefd_maximum{job=\"node-exporter\"} > 90\n)",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_battery_kube_st_node_exporter_rules, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-node-exporter.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("app", "kube-prometheus-stack")
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

  resource(:prometheus_rule_battery_kube_st_node_network, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-node-network")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "node-network",
          "rules" => [
            %{
              "alert" => "NodeNetworkInterfaceFlapping",
              "annotations" => %{
                "description" =>
                  "Network interface \"{{ $labels.device }}\" changing its up status often on node-exporter {{ $labels.namespace }}/{{ $labels.pod }}",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/general/nodenetworkinterfaceflapping",
                "summary" => "Network interface is often changing its status"
              },
              "expr" =>
                "changes(node_network_up{job=\"node-exporter\",device!~\"veth.+\"}[2m]) > 2",
              "for" => "2m",
              "labels" => %{"severity" => "warning"}
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
