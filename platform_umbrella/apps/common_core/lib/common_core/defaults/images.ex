defmodule CommonCore.Defaults.Images do
  @moduledoc false
  def control_server_image, do: "battery-registry:5000/battery/control:c6f4bd1-dirty1"

  def postgres_operator_image, do: "registry.opensource.zalan.do/acid/postgres-operator:v1.10.0"

  def cloudnative_pg_image, do: "ghcr.io/cloudnative-pg/cloudnative-pg:1.21.0"

  def redis_operator_image, do: "quay.io/spotahome/redis-operator:v1.2.4"

  def ceph_image, do: "quay.io/ceph/ceph:v17.2.6"

  def gitea_image, do: "gitea/gitea:1.19.4"

  def trivy_operator_image, do: "ghcr.io/aquasecurity/trivy-operator:0.14.1"

  def grafana_image, do: "grafana/grafana:10.1.5"
  def kiwigrid_sidecar_image, do: "quay.io/kiwigrid/k8s-sidecar:1.25.2"

  def node_exporter_image, do: "quay.io/prometheus/node-exporter:v1.6.1"
  def kube_state_metrics_image, do: "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.10.0"
  def alertmanager_image, do: "quay.io/prometheus/alertmanager:v0.26.0"

  def promtail_image, do: "grafana/promtail:2.8.6"
  def loki_image, do: "grafana/loki:2.8.6"

  def istio_pilot_image, do: "istio/pilot:1.19.3-distroless"

  def keycloak_image, do: "quay.io/keycloak/keycloak:22.0.4"

  def knative_operator_webhook_image, do: "gcr.io/knative-releases/knative.dev/operator/cmd/webhook:v1.11.7"

  def knative_operator_image, do: "gcr.io/knative-releases/knative.dev/operator/cmd/operator:v1.11.7"

  def kiali_image, do: "quay.io/kiali/kiali:#{kiali_image_version()}"
  def kiali_image_version, do: "v1.74.1"

  def metallb_speaker_image, do: "quay.io/metallb/speaker:v0.13.11"
  def metallb_controller_image, do: "quay.io/metallb/controller:v0.13.11"

  def vm_cluster_tag, do: "v1.93.6-cluster"

  def vm_operator_image, do: "victoriametrics/operator:v0.39.0"
  def vm_tag, do: "v1.93.6"

  def smtp4dev_image, do: "rnwood/smtp4dev:3.1.4"
end
