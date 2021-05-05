defmodule ControlServer.Services.Monitoring do
  @moduledoc """

  This is the entry way into our monitoing system. This will
  be in charge of the db side and generate all the needed
  k8s configs.
  """

  @default_path "/monitoring/base"
  @default_config %{}

  alias ControlServer.Services
  alias ControlServer.Services.AlertManager
  alias ControlServer.Services.Grafana
  alias ControlServer.Services.KubeState
  alias ControlServer.Services.NodeExporter
  alias ControlServer.Services.Prometheus
  alias ControlServer.Services.PrometheusOperator
  alias ControlServer.Settings.MonitoringSettings

  import ControlServer.FileExt

  def default_config, do: @default_config

  def activate(path \\ @default_path),
    do: Services.update_active!(true, path, :monitoring, @default_config)

  def deactivate(path \\ @default_path),
    do: Services.update_active!(false, path, :monitoring, @default_config)

  def active?(path \\ @default_path), do: Services.active?(path)

  def materialize(%{} = config) do
    setup_defs = %{
      # The namespace Really really has to be first.
      "/0/setup/namespace" => namespace(config),

      # Then the CRDS since they are needed for cluster roles.
      "/1/setup/prometheus_crd" =>
        read_yaml(
          "setup/prometheus-operator-0prometheusCustomResourceDefinition.yaml",
          :prometheus
        ),
      "/1/setup/prometheus_rule_crd" =>
        read_yaml(
          "setup/prometheus-operator-0prometheusruleCustomResourceDefinition.yaml",
          :prometheus
        ),
      "/1/setup/service_monitor_crd" =>
        read_yaml(
          "setup/prometheus-operator-0servicemonitorCustomResourceDefinition.yaml",
          :prometheus
        ),
      "/1/setup/podmonitor_crd" =>
        read_yaml(
          "setup/prometheus-operator-0podmonitorCustomResourceDefinition.yaml",
          :prometheus
        ),
      "/1/setup/probe_crd" =>
        read_yaml("setup/prometheus-operator-0probeCustomResourceDefinition.yaml", :prometheus),
      "/1/setup/am_config_crd" =>
        read_yaml(
          "setup/prometheus-operator-0alertmanagerConfigCustomResourceDefinition.yaml",
          :prometheus
        ),
      "/1/setup/am_crd" =>
        read_yaml(
          "setup/prometheus-operator-0alertmanagerCustomResourceDefinition.yaml",
          :prometheus
        ),
      "/1/setup/thanos_ruler_crd" =>
        read_yaml(
          "setup/prometheus-operator-0thanosrulerCustomResourceDefinition.yaml",
          :prometheus
        )
    }

    operator_defs = %{
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

    account_defs = %{
      "/4/prometheus/prometheus_account" => Prometheus.service_account(config),
      "/4/prometheus/prometheus_cluster_role" => Prometheus.role(:cluster, config),
      "/4/prometheus/prometheus_config_role" => Prometheus.role(:config, config),
      "/4/prometheus/prometheus_cluster_role_bind" => Prometheus.role_binding(:cluster, config),
      "/4/prometheus/prometheus_config_role_bind" => Prometheus.role_binding(:config, config)
    }

    monitored_namespaces = MonitoringSettings.prometheus_main_namespaces(config)

    main_role_defs =
      Enum.flat_map(monitored_namespaces, fn target_ns ->
        [
          {"/5/prometheus/prometheus_main_role_#{target_ns}",
           Prometheus.role(:main, target_ns, config)},
          {"/5/prometheus/prometheus_main_role_#{target_ns}_bind",
           Prometheus.role_binding(:main, target_ns, config)}
        ]
      end)
      |> Map.new()

    main_defs = %{
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

    %{}
    |> Map.merge(setup_defs)
    |> Map.merge(operator_defs)
    |> Map.merge(account_defs)
    |> Map.merge(main_role_defs)
    |> Map.merge(main_defs)
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
