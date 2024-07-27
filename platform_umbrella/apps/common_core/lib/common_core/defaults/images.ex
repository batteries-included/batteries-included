defmodule CommonCore.Defaults.Images do
  @moduledoc false
  @batteries_included_base "#{CommonCore.Version.version()}-#{CommonCore.Version.hash()}"
  @cert_manager_image_tag "v1.15.1"
  @kiali_image_version "v1.87.0"

  @spec cert_manager_image_version() :: String.t()
  def cert_manager_image_version, do: @cert_manager_image_tag

  @spec vm_cluster_tag() :: String.t()
  def vm_cluster_tag, do: "v1.102.0-cluster"

  @spec vm_tag() :: String.t()
  def vm_tag, do: "v1.93.9"

  @spec kiali_image_version() :: String.t()
  def kiali_image_version, do: @kiali_image_version

  @spec batteries_included_version() :: String.t()
  def batteries_included_version do
    override =
      :common_core
      |> Application.get_env(CommonCore.Defaults)
      |> Keyword.get(:version_override, nil)

    if override != nil do
      override
    else
      @batteries_included_base
    end
  end

  @spec control_server_image() :: String.t()
  def control_server_image do
    ver = batteries_included_version()
    "public.ecr.aws/batteries-included/control-server:#{ver}"
  end

  @spec control_server_image() :: String.t()
  def bootstrap_image do
    ver = batteries_included_version()
    "public.ecr.aws/batteries-included/kube-bootstrap:#{ver}"
  end

  @spec addon_resizer_image() :: String.t()
  def addon_resizer_image, do: "registry.k8s.io/autoscaling/addon-resizer:1.8.22"

  @spec alertmanager_image() :: String.t()
  def alertmanager_image, do: "quay.io/prometheus/alertmanager:v0.27.0"

  @spec aws_load_balancer_controller_image() :: String.t()
  def aws_load_balancer_controller_image, do: "public.ecr.aws/eks/aws-load-balancer-controller:v2.8.1"

  @spec cert_manager_acmesolver_image() :: String.t()
  def cert_manager_acmesolver_image, do: "quay.io/jetstack/cert-manager-acmesolver:#{cert_manager_image_version()}"

  @spec cert_manager_cainjector_image() :: String.t()
  def cert_manager_cainjector_image, do: "quay.io/jetstack/cert-manager-cainjector:#{cert_manager_image_version()}"
  @spec cert_manager_controller_image() :: String.t()
  def cert_manager_controller_image, do: "quay.io/jetstack/cert-manager-controller:#{cert_manager_image_version()}"

  @spec cert_manager_ctl_image() :: String.t()
  def cert_manager_ctl_image, do: "quay.io/jetstack/cert-manager-ctl:#{cert_manager_image_version()}"

  @spec cert_manager_webhook_image() :: String.t()
  def cert_manager_webhook_image, do: "quay.io/jetstack/cert-manager-webhook:#{cert_manager_image_version()}"

  @spec cloudnative_pg_image() :: String.t()
  def cloudnative_pg_image, do: "ghcr.io/cloudnative-pg/cloudnative-pg:1.23.2"

  @spec ferretdb_image() :: String.t()
  def ferretdb_image, do: "ghcr.io/ferretdb/ferretdb:1.23.0"

  @spec forgejo_image() :: String.t()
  def forgejo_image, do: "codeberg.org/forgejo/forgejo:1.21.11-2"

  @spec frrouting_frr_image() :: String.t()
  def frrouting_frr_image, do: "quay.io/frrouting/frr:8.5.4"

  @spec grafana_image() :: String.t()
  def grafana_image, do: "grafana/grafana:10.4.5"

  @spec istio_pilot_image() :: String.t()
  def istio_pilot_image, do: "docker.io/istio/pilot:1.22.3-distroless"

  @spec istio_proxy_image() :: String.t()
  def istio_proxy_image, do: "docker.io/istio/proxyv2:1.22.3-distroless"

  @spec karpenter_image() :: String.t()
  def karpenter_image, do: "public.ecr.aws/karpenter/controller:0.37.0"

  @spec keycloak_image() :: String.t()
  def keycloak_image, do: "quay.io/keycloak/keycloak:25.0.2"

  @spec kiali_image() :: String.t()
  def kiali_image, do: "quay.io/kiali/kiali:#{kiali_image_version()}"

  @spec kiwigrid_sidecar_image() :: String.t()
  def kiwigrid_sidecar_image, do: "quay.io/kiwigrid/k8s-sidecar:1.27.4"

  @spec kube_state_metrics_image() :: String.t()
  def kube_state_metrics_image, do: "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.12.0"

  @spec loki_image() :: String.t()
  def loki_image, do: "grafana/loki:2.9.8"

  @spec metallb_controller_image() :: String.t()
  def metallb_controller_image, do: "quay.io/metallb/controller:v0.13.12"

  @spec metallb_speaker_image() :: String.t()
  def metallb_speaker_image, do: "quay.io/metallb/speaker:v0.13.12"

  @spec metrics_server_image() :: String.t()
  def metrics_server_image, do: "registry.k8s.io/metrics-server/metrics-server:v0.7.1"

  @spec node_exporter_image() :: String.t()
  def node_exporter_image, do: "quay.io/prometheus/node-exporter:v1.8.1"

  @spec oauth2_proxy_image() :: String.t()
  def oauth2_proxy_image, do: "quay.io/oauth2-proxy/oauth2-proxy:v7.6.0"

  @spec promtail_image() :: String.t()
  def promtail_image, do: "grafana/promtail:2.9.8"

  @spec redis_operator_image() :: String.t()
  def redis_operator_image, do: "quay.io/spotahome/redis-operator:v1.2.4"

  @spec smtp4dev_image() :: String.t()
  def smtp4dev_image, do: "rnwood/smtp4dev:3.1.4"

  @spec text_generation_webui_image() :: String.t()
  def text_generation_webui_image, do: "atinoda/text-generation-webui:default-cpu-2024.06.23"

  @spec trivy_operator_image() :: String.t()
  def trivy_operator_image, do: "ghcr.io/aquasecurity/trivy-operator:0.21.3"

  @spec aqua_node_collector() :: String.t()
  def aqua_node_collector, do: "ghcr.io/aquasecurity/node-collector:0.2.1"

  @spec aqua_trivy_checks() :: String.t()
  def aqua_trivy_checks, do: "ghcr.io/aquasecurity/trivy-checks:0.13.0"

  @spec trust_manager_image() :: String.t()
  def trust_manager_image, do: "quay.io/jetstack/trust-manager:v0.11.0"
  def trust_manager_init_image, do: "quay.io/jetstack/cert-manager-package-debian:20210119.0"

  @spec vm_operator_image() :: String.t()
  def vm_operator_image, do: "victoriametrics/operator:v0.44.0"

  @spec knative_serving_queue_image() :: String.t()
  def knative_serving_queue_image, do: "gcr.io/knative-releases/knative.dev/serving/cmd/queue:v1.14.1"

  @spec knative_serving_activator_image() :: String.t()
  def knative_serving_activator_image, do: "gcr.io/knative-releases/knative.dev/serving/cmd/activator:v1.14.1"

  @spec knative_serving_autoscaler_image() :: String.t()
  def knative_serving_autoscaler_image, do: "gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler:v1.14.1"

  @spec knative_serving_controller_image() :: String.t()
  def knative_serving_controller_image, do: "gcr.io/knative-releases/knative.dev/serving/cmd/controller:v1.14.1"

  @spec knative_serving_webhook_image() :: String.t()
  def knative_serving_webhook_image, do: "gcr.io/knative-releases/knative.dev/serving/cmd/webhook:v1.14.1"

  @spec knative_istio_controller_image() :: String.t()
  def knative_istio_controller_image, do: "gcr.io/knative-releases/knative.dev/net-istio/cmd/controller:v1.14.1"

  @spec knative_istio_webhook_image() :: String.t()
  def knative_istio_webhook_image, do: "gcr.io/knative-releases/knative.dev/net-istio/cmd/webhook:v1.14.1"
end
