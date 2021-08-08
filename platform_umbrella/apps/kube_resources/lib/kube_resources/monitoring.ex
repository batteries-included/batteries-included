defmodule KubeResources.Monitoring do
  import KubeResources.FileExt

  alias KubeResources.AlertManager
  alias KubeResources.Grafana
  alias KubeResources.KubeState
  alias KubeResources.MonitoringSettings
  alias KubeResources.NodeExporter
  alias KubeResources.Prometheus
  alias KubeResources.PrometheusOperator

  def materialize(%{} = config) do
    %{}
    |> Map.merge(setup_defs(config))
    |> Map.merge(operator_defs(config))
    |> Map.merge(account_defs(config))
    |> Map.merge(main_role_defs(config))
    |> Map.merge(main_defs(config))
  end

  defp setup_defs(config) do
    %{
      # The namespace Really really has to be first.
      "/0/setup/namespace" => namespace(config),

      # Then the CRDS since they are needed for cluster roles.
      "/1/setup/prometheus_crd" =>
        read_yaml(
          "prometheus/prometheus-operator-0prometheusCustomResourceDefinition.yaml",
          :base
        ),
      "/1/setup/prometheus_rule_crd" =>
        read_yaml(
          "prometheus/prometheus-operator-0prometheusruleCustomResourceDefinition.yaml",
          :base
        ),
      "/1/setup/service_monitor_crd" =>
        read_yaml(
          "prometheus/prometheus-operator-0servicemonitorCustomResourceDefinition.yaml",
          :base
        ),
      "/1/setup/podmonitor_crd" =>
        read_yaml(
          "prometheus/prometheus-operator-0podmonitorCustomResourceDefinition.yaml",
          :base
        ),
      "/1/setup/probe_crd" =>
        read_yaml("prometheus/prometheus-operator-0probeCustomResourceDefinition.yaml", :base),
      "/1/setup/am_config_crd" =>
        read_yaml(
          "prometheus/prometheus-operator-0alertmanagerConfigCustomResourceDefinition.yaml",
          :base
        ),
      "/1/setup/am_crd" =>
        read_yaml(
          "prometheus/prometheus-operator-0alertmanagerCustomResourceDefinition.yaml",
          :base
        ),
      "/1/setup/thanos_ruler_crd" =>
        read_yaml(
          "prometheus/prometheus-operator-0thanosrulerCustomResourceDefinition.yaml",
          :base
        )
    }
  end

  defp operator_defs(config) do
    %{
      # for the prometheus operator account stuff
      "/2/setup/operator_service_account" => PrometheusOperator.service_account(config),
      "/2/setup/operator_cluster_role" => PrometheusOperator.cluster_role(config),
      # Bind them
      "/3/setup/operator_cluster_role_binding" => PrometheusOperator.cluster_role_binding(config),
      # Run Something.
      "/3/setup/operator_deployment" => PrometheusOperator.deployment(config),
      # Make it available.
      "/3/setup/operator_service" => PrometheusOperator.service(config)
    }
  end

  defp account_defs(config) do
    %{
      "/4/prometheus/prometheus_account" => Prometheus.service_account(config),
      "/4/prometheus/prometheus_cluster_role" => Prometheus.role(:cluster, config),
      "/4/prometheus/prometheus_config_role" => Prometheus.role(:config, config),
      "/4/prometheus/prometheus_cluster_role_bind" => Prometheus.role_binding(:cluster, config),
      "/4/prometheus/prometheus_config_role_bind" => Prometheus.role_binding(:config, config)
    }
  end

  defp main_role_defs(config) do
    config
    |> MonitoringSettings.prometheus_main_namespaces()
    |> Enum.flat_map(fn target_ns ->
      [
        {"/5/prometheus/prometheus_main_role_#{target_ns}",
         Prometheus.role(:main, target_ns, config)},
        {"/5/prometheus/prometheus_main_role_#{target_ns}_bind",
         Prometheus.role_binding(:main, target_ns, config)}
      ]
    end)
    |> Map.new()
  end

  defp main_defs(config) do
    %{
      "/9/prometheus/prometheus_prometheus" => Prometheus.prometheus(config),
      "/9/grafana/0/service_account" => Grafana.service_account(config),
      "/9/grafana/0/prometheus_datasource" => Grafana.prometheus_datasource_config(config),
      "/9/grafana/0/prometheus_dashboard_datasource" => Grafana.dashboard_sources_config(config),
      "/9/grafana/1/grafana_deployment" => Grafana.deployment(config),
      "/9/grafana/1/grafana_service" => Grafana.service(config),
      "/9/node/0/service_account" => NodeExporter.service_account(config),
      "/9/node/0/cluster_role" => NodeExporter.cluster_role(config),
      "/9/node/1/bind" => NodeExporter.cluster_binding(config),
      "/9/node/1/daemon" => NodeExporter.daemonset(config),
      "/9/node/2/service" => NodeExporter.service(config),
      "/9/kube/0/service_account" => KubeState.service_account(config),
      "/9/kube/0/cluster_role" => KubeState.cluster_role(config),
      "/9/kube/1/bind" => KubeState.cluster_binding(config),
      "/9/kube/1/daemon" => KubeState.deployment(config),
      "/9/kube/2/service" => KubeState.service(config),
      "/9/alertmanager/0/service_account" => AlertManager.service_account(config),
      "/9/alertmanager/1/config" => AlertManager.config(config),
      "/9/alertmanager/2/alertmanager" => AlertManager.alertmanager(config),
      "/9/alertmanager/2/service" => AlertManager.service(config)
    }
  end

  defp namespace(config) do
    ns = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Namespace",
      "metadata" => %{
        "name" => ns
      }
    }
  end
end
