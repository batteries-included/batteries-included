defmodule CommonCore.Defaults.Images do
  @moduledoc false
  @cert_manager_image_tag "v1.13.3"
  def cert_manager_acmesolver_image, do: "quay.io/jetstack/cert-manager-acmesolver:#{@cert_manager_image_tag}"
  def cert_manager_cainjector_image, do: "quay.io/jetstack/cert-manager-cainjector:#{@cert_manager_image_tag}"
  def cert_manager_controller_image, do: "quay.io/jetstack/cert-manager-controller:#{@cert_manager_image_tag}"
  def cert_manager_ctl_image, do: "quay.io/jetstack/cert-manager-ctl:#{@cert_manager_image_tag}"
  def cert_manager_webhook_image, do: "quay.io/jetstack/cert-manager-webhook:#{@cert_manager_image_tag}"

  def control_server_image, do: "battery-registry:5000/battery/control:c6f4bd1-dirty1"

  def cloudnative_pg_image, do: "ghcr.io/cloudnative-pg/cloudnative-pg:1.21.1"

  def redis_operator_image, do: "quay.io/spotahome/redis-operator:v1.2.4"

  def gitea_image, do: "gitea/gitea:1.19.4"

  def trivy_operator_image, do: "ghcr.io/aquasecurity/trivy-operator:0.14.1"

  def grafana_image, do: "grafana/grafana:10.2.3"
  def kiwigrid_sidecar_image, do: "quay.io/kiwigrid/k8s-sidecar:1.25.2"

  def node_exporter_image, do: "quay.io/prometheus/node-exporter:v1.6.1"
  def kube_state_metrics_image, do: "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.10.0"
  def alertmanager_image, do: "quay.io/prometheus/alertmanager:v0.26.0"
  def metrics_server_image, do: "registry.k8s.io/metrics-server/metrics-server:v0.6.4"
  def addon_resizer_image, do: "registry.k8s.io/autoscaling/addon-resizer:1.8.19"

  def promtail_image, do: "grafana/promtail:2.8.6"
  def loki_image, do: "grafana/loki:2.8.6"

  def istio_pilot_image, do: "docker.io/istio/pilot:1.20.1-distroless"
  def istio_proxy_image, do: "docker.io/istio/proxyv2:1.20.1-distroless"

  def keycloak_image, do: "quay.io/keycloak/keycloak:22.0.4"

  def kiali_image, do: "quay.io/kiali/kiali:#{kiali_image_version()}"
  def kiali_image_version, do: "v1.78.0"

  def metallb_speaker_image, do: "quay.io/metallb/speaker:v0.13.12"
  def metallb_controller_image, do: "quay.io/metallb/controller:v0.13.12"

  def frrouting_frr_image, do: "quay.io/frrouting/frr:8.5.4"

  def ferretdb_image, do: "ghcr.io/ferretdb/ferretdb:1.16.0"

  def vm_cluster_tag, do: "v1.93.9-cluster"

  def vm_operator_image, do: "victoriametrics/operator:v0.39.4"
  def vm_tag, do: "v1.93.9"

  def smtp4dev_image, do: "rnwood/smtp4dev:3.1.4"

  def oauth2_proxy_image, do: "quay.io/oauth2-proxy/oauth2-proxy:v7.5.1"

  def text_generation_webui_image, do: "atinoda/text-generation-webui:default-snapshot-2023-12-10"
end
