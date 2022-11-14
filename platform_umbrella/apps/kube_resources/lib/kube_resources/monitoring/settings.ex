defmodule KubeResources.MonitoringSettings do
  @moduledoc """
  The first most crude pass at putting in configurable
  settings with defaults. This is awful. There has to be
  a better way with defstruct and defaults.. Dunno.
  """
  import KubeExt.MapSettings

  @namespace "battery-core"
  @monitored_namespaces ["default", @namespace, "kube-system"]

  @prometheus_operator_image "quay.io/prometheus-operator/prometheus-operator:v0.60.1"

  @reloader_image "quay.io/prometheus-operator/prometheus-config-reloader:v0.60.1"
  @prometheus_image "quay.io/prometheus/prometheus:v2.39.2"
  @prometheus_replicas 1
  @prometheus_memory "450Mi"

  @grafana_image "grafana/grafana:9.2.4"
  @node_image "quay.io/prometheus/node-exporter:v1.4.0"
  @kube_image "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.6.0"
  @alertmanager_image "quay.io/prometheus/alertmanager:v0.24.0"

  @promtail_image "grafana/promtail:2.7.0"
  @loki_image "grafana/loki:2.7.0"

  @kubelet_service "kube-system/battery-kubelet"

  setting(:monitored_namespaces, :monitored_namespace, @monitored_namespaces)

  setting(:prometheus_operator_image, :image, @prometheus_operator_image)
  setting(:prometheus_image, :image, @prometheus_image)
  setting(:prometheus_replicas, :replicas, @prometheus_replicas)
  setting(:prometheus_memory, :memory, @prometheus_memory)

  setting(:prometheus_reloader_image, :image, @reloader_image)
  setting(:grafana_image, :image, @grafana_image)
  setting(:node_exporter_image, :image, @node_image)
  setting(:kube_state_image, :image, @kube_image)
  setting(:alertmanager_image, :image, @alertmanager_image)

  setting(:promtail_image, :image, @promtail_image)
  setting(:loki_image, :image, @loki_image)

  setting(:kubelet_service, :kubelet_service, @kubelet_service)
end
