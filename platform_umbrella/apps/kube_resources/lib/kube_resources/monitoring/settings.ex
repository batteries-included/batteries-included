defmodule KubeResources.MonitoringSettings do
  @moduledoc """
  The first most crude pass at putting in configurable
  settings with defaults. This is awful. There has to be
  a better way with defstruct and defaults.. Dunno.
  """
  @namespace "battery-core"
  @monitored_namespaces ["default", @namespace, "kube-system", "battery-data", "battery-knative"]

  @prometheus_operator_image "quay.io/prometheus-operator/prometheus-operator"
  @prometheus_operator_version "v0.49.0"

  @prometheus_image "quay.io/prometheus/prometheus"
  @prometheus_version "v2.30.3"
  @prometheus_replicas 1
  @prometheus_memory "450Mi"

  @grafana_image "grafana/grafana"
  @grafana_version "7.3.4"

  @node_image "quay.io/prometheus/node-exporter"
  @node_version "v1.2.2"

  @kube_version "v2.2.0"
  @kube_image "k8s.gcr.io/kube-state-metrics/kube-state-metrics"

  @alertmanager_image "quay.io/prometheus/alertmanager"
  @alertmanager_version "v0.23.0"

  def namespace(config) do
    Map.get(config, "namespace", @namespace)
  end

  def monitored_namespaces(config) do
    Map.get(config, "monitored_namespaces", @monitored_namespaces)
  end

  def prometheus_operator_image(config) do
    Map.get(config, "prometheus_operator.image", @prometheus_operator_image)
  end

  def prometheus_operator_version(config) do
    Map.get(config, "prometheus_operator.version", @prometheus_operator_version)
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

  def grafana_image(config) do
    Map.get(config, "grafana.image", @grafana_image)
  end

  def grafana_version(config) do
    Map.get(config, "grafana.version", @grafana_version)
  end

  def node_image(config) do
    Map.get(config, "node.image", @node_image)
  end

  def node_version(config) do
    Map.get(config, "node.version", @node_version)
  end

  def kube_image(config) do
    Map.get(config, "kube.image", @kube_image)
  end

  def kube_version(config) do
    Map.get(config, "kube.version", @kube_version)
  end

  def alertmanager_image(config) do
    Map.get(config, "alertmanager.image", @alertmanager_image)
  end

  def alertmanager_version(config) do
    Map.get(config, "alertmanager.version", @alertmanager_version)
  end
end
