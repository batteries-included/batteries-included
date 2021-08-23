defmodule KubeResources.Monitoring do
  alias KubeResources.AlertManager
  alias KubeResources.Grafana
  alias KubeResources.KubeState
  alias KubeResources.NodeExporter
  alias KubeResources.Prometheus
  alias KubeResources.PrometheusOperator

  def materialize(%{} = config) do
    %{}
    |> Map.merge(setup_defs(config))
    |> Map.merge(operator_defs(config))
    |> Map.merge(account_defs(config))
    |> Map.merge(main_defs(config))
  end

  @prometheus_crd_path "priv/manifests/prometheus/prometheus-operator-0prometheusCustomResourceDefinition.yaml"
  @prometheus_rule_crd_path "priv/manifests/prometheus/prometheus-operator-0prometheusruleCustomResourceDefinition.yaml"

  @probe_crd_path "priv/manifests/prometheus/prometheus-operator-0probeCustomResourceDefinition.yaml"
  @service_mon_crd_path "priv/manifests/prometheus/prometheus-operator-0servicemonitorCustomResourceDefinition.yaml"
  @pod_mon_crd_path "priv/manifests/prometheus/prometheus-operator-0podmonitorCustomResourceDefinition.yaml"

  @am_config_crd_path "priv/manifests/prometheus/prometheus-operator-0alertmanagerConfigCustomResourceDefinition.yaml"
  @am_crd_path "priv/manifests/prometheus/prometheus-operator-0alertmanagerCustomResourceDefinition.yaml"

  @thanos_rule_crd_path "priv/manifests/prometheus/prometheus-operator-0thanosrulerCustomResourceDefinition.yaml"

  defp setup_defs(_config) do
    %{
      # Then the CRDS since they are needed for cluster roles.
      "/1/setup/prometheus_crd" => yaml(prometheus_crd_content()),
      "/1/setup/prometheus_rule_crd" => yaml(prometheus_rule_crd_content()),
      "/1/setup/service_monitor_crd" => yaml(service_mon_crd_content()),
      "/1/setup/podmonitor_crd" => yaml(pod_mon_crd_content()),
      "/1/setup/probe_crd" => yaml(probe_crd_content()),
      "/1/setup/am_config_crd" => yaml(am_config_crd_content()),
      "/1/setup/am_crd" => yaml(am_crd_content()),
      "/1/setup/thanos_ruler_crd" => yaml(thanos_rule_crd_content())
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
      "/4/prometheus/prometheus_cluster_role" => Prometheus.cluster_role(config),
      "/4/prometheus/prometheus_cluster_role_bind" => Prometheus.cluster_role_binding(config),
      "/4/prometheus/prometheus_main_roles" => Prometheus.main_roles(config),
      "/4/prometheus/prometheus_role_binds" => Prometheus.main_role_bindings(config),
      "/4/prometheus/prometheus_config_role" => Prometheus.config_role(config),
      "/4/prometheus/prometheus_config_role_bind" => Prometheus.config_role_binding(config)
    }
  end

  defp main_defs(config) do
    %{
      "/9/prometheus/prometheus_prometheus" => Prometheus.prometheus(config),
      "/9/grafana/service_account" => Grafana.service_account(config),
      "/9/grafana/prometheus_datasource" => Grafana.prometheus_datasource_config(config),
      "/9/grafana/prometheus_dashboard_datasource" => Grafana.dashboard_sources_config(config),
      "/9/grafana/main_config" => Grafana.main_config(config),
      "/9/grafana/grafana_deployment" => Grafana.deployment(config),
      "/9/grafana/grafana_service" => Grafana.service(config),
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
      "/9/alertmanager/service_account" => AlertManager.service_account(config),
      "/9/alertmanager/config" => AlertManager.config(config),
      "/9/alertmanager/alertmanager" => AlertManager.alertmanager(config),
      "/9/alertmanager/service" => AlertManager.service(config)
    }
  end

  defp prometheus_crd_content, do: unquote(File.read!(@prometheus_crd_path))
  defp prometheus_rule_crd_content, do: unquote(File.read!(@prometheus_rule_crd_path))

  defp probe_crd_content, do: unquote(File.read!(@probe_crd_path))
  defp service_mon_crd_content, do: unquote(File.read!(@service_mon_crd_path))
  defp pod_mon_crd_content, do: unquote(File.read!(@pod_mon_crd_path))

  defp am_crd_content, do: unquote(File.read!(@am_crd_path))
  defp am_config_crd_content, do: unquote(File.read!(@am_config_crd_path))

  defp thanos_rule_crd_content, do: unquote(File.read!(@thanos_rule_crd_path))

  defp yaml(content) do
    content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate_content_hash/1)
  end
end
