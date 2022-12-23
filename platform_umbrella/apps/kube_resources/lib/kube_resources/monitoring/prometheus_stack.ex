defmodule KubeResources.PrometheusStack do
  use KubeExt.IncludeResource,
    alertmanager_overview_json: "priv/raw_files/prometheus_stack/alertmanager-overview.json",
    apiserver_json: "priv/raw_files/prometheus_stack/apiserver.json",
    cluster_total_json: "priv/raw_files/prometheus_stack/cluster-total.json",
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

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "prometheus_stack"

  resource(:config_map_alertmanager_overview, _battery, state) do
    namespace = core_namespace(state)
    data = %{"alertmanager-overview.json" => get_resource(:alertmanager_overview_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-alertmanager-overview")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_cluster_total, _battery, state) do
    namespace = core_namespace(state)
    data = %{"cluster-total.json" => get_resource(:cluster_total_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-cluster-total")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_grafana_overview, _battery, state) do
    namespace = core_namespace(state)
    data = %{"grafana-overview.json" => get_resource(:grafana_overview_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-grafana-overview")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_coredns, _battery, state) do
    namespace = core_namespace(state)
    data = %{"k8s-coredns.json" => get_resource(:k8s_coredns_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-coredns")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_cluster, _battery, state) do
    namespace = core_namespace(state)
    data = %{"k8s-resources-cluster.json" => get_resource(:k8s_resources_cluster_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-cluster")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_namespace, _battery, state) do
    namespace = core_namespace(state)

    data = %{"k8s-resources-namespace.json" => get_resource(:k8s_resources_namespace_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-namespace")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_node, _battery, state) do
    namespace = core_namespace(state)
    data = %{"k8s-resources-node.json" => get_resource(:k8s_resources_node_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-node")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_pod, _battery, state) do
    namespace = core_namespace(state)
    data = %{"k8s-resources-pod.json" => get_resource(:k8s_resources_pod_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-pod")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_workload, _battery, state) do
    namespace = core_namespace(state)

    data = %{"k8s-resources-workload.json" => get_resource(:k8s_resources_workload_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-workload")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_k8s_resources_workloads_namespace, _battery, state) do
    namespace = core_namespace(state)

    data = %{
      "k8s-resources-workloads-namespace.json" =>
        get_resource(:k8s_resources_workloads_namespace_json)
    }

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-k8s-resources-workloads-namespace")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_namespace_by_pod, _battery, state) do
    namespace = core_namespace(state)
    data = %{"namespace-by-pod.json" => get_resource(:namespace_by_pod_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-namespace-by-pod")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_namespace_by_workload, _battery, state) do
    namespace = core_namespace(state)
    data = %{"namespace-by-workload.json" => get_resource(:namespace_by_workload_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-namespace-by-workload")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_node_cluster_rsrc_use, _battery, state) do
    namespace = core_namespace(state)
    data = %{"node-cluster-rsrc-use.json" => get_resource(:node_cluster_rsrc_use_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-node-cluster-rsrc-use")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_node_rsrc_use, _battery, state) do
    namespace = core_namespace(state)
    data = %{"node-rsrc-use.json" => get_resource(:node_rsrc_use_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-node-rsrc-use")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_nodes, _battery, state) do
    namespace = core_namespace(state)
    data = %{"nodes.json" => get_resource(:nodes_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-nodes")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_nodes_darwin, _battery, state) do
    namespace = core_namespace(state)
    data = %{"nodes-darwin.json" => get_resource(:nodes_darwin_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-nodes-darwin")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_persistentvolumesusage, _battery, state) do
    namespace = core_namespace(state)

    data = %{"persistentvolumesusage.json" => get_resource(:persistentvolumesusage_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-persistentvolumesusage")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_pod_total, _battery, state) do
    namespace = core_namespace(state)
    data = %{"pod-total.json" => get_resource(:pod_total_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-pod-total")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_prometheus, _battery, state) do
    namespace = core_namespace(state)
    data = %{"prometheus.json" => get_resource(:prometheus_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-prometheus")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:config_map_workload_total, _battery, state) do
    namespace = core_namespace(state)
    data = %{"workload-total.json" => get_resource(:workload_total_json)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-workload-total")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:prometheus_rule_kube_general_rules, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kube-prometheus-general.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
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

  resource(:prometheus_rule_kube_node_recording_rules, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-kube-prometheus-node-recording.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
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
end
