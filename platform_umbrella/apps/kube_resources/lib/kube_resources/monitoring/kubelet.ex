defmodule KubeResources.MonitoringKubelet do
  use KubeExt.IncludeResource,
    kubelet_json: "priv/raw_files/prometheus_stack/kubelet.json"

  use KubeExt.ResourceGenerator
  alias KubeResources.MonitoringSettings, as: Settings

  @app "monitoring_kubelet"

  resource(:config_map, config) do
    namespace = Settings.namespace(config)
    data = %{"kubelet.json" => get_resource(:kubelet_json)}

    B.build_resource(:config_map)
    |> B.name("battery-kube-prometheus-st-kubelet")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "kube-prometheus-stack-grafana")
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:prometheus_rule_kubelet_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kubelet.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubelet.rules",
          "rules" => [
            %{
              "expr" =>
                "histogram_quantile(0.99, sum(rate(kubelet_pleg_relist_duration_seconds_bucket[5m])) by (cluster, instance, le) * on(cluster, instance) group_left(node) kubelet_node_name{job=\"kubelet\", metrics_path=\"/metrics\"})",
              "labels" => %{"quantile" => "0.99"},
              "record" => "node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.9, sum(rate(kubelet_pleg_relist_duration_seconds_bucket[5m])) by (cluster, instance, le) * on(cluster, instance) group_left(node) kubelet_node_name{job=\"kubelet\", metrics_path=\"/metrics\"})",
              "labels" => %{"quantile" => "0.9"},
              "record" => "node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.5, sum(rate(kubelet_pleg_relist_duration_seconds_bucket[5m])) by (cluster, instance, le) * on(cluster, instance) group_left(node) kubelet_node_name{job=\"kubelet\", metrics_path=\"/metrics\"})",
              "labels" => %{"quantile" => "0.5"},
              "record" => "node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile"
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_kubernetes_system_kubelet, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kubernetes-system-kubelet")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-system-kubelet",
          "rules" => [
            %{
              "alert" => "KubeNodeNotReady",
              "annotations" => %{
                "description" => "{{ $labels.node }} has been unready for more than 15 minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubenodenotready",
                "summary" => "Node is not ready."
              },
              "expr" =>
                "kube_node_status_condition{job=\"kube-state-metrics\",condition=\"Ready\",status=\"true\"} == 0",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeNodeUnreachable",
              "annotations" => %{
                "description" =>
                  "{{ $labels.node }} is unreachable and some workloads may be rescheduled.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubenodeunreachable",
                "summary" => "Node is unreachable."
              },
              "expr" =>
                "(kube_node_spec_taint{job=\"kube-state-metrics\",key=\"node.kubernetes.io/unreachable\",effect=\"NoSchedule\"} unless ignoring(key,value) kube_node_spec_taint{job=\"kube-state-metrics\",key=~\"ToBeDeletedByClusterAutoscaler|cloud.google.com/impending-node-termination|aws-node-termination-handler/spot-itn\"}) == 1",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeletTooManyPods",
              "annotations" => %{
                "description" =>
                  "Kubelet '{{ $labels.node }}' is running at {{ $value | humanizePercentage }} of its Pod capacity.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubelettoomanypods",
                "summary" => "Kubelet is running at capacity."
              },
              "expr" =>
                "count by(cluster, node) (\n  (kube_pod_status_phase{job=\"kube-state-metrics\",phase=\"Running\"} == 1) * on(instance,pod,namespace,cluster) group_left(node) topk by(instance,pod,namespace,cluster) (1, kube_pod_info{job=\"kube-state-metrics\"})\n)\n/\nmax by(cluster, node) (\n  kube_node_status_capacity{job=\"kube-state-metrics\",resource=\"pods\"} != 1\n) > 0.95",
              "for" => "15m",
              "labels" => %{"severity" => "info"}
            },
            %{
              "alert" => "KubeNodeReadinessFlapping",
              "annotations" => %{
                "description" =>
                  "The readiness status of node {{ $labels.node }} has changed {{ $value }} times in the last 15 minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubenodereadinessflapping",
                "summary" => "Node readiness status is flapping."
              },
              "expr" =>
                "sum(changes(kube_node_status_condition{status=\"true\",condition=\"Ready\"}[15m])) by (cluster, node) > 2",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeletPlegDurationHigh",
              "annotations" => %{
                "description" =>
                  "The Kubelet Pod Lifecycle Event Generator has a 99th percentile duration of {{ $value }} seconds on node {{ $labels.node }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletplegdurationhigh",
                "summary" => "Kubelet Pod Lifecycle Event Generator is taking too long to relist."
              },
              "expr" =>
                "node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile{quantile=\"0.99\"} >= 10",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeletPodStartUpLatencyHigh",
              "annotations" => %{
                "description" =>
                  "Kubelet Pod startup 99th percentile latency is {{ $value }} seconds on node {{ $labels.node }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletpodstartuplatencyhigh",
                "summary" => "Kubelet Pod startup latency is too high."
              },
              "expr" =>
                "histogram_quantile(0.99, sum(rate(kubelet_pod_worker_duration_seconds_bucket{job=\"kubelet\", metrics_path=\"/metrics\"}[5m])) by (cluster, instance, le)) * on(cluster, instance) group_left(node) kubelet_node_name{job=\"kubelet\", metrics_path=\"/metrics\"} > 60",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeletClientCertificateExpiration",
              "annotations" => %{
                "description" =>
                  "Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletclientcertificateexpiration",
                "summary" => "Kubelet client certificate is about to expire."
              },
              "expr" => "kubelet_certificate_manager_client_ttl_seconds < 604800",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeletClientCertificateExpiration",
              "annotations" => %{
                "description" =>
                  "Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletclientcertificateexpiration",
                "summary" => "Kubelet client certificate is about to expire."
              },
              "expr" => "kubelet_certificate_manager_client_ttl_seconds < 86400",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "KubeletServerCertificateExpiration",
              "annotations" => %{
                "description" =>
                  "Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletservercertificateexpiration",
                "summary" => "Kubelet server certificate is about to expire."
              },
              "expr" => "kubelet_certificate_manager_server_ttl_seconds < 604800",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeletServerCertificateExpiration",
              "annotations" => %{
                "description" =>
                  "Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletservercertificateexpiration",
                "summary" => "Kubelet server certificate is about to expire."
              },
              "expr" => "kubelet_certificate_manager_server_ttl_seconds < 86400",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "KubeletClientCertificateRenewalErrors",
              "annotations" => %{
                "description" =>
                  "Kubelet on node {{ $labels.node }} has failed to renew its client certificate ({{ $value | humanize }} errors in the last 5 minutes).",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletclientcertificaterenewalerrors",
                "summary" => "Kubelet has failed to renew its client certificate."
              },
              "expr" =>
                "increase(kubelet_certificate_manager_client_expiration_renew_errors[5m]) > 0",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeletServerCertificateRenewalErrors",
              "annotations" => %{
                "description" =>
                  "Kubelet on node {{ $labels.node }} has failed to renew its server certificate ({{ $value | humanize }} errors in the last 5 minutes).",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletservercertificaterenewalerrors",
                "summary" => "Kubelet has failed to renew its server certificate."
              },
              "expr" => "increase(kubelet_server_expiration_renew_errors[5m]) > 0",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeletDown",
              "annotations" => %{
                "description" => "Kubelet has disappeared from Prometheus target discovery.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeletdown",
                "summary" => "Target disappeared from Prometheus target discovery."
              },
              "expr" => "absent(up{job=\"kubelet\", metrics_path=\"/metrics\"} == 1)",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_k8s_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-k8s.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "k8s.rules",
          "rules" => [
            %{
              "expr" =>
                "sum by (cluster, namespace, pod, container) (\n  irate(container_cpu_usage_seconds_total{job=\"kubelet\", metrics_path=\"/metrics/cadvisor\", image!=\"\"}[5m])\n) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (\n  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"})\n)",
              "record" =>
                "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
            },
            %{
              "expr" =>
                "container_memory_working_set_bytes{job=\"kubelet\", metrics_path=\"/metrics/cadvisor\", image!=\"\"}\n* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,\n  max by(namespace, pod, node) (kube_pod_info{node!=\"\"})\n)",
              "record" => "node_namespace_pod_container:container_memory_working_set_bytes"
            },
            %{
              "expr" =>
                "container_memory_rss{job=\"kubelet\", metrics_path=\"/metrics/cadvisor\", image!=\"\"}\n* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,\n  max by(namespace, pod, node) (kube_pod_info{node!=\"\"})\n)",
              "record" => "node_namespace_pod_container:container_memory_rss"
            },
            %{
              "expr" =>
                "container_memory_cache{job=\"kubelet\", metrics_path=\"/metrics/cadvisor\", image!=\"\"}\n* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,\n  max by(namespace, pod, node) (kube_pod_info{node!=\"\"})\n)",
              "record" => "node_namespace_pod_container:container_memory_cache"
            },
            %{
              "expr" =>
                "container_memory_swap{job=\"kubelet\", metrics_path=\"/metrics/cadvisor\", image!=\"\"}\n* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,\n  max by(namespace, pod, node) (kube_pod_info{node!=\"\"})\n)",
              "record" => "node_namespace_pod_container:container_memory_swap"
            },
            %{
              "expr" =>
                "kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)\ngroup_left() max by (namespace, pod, cluster) (\n  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)\n)",
              "record" =>
                "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests"
            },
            %{
              "expr" =>
                "sum by (namespace, cluster) (\n    sum by (namespace, pod, cluster) (\n        max by (namespace, pod, container, cluster) (\n          kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}\n        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (\n          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1\n        )\n    )\n)",
              "record" => "namespace_memory:kube_pod_container_resource_requests:sum"
            },
            %{
              "expr" =>
                "kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)\ngroup_left() max by (namespace, pod, cluster) (\n  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)\n)",
              "record" => "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests"
            },
            %{
              "expr" =>
                "sum by (namespace, cluster) (\n    sum by (namespace, pod, cluster) (\n        max by (namespace, pod, container, cluster) (\n          kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}\n        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (\n          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1\n        )\n    )\n)",
              "record" => "namespace_cpu:kube_pod_container_resource_requests:sum"
            },
            %{
              "expr" =>
                "kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)\ngroup_left() max by (namespace, pod, cluster) (\n  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)\n)",
              "record" => "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits"
            },
            %{
              "expr" =>
                "sum by (namespace, cluster) (\n    sum by (namespace, pod, cluster) (\n        max by (namespace, pod, container, cluster) (\n          kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}\n        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (\n          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1\n        )\n    )\n)",
              "record" => "namespace_memory:kube_pod_container_resource_limits:sum"
            },
            %{
              "expr" =>
                "kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)\ngroup_left() max by (namespace, pod, cluster) (\n (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)\n )",
              "record" => "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits"
            },
            %{
              "expr" =>
                "sum by (namespace, cluster) (\n    sum by (namespace, pod, cluster) (\n        max by (namespace, pod, container, cluster) (\n          kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}\n        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (\n          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1\n        )\n    )\n)",
              "record" => "namespace_cpu:kube_pod_container_resource_limits:sum"
            },
            %{
              "expr" =>
                "max by (cluster, namespace, workload, pod) (\n  label_replace(\n    label_replace(\n      kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"ReplicaSet\"},\n      \"replicaset\", \"$1\", \"owner_name\", \"(.*)\"\n    ) * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (\n      1, max by (replicaset, namespace, owner_name) (\n        kube_replicaset_owner{job=\"kube-state-metrics\"}\n      )\n    ),\n    \"workload\", \"$1\", \"owner_name\", \"(.*)\"\n  )\n)",
              "labels" => %{"workload_type" => "deployment"},
              "record" => "namespace_workload_pod:kube_pod_owner:relabel"
            },
            %{
              "expr" =>
                "max by (cluster, namespace, workload, pod) (\n  label_replace(\n    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"DaemonSet\"},\n    \"workload\", \"$1\", \"owner_name\", \"(.*)\"\n  )\n)",
              "labels" => %{"workload_type" => "daemonset"},
              "record" => "namespace_workload_pod:kube_pod_owner:relabel"
            },
            %{
              "expr" =>
                "max by (cluster, namespace, workload, pod) (\n  label_replace(\n    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"StatefulSet\"},\n    \"workload\", \"$1\", \"owner_name\", \"(.*)\"\n  )\n)",
              "labels" => %{"workload_type" => "statefulset"},
              "record" => "namespace_workload_pod:kube_pod_owner:relabel"
            },
            %{
              "expr" =>
                "max by (cluster, namespace, workload, pod) (\n  label_replace(\n    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"Job\"},\n    \"workload\", \"$1\", \"owner_name\", \"(.*)\"\n  )\n)",
              "labels" => %{"workload_type" => "job"},
              "record" => "namespace_workload_pod:kube_pod_owner:relabel"
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_kubernetes_storage, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kubernetes-storage")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-storage",
          "rules" => [
            %{
              "alert" => "KubePersistentVolumeFillingUp",
              "annotations" => %{
                "description" =>
                  "The PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is only {{ $value | humanizePercentage }} free.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubepersistentvolumefillingup",
                "summary" => "PersistentVolume is filling up."
              },
              "expr" =>
                "(\n  kubelet_volume_stats_available_bytes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}\n    /\n  kubelet_volume_stats_capacity_bytes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}\n) < 0.03\nand\nkubelet_volume_stats_used_bytes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"} > 0\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_access_mode{ access_mode=\"ReadOnlyMany\"} == 1\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_labels{label_excluded_from_alerts=\"true\"} == 1",
              "for" => "1m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "KubePersistentVolumeFillingUp",
              "annotations" => %{
                "description" =>
                  "Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to fill up within four days. Currently {{ $value | humanizePercentage }} is available.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubepersistentvolumefillingup",
                "summary" => "PersistentVolume is filling up."
              },
              "expr" =>
                "(\n  kubelet_volume_stats_available_bytes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}\n    /\n  kubelet_volume_stats_capacity_bytes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}\n) < 0.15\nand\nkubelet_volume_stats_used_bytes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"} > 0\nand\npredict_linear(kubelet_volume_stats_available_bytes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}[6h], 4 * 24 * 3600) < 0\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_access_mode{ access_mode=\"ReadOnlyMany\"} == 1\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_labels{label_excluded_from_alerts=\"true\"} == 1",
              "for" => "1h",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubePersistentVolumeInodesFillingUp",
              "annotations" => %{
                "description" =>
                  "The PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} only has {{ $value | humanizePercentage }} free inodes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubepersistentvolumeinodesfillingup",
                "summary" => "PersistentVolumeInodes are filling up."
              },
              "expr" =>
                "(\n  kubelet_volume_stats_inodes_free{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}\n    /\n  kubelet_volume_stats_inodes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}\n) < 0.03\nand\nkubelet_volume_stats_inodes_used{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"} > 0\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_access_mode{ access_mode=\"ReadOnlyMany\"} == 1\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_labels{label_excluded_from_alerts=\"true\"} == 1",
              "for" => "1m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "KubePersistentVolumeInodesFillingUp",
              "annotations" => %{
                "description" =>
                  "Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to run out of inodes within four days. Currently {{ $value | humanizePercentage }} of its inodes are free.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubepersistentvolumeinodesfillingup",
                "summary" => "PersistentVolumeInodes are filling up."
              },
              "expr" =>
                "(\n  kubelet_volume_stats_inodes_free{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}\n    /\n  kubelet_volume_stats_inodes{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}\n) < 0.15\nand\nkubelet_volume_stats_inodes_used{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"} > 0\nand\npredict_linear(kubelet_volume_stats_inodes_free{job=\"kubelet\", namespace=~\".*\", metrics_path=\"/metrics\"}[6h], 4 * 24 * 3600) < 0\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_access_mode{ access_mode=\"ReadOnlyMany\"} == 1\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_labels{label_excluded_from_alerts=\"true\"} == 1",
              "for" => "1h",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubePersistentVolumeErrors",
              "annotations" => %{
                "description" =>
                  "The persistent volume {{ $labels.persistentvolume }} has status {{ $labels.phase }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubepersistentvolumeerrors",
                "summary" => "PersistentVolume is having issues with provisioning."
              },
              "expr" =>
                "kube_persistentvolume_status_phase{phase=~\"Failed|Pending\",job=\"kube-state-metrics\"} > 0",
              "for" => "5m",
              "labels" => %{"severity" => "critical"}
            }
          ]
        }
      ]
    })
  end

  resource(:service_monitor, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_monitor)
    |> B.name("battery-prometheus-kubelet")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "endpoints" => [
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "honorLabels" => true,
          "port" => "https-metrics",
          "relabelings" => [
            %{"sourceLabels" => ["__metrics_path__"], "targetLabel" => "metrics_path"}
          ],
          "scheme" => "https",
          "tlsConfig" => %{
            "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
            "insecureSkipVerify" => true
          }
        },
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "honorLabels" => true,
          "metricRelabelings" => [
            %{
              "action" => "drop",
              "regex" =>
                "container_cpu_(cfs_throttled_seconds_total|load_average_10s|system_seconds_total|user_seconds_total)",
              "sourceLabels" => ["__name__"]
            },
            %{
              "action" => "drop",
              "regex" =>
                "container_fs_(io_current|io_time_seconds_total|io_time_weighted_seconds_total|reads_merged_total|sector_reads_total|sector_writes_total|writes_merged_total)",
              "sourceLabels" => ["__name__"]
            },
            %{
              "action" => "drop",
              "regex" => "container_memory_(mapped_file|swap)",
              "sourceLabels" => ["__name__"]
            },
            %{
              "action" => "drop",
              "regex" => "container_(file_descriptors|tasks_state|threads_max)",
              "sourceLabels" => ["__name__"]
            },
            %{"action" => "drop", "regex" => "container_spec.*", "sourceLabels" => ["__name__"]},
            %{"action" => "drop", "regex" => ".+;", "sourceLabels" => ["id", "pod"]}
          ],
          "path" => "/metrics/cadvisor",
          "port" => "https-metrics",
          "relabelings" => [
            %{"sourceLabels" => ["__metrics_path__"], "targetLabel" => "metrics_path"}
          ],
          "scheme" => "https",
          "tlsConfig" => %{
            "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
            "insecureSkipVerify" => true
          }
        },
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "honorLabels" => true,
          "path" => "/metrics/probes",
          "port" => "https-metrics",
          "relabelings" => [
            %{"sourceLabels" => ["__metrics_path__"], "targetLabel" => "metrics_path"}
          ],
          "scheme" => "https",
          "tlsConfig" => %{
            "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
            "insecureSkipVerify" => true
          }
        }
      ],
      "jobLabel" => "k8s-app",
      "namespaceSelector" => %{"matchNames" => ["kube-system"]},
      "selector" => %{
        "matchLabels" => %{"k8s-app" => "kubelet"}
      }
    })
  end
end
