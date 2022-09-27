defmodule KubeResources.PrometheusStack do
  use KubeExt.IncludeResource,
    alertmanager_overview_json: "priv/raw_files/prometheus_stack/alertmanager-overview.json",
    apiserver_json: "priv/raw_files/prometheus_stack/apiserver.json",
    cluster_total_json: "priv/raw_files/prometheus_stack/cluster-total.json",
    controller_manager_json: "priv/raw_files/prometheus_stack/controller-manager.json",
    grafana_overview_json: "priv/raw_files/prometheus_stack/grafana-overview.json",
    k8s_coredns_json: "priv/raw_files/prometheus_stack/k8s-coredns.json",
    k8s_resources_cluster_json: "priv/raw_files/prometheus_stack/k8s-resources-cluster.json",
    k8s_resources_namespace_json: "priv/raw_files/prometheus_stack/k8s-resources-namespace.json",
    k8s_resources_node_json: "priv/raw_files/prometheus_stack/k8s-resources-node.json",
    k8s_resources_pod_json: "priv/raw_files/prometheus_stack/k8s-resources-pod.json",
    k8s_resources_workload_json: "priv/raw_files/prometheus_stack/k8s-resources-workload.json",
    k8s_resources_workloads_namespace_json:
      "priv/raw_files/prometheus_stack/k8s-resources-workloads-namespace.json",
    namespace_by_pod_json: "priv/raw_files/prometheus_stack/namespace-by-pod.json",
    namespace_by_workload_json: "priv/raw_files/prometheus_stack/namespace-by-workload.json",
    node_cluster_rsrc_use_json: "priv/raw_files/prometheus_stack/node-cluster-rsrc-use.json",
    node_rsrc_use_json: "priv/raw_files/prometheus_stack/node-rsrc-use.json",
    nodes_darwin_json: "priv/raw_files/prometheus_stack/nodes-darwin.json",
    nodes_json: "priv/raw_files/prometheus_stack/nodes.json",
    persistentvolumesusage_json: "priv/raw_files/prometheus_stack/persistentvolumesusage.json",
    pod_total_json: "priv/raw_files/prometheus_stack/pod-total.json",
    prometheus_json: "priv/raw_files/prometheus_stack/prometheus.json",
    workload_total_json: "priv/raw_files/prometheus_stack/workload-total.json"

  use KubeExt.ResourceGenerator

  alias KubeResources.MonitoringSettings, as: Settings

  @app "prometheus_stack"

  resource(:config_map_alertmanager_overview, config) do
    namespace = Settings.namespace(config)
    data = %{"alertmanager-overview.json" => get_resource(:alertmanager_overview_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-alertmanager-overview")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_cluster_total, config) do
    namespace = Settings.namespace(config)
    data = %{"cluster-total.json" => get_resource(:cluster_total_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-cluster-total")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_grafana_overview, config) do
    namespace = Settings.namespace(config)
    data = %{"grafana-overview.json" => get_resource(:grafana_overview_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-grafana-overview")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_coredns, config) do
    namespace = Settings.namespace(config)
    data = %{"k8s-coredns.json" => get_resource(:k8s_coredns_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-coredns")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_cluster, config) do
    namespace = Settings.namespace(config)
    data = %{"k8s-resources-cluster.json" => get_resource(:k8s_resources_cluster_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-cluster")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_namespace, config) do
    namespace = Settings.namespace(config)

    data = %{"k8s-resources-namespace.json" => get_resource(:k8s_resources_namespace_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-namespace")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_node, config) do
    namespace = Settings.namespace(config)
    data = %{"k8s-resources-node.json" => get_resource(:k8s_resources_node_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-node")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_pod, config) do
    namespace = Settings.namespace(config)
    data = %{"k8s-resources-pod.json" => get_resource(:k8s_resources_pod_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-pod")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_workload, config) do
    namespace = Settings.namespace(config)

    data = %{"k8s-resources-workload.json" => get_resource(:k8s_resources_workload_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-workload")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_workloads_namespace, config) do
    namespace = Settings.namespace(config)

    data = %{
      "k8s-resources-workloads-namespace.json" =>
        get_resource(:k8s_resources_workloads_namespace_json)
    }

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-workloads-namespace")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_namespace_by_pod, config) do
    namespace = Settings.namespace(config)
    data = %{"namespace-by-pod.json" => get_resource(:namespace_by_pod_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-namespace-by-pod")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_namespace_by_workload, config) do
    namespace = Settings.namespace(config)
    data = %{"namespace-by-workload.json" => get_resource(:namespace_by_workload_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-namespace-by-workload")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_node_cluster_rsrc_use, config) do
    namespace = Settings.namespace(config)
    data = %{"node-cluster-rsrc-use.json" => get_resource(:node_cluster_rsrc_use_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-node-cluster-rsrc-use")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_node_rsrc_use, config) do
    namespace = Settings.namespace(config)
    data = %{"node-rsrc-use.json" => get_resource(:node_rsrc_use_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-node-rsrc-use")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_nodes, config) do
    namespace = Settings.namespace(config)
    data = %{"nodes.json" => get_resource(:nodes_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-nodes")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_nodes_darwin, config) do
    namespace = Settings.namespace(config)
    data = %{"nodes-darwin.json" => get_resource(:nodes_darwin_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-nodes-darwin")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_persistentvolumesusage, config) do
    namespace = Settings.namespace(config)

    data = %{"persistentvolumesusage.json" => get_resource(:persistentvolumesusage_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-persistentvolumesusage")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_pod_total, config) do
    namespace = Settings.namespace(config)
    data = %{"pod-total.json" => get_resource(:pod_total_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-pod-total")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_prometheus, config) do
    namespace = Settings.namespace(config)
    data = %{"prometheus.json" => get_resource(:prometheus_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-prometheus")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_workload_total, config) do
    namespace = Settings.namespace(config)
    data = %{"workload-total.json" => get_resource(:workload_total_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-workload-total")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:prometheus_rule_config_reloaders, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-config-reloaders")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "config-reloaders",
          "rules" => [
            %{
              "alert" => "ConfigReloaderSidecarErrors",
              "annotations" => %{
                "description" =>
                  "Errors encountered while the {{$labels.pod}} config-reloader sidecar attempts to sync config in {{$labels.namespace}} namespace.\nAs a result, configuration for service running in {{$labels.pod}} may be stale and cannot be updated anymore.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/prometheus-operator/configreloadersidecarerrors",
                "summary" => "config-reloader sidecar has not had a successful reload for 10m"
              },
              "expr" =>
                "max_over_time(reloader_last_reload_successful{namespace=~\".+\"}[5m]) == 0",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_general_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-general.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "general.rules",
          "rules" => [
            %{
              "alert" => "TargetDown",
              "annotations" => %{
                "description" =>
                  "{{ printf \"%.4g\" $value }}% of the {{ $labels.job }}/{{ $labels.service }} targets in {{ $labels.namespace }} namespace are down.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/general/targetdown",
                "summary" => "One or more targets are unreachable."
              },
              "expr" =>
                "100 * (count(up == 0) BY (job, namespace, service) / count(up) BY (job, namespace, service)) > 10",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "Watchdog",
              "annotations" => %{
                "description" =>
                  "This is an alert meant to ensure that the entire alerting pipeline is functional.\nThis alert is always firing, therefore it should always be firing in Alertmanager\nand always fire against a receiver. There are integrations with various notification\nmechanisms that send a notification when this alert is not firing. For example the\n\"DeadMansSnitch\" integration in PagerDuty.\n",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/general/watchdog",
                "summary" =>
                  "An alert that should always be firing to certify that Alertmanager is working properly."
              },
              "expr" => "vector(1)",
              "labels" => %{"severity" => "none"}
            },
            %{
              "alert" => "InfoInhibitor",
              "annotations" => %{
                "description" =>
                  "This is an alert that is used to inhibit info alerts.\nBy themselves, the info-level alerts are sometimes very noisy, but they are relevant when combined with\nother alerts.\nThis alert fires whenever there's a severity=\"info\" alert, and stops firing when another alert with a\nseverity of 'warning' or 'critical' starts firing on the same namespace.\nThis alert should be routed to a null receiver and configured to inhibit alerts with severity=\"info\".\n",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/general/infoinhibitor",
                "summary" => "Info-level alert inhibition."
              },
              "expr" =>
                "ALERTS{severity = \"info\"} == 1 unless on(namespace) ALERTS{alertname != \"InfoInhibitor\", severity =~ \"warning|critical\", alertstate=\"firing\"} == 1",
              "labels" => %{"severity" => "none"}
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_kube_general_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kube-prometheus-general.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kube-prometheus-general.rules",
          "rules" => [
            %{"expr" => "count without(instance, pod, node) (up == 1)", "record" => "count:up1"},
            %{"expr" => "count without(instance, pod, node) (up == 0)", "record" => "count:up0"}
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_kube_node_recording_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kube-prometheus-node-recording.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kube-prometheus-node-recording.rules",
          "rules" => [
            %{
              "expr" =>
                "sum(rate(node_cpu_seconds_total{mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[3m])) BY (instance)",
              "record" => "instance:node_cpu:rate:sum"
            },
            %{
              "expr" => "sum(rate(node_network_receive_bytes_total[3m])) BY (instance)",
              "record" => "instance:node_network_receive_bytes:rate:sum"
            },
            %{
              "expr" => "sum(rate(node_network_transmit_bytes_total[3m])) BY (instance)",
              "record" => "instance:node_network_transmit_bytes:rate:sum"
            },
            %{
              "expr" =>
                "sum(rate(node_cpu_seconds_total{mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m])) WITHOUT (cpu, mode) / ON(instance) GROUP_LEFT() count(sum(node_cpu_seconds_total) BY (instance, cpu)) BY (instance)",
              "record" => "instance:node_cpu:ratio"
            },
            %{
              "expr" =>
                "sum(rate(node_cpu_seconds_total{mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m]))",
              "record" => "cluster:node_cpu:sum_rate5m"
            },
            %{
              "expr" =>
                "cluster:node_cpu:sum_rate5m / count(sum(node_cpu_seconds_total) BY (instance, cpu))",
              "record" => "cluster:node_cpu:ratio"
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_kubernetes_apps, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kubernetes-apps")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-apps",
          "rules" => [
            %{
              "alert" => "KubePodCrashLooping",
              "annotations" => %{
                "description" =>
                  "Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is in waiting state (reason: \"CrashLoopBackOff\").",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubepodcrashlooping",
                "summary" => "Pod is crash looping."
              },
              "expr" =>
                "max_over_time(kube_pod_container_status_waiting_reason{reason=\"CrashLoopBackOff\", job=\"kube-state-metrics\", namespace=~\".*\"}[5m]) >= 1",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubePodNotReady",
              "annotations" => %{
                "description" =>
                  "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready state for longer than 15 minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubepodnotready",
                "summary" => "Pod has been in a non-ready state for more than 15 minutes."
              },
              "expr" =>
                "sum by (namespace, pod, cluster) (\n  max by(namespace, pod, cluster) (\n    kube_pod_status_phase{job=\"kube-state-metrics\", namespace=~\".*\", phase=~\"Pending|Unknown\"}\n  ) * on(namespace, pod, cluster) group_left(owner_kind) topk by(namespace, pod, cluster) (\n    1, max by(namespace, pod, owner_kind, cluster) (kube_pod_owner{owner_kind!=\"Job\"})\n  )\n) > 0",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeDeploymentGenerationMismatch",
              "annotations" => %{
                "description" =>
                  "Deployment generation for {{ $labels.namespace }}/{{ $labels.deployment }} does not match, this indicates that the Deployment has failed but has not been rolled back.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubedeploymentgenerationmismatch",
                "summary" => "Deployment generation mismatch due to possible roll-back"
              },
              "expr" =>
                "kube_deployment_status_observed_generation{job=\"kube-state-metrics\", namespace=~\".*\"}\n  !=\nkube_deployment_metadata_generation{job=\"kube-state-metrics\", namespace=~\".*\"}",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeDeploymentReplicasMismatch",
              "annotations" => %{
                "description" =>
                  "Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has not matched the expected number of replicas for longer than 15 minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubedeploymentreplicasmismatch",
                "summary" => "Deployment has not matched the expected number of replicas."
              },
              "expr" =>
                "(\n  kube_deployment_spec_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}\n    >\n  kube_deployment_status_replicas_available{job=\"kube-state-metrics\", namespace=~\".*\"}\n) and (\n  changes(kube_deployment_status_replicas_updated{job=\"kube-state-metrics\", namespace=~\".*\"}[10m])\n    ==\n  0\n)",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeStatefulSetReplicasMismatch",
              "annotations" => %{
                "description" =>
                  "StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} has not matched the expected number of replicas for longer than 15 minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubestatefulsetreplicasmismatch",
                "summary" => "Deployment has not matched the expected number of replicas."
              },
              "expr" =>
                "(\n  kube_statefulset_status_replicas_ready{job=\"kube-state-metrics\", namespace=~\".*\"}\n    !=\n  kube_statefulset_status_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}\n) and (\n  changes(kube_statefulset_status_replicas_updated{job=\"kube-state-metrics\", namespace=~\".*\"}[10m])\n    ==\n  0\n)",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeStatefulSetGenerationMismatch",
              "annotations" => %{
                "description" =>
                  "StatefulSet generation for {{ $labels.namespace }}/{{ $labels.statefulset }} does not match, this indicates that the StatefulSet has failed but has not been rolled back.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubestatefulsetgenerationmismatch",
                "summary" => "StatefulSet generation mismatch due to possible roll-back"
              },
              "expr" =>
                "kube_statefulset_status_observed_generation{job=\"kube-state-metrics\", namespace=~\".*\"}\n  !=\nkube_statefulset_metadata_generation{job=\"kube-state-metrics\", namespace=~\".*\"}",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeStatefulSetUpdateNotRolledOut",
              "annotations" => %{
                "description" =>
                  "StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} update has not been rolled out.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubestatefulsetupdatenotrolledout",
                "summary" => "StatefulSet update has not been rolled out."
              },
              "expr" =>
                "(\n  max without (revision) (\n    kube_statefulset_status_current_revision{job=\"kube-state-metrics\", namespace=~\".*\"}\n      unless\n    kube_statefulset_status_update_revision{job=\"kube-state-metrics\", namespace=~\".*\"}\n  )\n    *\n  (\n    kube_statefulset_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}\n      !=\n    kube_statefulset_status_replicas_updated{job=\"kube-state-metrics\", namespace=~\".*\"}\n  )\n)  and (\n  changes(kube_statefulset_status_replicas_updated{job=\"kube-state-metrics\", namespace=~\".*\"}[5m])\n    ==\n  0\n)",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeDaemonSetRolloutStuck",
              "annotations" => %{
                "description" =>
                  "DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} has not finished or progressed for at least 15 minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubedaemonsetrolloutstuck",
                "summary" => "DaemonSet rollout is stuck."
              },
              "expr" =>
                "(\n  (\n    kube_daemonset_status_current_number_scheduled{job=\"kube-state-metrics\", namespace=~\".*\"}\n     !=\n    kube_daemonset_status_desired_number_scheduled{job=\"kube-state-metrics\", namespace=~\".*\"}\n  ) or (\n    kube_daemonset_status_number_misscheduled{job=\"kube-state-metrics\", namespace=~\".*\"}\n     !=\n    0\n  ) or (\n    kube_daemonset_status_updated_number_scheduled{job=\"kube-state-metrics\", namespace=~\".*\"}\n     !=\n    kube_daemonset_status_desired_number_scheduled{job=\"kube-state-metrics\", namespace=~\".*\"}\n  ) or (\n    kube_daemonset_status_number_available{job=\"kube-state-metrics\", namespace=~\".*\"}\n     !=\n    kube_daemonset_status_desired_number_scheduled{job=\"kube-state-metrics\", namespace=~\".*\"}\n  )\n) and (\n  changes(kube_daemonset_status_updated_number_scheduled{job=\"kube-state-metrics\", namespace=~\".*\"}[5m])\n    ==\n  0\n)",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeContainerWaiting",
              "annotations" => %{
                "description" =>
                  "pod/{{ $labels.pod }} in namespace {{ $labels.namespace }} on container {{ $labels.container}} has been in waiting state for longer than 1 hour.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubecontainerwaiting",
                "summary" => "Pod container waiting longer than 1 hour"
              },
              "expr" =>
                "sum by (namespace, pod, container, cluster) (kube_pod_container_status_waiting_reason{job=\"kube-state-metrics\", namespace=~\".*\"}) > 0",
              "for" => "1h",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeDaemonSetNotScheduled",
              "annotations" => %{
                "description" =>
                  "{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are not scheduled.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubedaemonsetnotscheduled",
                "summary" => "DaemonSet pods are not scheduled."
              },
              "expr" =>
                "kube_daemonset_status_desired_number_scheduled{job=\"kube-state-metrics\", namespace=~\".*\"}\n  -\nkube_daemonset_status_current_number_scheduled{job=\"kube-state-metrics\", namespace=~\".*\"} > 0",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeDaemonSetMisScheduled",
              "annotations" => %{
                "description" =>
                  "{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are running where they are not supposed to run.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubedaemonsetmisscheduled",
                "summary" => "DaemonSet pods are misscheduled."
              },
              "expr" =>
                "kube_daemonset_status_number_misscheduled{job=\"kube-state-metrics\", namespace=~\".*\"} > 0",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeJobNotCompleted",
              "annotations" => %{
                "description" =>
                  "Job {{ $labels.namespace }}/{{ $labels.job_name }} is taking more than {{ \"43200\" | humanizeDuration }} to complete.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubejobnotcompleted",
                "summary" => "Job did not complete in time"
              },
              "expr" =>
                "time() - max by(namespace, job_name, cluster) (kube_job_status_start_time{job=\"kube-state-metrics\", namespace=~\".*\"}\n  and\nkube_job_status_active{job=\"kube-state-metrics\", namespace=~\".*\"} > 0) > 43200",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeJobFailed",
              "annotations" => %{
                "description" =>
                  "Job {{ $labels.namespace }}/{{ $labels.job_name }} failed to complete. Removing failed job after investigation should clear this alert.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubejobfailed",
                "summary" => "Job failed to complete."
              },
              "expr" => "kube_job_failed{job=\"kube-state-metrics\", namespace=~\".*\"}  > 0",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeHpaReplicasMismatch",
              "annotations" => %{
                "description" =>
                  "HPA {{ $labels.namespace }}/{{ $labels.horizontalpodautoscaler  }} has not matched the desired number of replicas for longer than 15 minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubehpareplicasmismatch",
                "summary" => "HPA has not matched desired number of replicas."
              },
              "expr" =>
                "(kube_horizontalpodautoscaler_status_desired_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}\n  !=\nkube_horizontalpodautoscaler_status_current_replicas{job=\"kube-state-metrics\", namespace=~\".*\"})\n  and\n(kube_horizontalpodautoscaler_status_current_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}\n  >\nkube_horizontalpodautoscaler_spec_min_replicas{job=\"kube-state-metrics\", namespace=~\".*\"})\n  and\n(kube_horizontalpodautoscaler_status_current_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}\n  <\nkube_horizontalpodautoscaler_spec_max_replicas{job=\"kube-state-metrics\", namespace=~\".*\"})\n  and\nchanges(kube_horizontalpodautoscaler_status_current_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}[15m]) == 0",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeHpaMaxedOut",
              "annotations" => %{
                "description" =>
                  "HPA {{ $labels.namespace }}/{{ $labels.horizontalpodautoscaler  }} has been running at max replicas for longer than 15 minutes.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubehpamaxedout",
                "summary" => "HPA is running at max replicas"
              },
              "expr" =>
                "kube_horizontalpodautoscaler_status_current_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}\n  ==\nkube_horizontalpodautoscaler_spec_max_replicas{job=\"kube-state-metrics\", namespace=~\".*\"}",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_kubernetes_resources, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kubernetes-resources")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-resources",
          "rules" => [
            %{
              "alert" => "KubeCPUOvercommit",
              "annotations" => %{
                "description" =>
                  "Cluster has overcommitted CPU resource requests for Pods by {{ $value }} CPU shares and cannot tolerate node failure.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubecpuovercommit",
                "summary" => "Cluster has overcommitted CPU resource requests."
              },
              "expr" =>
                "sum(namespace_cpu:kube_pod_container_resource_requests:sum{}) - (sum(kube_node_status_allocatable{resource=\"cpu\"}) - max(kube_node_status_allocatable{resource=\"cpu\"})) > 0\nand\n(sum(kube_node_status_allocatable{resource=\"cpu\"}) - max(kube_node_status_allocatable{resource=\"cpu\"})) > 0",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeMemoryOvercommit",
              "annotations" => %{
                "description" =>
                  "Cluster has overcommitted memory resource requests for Pods by {{ $value | humanize }} bytes and cannot tolerate node failure.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubememoryovercommit",
                "summary" => "Cluster has overcommitted memory resource requests."
              },
              "expr" =>
                "sum(namespace_memory:kube_pod_container_resource_requests:sum{}) - (sum(kube_node_status_allocatable{resource=\"memory\"}) - max(kube_node_status_allocatable{resource=\"memory\"})) > 0\nand\n(sum(kube_node_status_allocatable{resource=\"memory\"}) - max(kube_node_status_allocatable{resource=\"memory\"})) > 0",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeCPUQuotaOvercommit",
              "annotations" => %{
                "description" =>
                  "Cluster has overcommitted CPU resource requests for Namespaces.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubecpuquotaovercommit",
                "summary" => "Cluster has overcommitted CPU resource requests."
              },
              "expr" =>
                "sum(min without(resource) (kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\", resource=~\"(cpu|requests.cpu)\"}))\n  /\nsum(kube_node_status_allocatable{resource=\"cpu\", job=\"kube-state-metrics\"})\n  > 1.5",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeMemoryQuotaOvercommit",
              "annotations" => %{
                "description" =>
                  "Cluster has overcommitted memory resource requests for Namespaces.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubememoryquotaovercommit",
                "summary" => "Cluster has overcommitted memory resource requests."
              },
              "expr" =>
                "sum(min without(resource) (kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\", resource=~\"(memory|requests.memory)\"}))\n  /\nsum(kube_node_status_allocatable{resource=\"memory\", job=\"kube-state-metrics\"})\n  > 1.5",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeQuotaAlmostFull",
              "annotations" => %{
                "description" =>
                  "Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubequotaalmostfull",
                "summary" => "Namespace quota is going to be full."
              },
              "expr" =>
                "kube_resourcequota{job=\"kube-state-metrics\", type=\"used\"}\n  / ignoring(instance, job, type)\n(kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\"} > 0)\n  > 0.9 < 1",
              "for" => "15m",
              "labels" => %{"severity" => "info"}
            },
            %{
              "alert" => "KubeQuotaFullyUsed",
              "annotations" => %{
                "description" =>
                  "Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubequotafullyused",
                "summary" => "Namespace quota is fully used."
              },
              "expr" =>
                "kube_resourcequota{job=\"kube-state-metrics\", type=\"used\"}\n  / ignoring(instance, job, type)\n(kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\"} > 0)\n  == 1",
              "for" => "15m",
              "labels" => %{"severity" => "info"}
            },
            %{
              "alert" => "KubeQuotaExceeded",
              "annotations" => %{
                "description" =>
                  "Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubequotaexceeded",
                "summary" => "Namespace quota has exceeded the limits."
              },
              "expr" =>
                "kube_resourcequota{job=\"kube-state-metrics\", type=\"used\"}\n  / ignoring(instance, job, type)\n(kube_resourcequota{job=\"kube-state-metrics\", type=\"hard\"} > 0)\n  > 1",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "CPUThrottlingHigh",
              "annotations" => %{
                "description" =>
                  "{{ $value | humanizePercentage }} throttling of CPU in namespace {{ $labels.namespace }} for container {{ $labels.container }} in pod {{ $labels.pod }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/cputhrottlinghigh",
                "summary" => "Processes experience elevated CPU throttling."
              },
              "expr" =>
                "sum(increase(container_cpu_cfs_throttled_periods_total{container!=\"\", }[5m])) by (container, pod, namespace)\n  /\nsum(increase(container_cpu_cfs_periods_total{}[5m])) by (container, pod, namespace)\n  > ( 25 / 100 )",
              "for" => "15m",
              "labels" => %{"severity" => "info"}
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_kubernetes_system, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kubernetes-system")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-system",
          "rules" => [
            %{
              "alert" => "KubeVersionMismatch",
              "annotations" => %{
                "description" =>
                  "There are {{ $value }} different semantic versions of Kubernetes components running.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeversionmismatch",
                "summary" => "Different semantic versions of Kubernetes components running."
              },
              "expr" =>
                "count by (cluster) (count by (git_version, cluster) (label_replace(kubernetes_build_info{job!~\"kube-dns|coredns\"},\"git_version\",\"$1\",\"git_version\",\"(v[0-9]*.[0-9]*).*\"))) > 1",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeClientErrors",
              "annotations" => %{
                "description" =>
                  "Kubernetes API server client '{{ $labels.job }}/{{ $labels.instance }}' is experiencing {{ $value | humanizePercentage }} errors.'",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeclienterrors",
                "summary" => "Kubernetes API server client is experiencing errors."
              },
              "expr" =>
                "(sum(rate(rest_client_requests_total{code=~\"5..\"}[5m])) by (cluster, instance, job, namespace)\n  /\nsum(rate(rest_client_requests_total[5m])) by (cluster, instance, job, namespace))\n> 0.01",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_operator, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-prometheus-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "kube-prometheus-stack")
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "prometheus-operator",
          "rules" => [
            %{
              "alert" => "PrometheusOperatorListErrors",
              "annotations" => %{
                "description" =>
                  "Errors while performing List operations in controller {{$labels.controller}} in {{$labels.namespace}} namespace.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/prometheus-operator/prometheusoperatorlisterrors",
                "summary" => "Errors while performing list operations in controller."
              },
              "expr" =>
                "(sum by (controller,namespace) (rate(prometheus_operator_list_operations_failed_total{job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[10m])) / sum by (controller,namespace) (rate(prometheus_operator_list_operations_total{job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[10m]))) > 0.4",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "PrometheusOperatorWatchErrors",
              "annotations" => %{
                "description" =>
                  "Errors while performing watch operations in controller {{$labels.controller}} in {{$labels.namespace}} namespace.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/prometheus-operator/prometheusoperatorwatcherrors",
                "summary" => "Errors while performing watch operations in controller."
              },
              "expr" =>
                "(sum by (controller,namespace) (rate(prometheus_operator_watch_operations_failed_total{job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[5m])) / sum by (controller,namespace) (rate(prometheus_operator_watch_operations_total{job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[5m]))) > 0.4",
              "for" => "15m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "PrometheusOperatorSyncFailed",
              "annotations" => %{
                "description" =>
                  "Controller {{ $labels.controller }} in {{ $labels.namespace }} namespace fails to reconcile {{ $value }} objects.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/prometheus-operator/prometheusoperatorsyncfailed",
                "summary" => "Last controller reconciliation failed"
              },
              "expr" =>
                "min_over_time(prometheus_operator_syncs{status=\"failed\",job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[5m]) > 0",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "PrometheusOperatorReconcileErrors",
              "annotations" => %{
                "description" =>
                  "{{ $value | humanizePercentage }} of reconciling operations failed for {{ $labels.controller }} controller in {{ $labels.namespace }} namespace.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/prometheus-operator/prometheusoperatorreconcileerrors",
                "summary" => "Errors while reconciling controller."
              },
              "expr" =>
                "(sum by (controller,namespace) (rate(prometheus_operator_reconcile_errors_total{job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[5m]))) / (sum by (controller,namespace) (rate(prometheus_operator_reconcile_operations_total{job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[5m]))) > 0.1",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "PrometheusOperatorNodeLookupErrors",
              "annotations" => %{
                "description" =>
                  "Errors while reconciling Prometheus in {{ $labels.namespace }} Namespace.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/prometheus-operator/prometheusoperatornodelookuperrors",
                "summary" => "Errors while reconciling Prometheus."
              },
              "expr" =>
                "rate(prometheus_operator_node_address_lookup_errors_total{job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[5m]) > 0.1",
              "for" => "10m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "PrometheusOperatorNotReady",
              "annotations" => %{
                "description" =>
                  "Prometheus operator in {{ $labels.namespace }} namespace isn't ready to reconcile {{ $labels.controller }} resources.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/prometheus-operator/prometheusoperatornotready",
                "summary" => "Prometheus operator not ready"
              },
              "expr" =>
                "min by (controller,namespace) (max_over_time(prometheus_operator_ready{job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[5m]) == 0)",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "PrometheusOperatorRejectedResources",
              "annotations" => %{
                "description" =>
                  "Prometheus operator in {{ $labels.namespace }} namespace rejected {{ printf \"%0.0f\" $value }} {{ $labels.controller }}/{{ $labels.resource }} resources.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/prometheus-operator/prometheusoperatorrejectedresources",
                "summary" => "Resources rejected by Prometheus operator"
              },
              "expr" =>
                "min_over_time(prometheus_operator_managed_resources{state=\"rejected\",job=\"battery-prometheus-operator\",namespace=\"battery-core\"}[5m]) > 0",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            }
          ]
        }
      ]
    })
  end
end
