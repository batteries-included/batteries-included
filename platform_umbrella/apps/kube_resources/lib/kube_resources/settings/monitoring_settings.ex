defmodule KubeResources.MonitoringSettings do
  @moduledoc """
  The first most crude pass at putting in configurable
  settings with defaults. This is awful. There has to be
  a better way with defstruct and defaults.. Dunno.
  """
  @namespace "battery-core"

  @prometheus_operator_name "prometheus-operator"
  @prometheus_operator_image "quay.io/prometheus-operator/prometheus-operator"
  @prometheus_operator_version "v0.44.1"

  @prometheus_name "prometheus"
  @prometheus_image "quay.io/prometheus/prometheus"
  @prometheus_version "v2.22.1"
  @prometheus_main_namespaces ["default", @namespace, "kube-system"]
  @prometheus_replicas 1
  @prometheus_memory "450Mi"
  @prometheus_account "battery-prometheues"
  @prometheus_main_role "battery-prometheus-main"
  @prometheus_cluster_role "battery-prometheus-cluster"
  @prometheus_config_role "battery-prometheus-config"

  @grafana_name "grafana"
  @grafana_image "grafana/grafana"
  @grafana_version "7.3.4"

  @node_name "node-exporter"
  @node_image "quay.io/prometheus/node-exporter"
  @node_version "v1.0.1"

  @kube_name "kube-state-metrics"
  @kube_version "v1.9.7"
  @kube_image "quay.io/coreos/kube-state-metrics"

  @alertmanager_name "alertmanager"
  @alertmanager_image "quay.io/prometheus/alertmanager"
  @alertmanager_version "v0.21.0"

  def namespace(config) do
    Map.get(config, "namespace", @namespace)
  end

  def prometheus_main_namespaces(config) do
    Map.get(config, "prometheus.main_namespaces", @prometheus_main_namespaces)
  end

  def prometheus_operator_image(config) do
    Map.get(config, "prometheus_operator.image", @prometheus_operator_image)
  end

  def prometheus_operator_version(config) do
    Map.get(config, "prometheus_operator.version", @prometheus_operator_version)
  end

  def prometheus_operator_name(config) do
    Map.get(config, "prometheus_operator.name", @prometheus_operator_name)
  end

  def prometheus_name(config) do
    Map.get(config, "prometheus.name", @prometheus_name)
  end

  def prometheus_account(config) do
    Map.get(config, "prometheus.account", @prometheus_account)
  end

  def prometheus_memory(config) do
    Map.get(config, "prometheus.memory", @prometheus_memory)
  end

  def prometheus_replicas(config) do
    Map.get(config, "prometheus.replicas", @prometheus_replicas)
  end

  def prometheus_image(config) do
    Map.get(config, "prometheus.image", @prometheus_image)
  end

  def prometheus_version(config) do
    Map.get(config, "prometheus.version", @prometheus_version)
  end

  def prometheus_main_role(config) do
    Map.get(config, "prometheus.main_role", @prometheus_main_role)
  end

  def prometheus_config_role(config) do
    Map.get(config, "prometheus.config_role", @prometheus_config_role)
  end

  def prometheus_cluster_role(config) do
    Map.get(config, "prometheus.cluster_role", @prometheus_cluster_role)
  end

  def grafana_name(config) do
    Map.get(config, "grafana.name", @grafana_name)
  end

  def grafana_image(config) do
    Map.get(config, "grafana.image", @grafana_image)
  end

  def grafana_version(config) do
    Map.get(config, "grafana.version", @grafana_version)
  end

  def node_name(config) do
    Map.get(config, "node.name", @node_name)
  end

  def node_image(config) do
    Map.get(config, "node.image", @node_image)
  end

  def node_version(config) do
    Map.get(config, "node.version", @node_version)
  end

  def kube_name(config) do
    Map.get(config, "kube.name", @kube_name)
  end

  def kube_image(config) do
    Map.get(config, "kube.image", @kube_image)
  end

  def kube_version(config) do
    Map.get(config, "kube.version", @kube_version)
  end

  def alertmanager_name(config) do
    Map.get(config, "alertmanager.name", @alertmanager_name)
  end

  def alertmanager_image(config) do
    Map.get(config, "alertmanager.image", @alertmanager_image)
  end

  def alertmanager_version(config) do
    Map.get(config, "alertmanager.version", @alertmanager_version)
  end
end
