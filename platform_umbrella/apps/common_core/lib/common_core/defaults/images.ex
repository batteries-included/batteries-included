defmodule CommonCore.Defaults.Images do
  @moduledoc false

  alias CommonCore.Defaults.Image

  @batteries_included_base "#{CommonCore.Version.version()}-#{CommonCore.Version.hash()}"

  @cert_manager_allowed_tags ~w(v1.15.1 v1.15.4)
  @cert_manager_default_tag "v1.15.4"

  @knative_allowed_tags ~w(v1.15.1 v1.15.2)
  @knative_default_tag "v1.15.2"

  @knative_istio_allowed_tags ~w(v1.15.1)
  @knative_istio_default_tag "v1.15.1"

  @registry %{
    addon_resizer:
      Image.new!(%{
        name: "registry.k8s.io/autoscaling/addon-resizer",
        tags: ~w(1.8.22),
        default_tag: "1.8.22"
      }),
    aws_load_balancer_controller:
      Image.new!(%{
        name: "public.ecr.aws/eks/aws-load-balancer-controller",
        tags: ~w(v2.8.1 v2.8.2),
        default_tag: "v2.8.2"
      }),
    cert_manager_acmesolver:
      Image.new!(%{
        name: "quay.io/jetstack/cert-manager-acmesolver",
        tags: @cert_manager_allowed_tags,
        default_tag: @cert_manager_default_tag
      }),
    cert_manager_cainjector:
      Image.new!(%{
        name: "quay.io/jetstack/cert-manager-cainjector",
        tags: @cert_manager_allowed_tags,
        default_tag: @cert_manager_default_tag
      }),
    cert_manager_controller:
      Image.new!(%{
        name: "quay.io/jetstack/cert-manager-controller",
        tags: @cert_manager_allowed_tags,
        default_tag: @cert_manager_default_tag
      }),
    cert_manager_ctl:
      Image.new!(%{
        name: "quay.io/jetstack/cert-manager-ctl",
        tags: @cert_manager_allowed_tags,
        default_tag: @cert_manager_default_tag
      }),
    cert_manager_webhook:
      Image.new!(%{
        name: "quay.io/jetstack/cert-manager-webhook",
        tags: @cert_manager_allowed_tags,
        default_tag: @cert_manager_default_tag
      }),
    cloudnative_pg:
      Image.new!(%{
        name: "ghcr.io/cloudnative-pg/cloudnative-pg",
        tags: ~w(1.23.2 1.24.0 1.24.1),
        default_tag: "1.24.1"
      }),
    ferretdb:
      Image.new!(%{
        name: "ghcr.io/ferretdb/ferretdb",
        tags: ~w(1.23.0 1.24.0),
        default_tag: "1.24.0"
      }),
    forgejo:
      Image.new!(%{
        name: "codeberg.org/forgejo/forgejo",
        tags: ~w(1.21.11-2),
        default_tag: "1.21.11-2"
      }),
    grafana:
      Image.new!(%{
        name: "grafana/grafana",
        tags: ~w(10.4.5 11.2.0 11.3.1),
        default_tag: "11.3.1"
      }),
    # Be sure to check: https://kiali.io/docs/installation/installation-guide/prerequisites/#version-compatibility
    istio_pilot:
      Image.new!(%{
        name: "docker.io/istio/pilot",
        tags: ~w(1.22.3-distroless 1.23.1-distroless 1.23.2-distroless 1.23.3-distroless),
        default_tag: "1.23.3-distroless"
      }),
    istio_proxy:
      Image.new!(%{
        name: "docker.io/istio/proxyv2",
        tags: ~w(1.22.3-distroless 1.23.1-distroless 1.23.2-distroless 1.23.3-distroless),
        default_tag: "1.23.3-distroless"
      }),
    karpenter:
      Image.new!(%{
        name: "public.ecr.aws/karpenter/controller",
        tags: ~w(0.37.0),
        default_tag: "0.37.0"
      }),
    keycloak:
      Image.new!(%{
        name: "quay.io/keycloak/keycloak",
        tags: ~w(25.0.2 25.0.6),
        default_tag: "25.0.6"
      }),
    # Be sure to check: https://kiali.io/docs/installation/installation-guide/prerequisites/#version-compatibility
    kiali:
      Image.new!(%{
        name: "quay.io/kiali/kiali",
        tags: ~w(v1.87.0 v1.89.7),
        default_tag: "v1.89.7"
      }),
    kiwigrid_sidecar:
      Image.new!(%{
        name: "quay.io/kiwigrid/k8s-sidecar",
        tags: ~w(1.27.4),
        default_tag: "1.27.4"
      }),
    kube_state_metrics:
      Image.new!(%{
        name: "registry.k8s.io/kube-state-metrics/kube-state-metrics",
        tags: ~w(v2.12.0 v2.14.0),
        default_tag: "v2.14.0"
      }),
    loki:
      Image.new!(%{
        name: "grafana/loki",
        tags: ~w(2.9.8 2.9.10),
        default_tag: "2.9.10"
      }),
    metallb_controller:
      Image.new!(%{
        name: "quay.io/metallb/controller",
        tags: ~w(v0.14.8),
        default_tag: "v0.14.8"
      }),
    metallb_speaker:
      Image.new!(%{
        name: "quay.io/metallb/speaker",
        tags: ~w(v0.14.8),
        default_tag: "v0.14.8"
      }),
    frrouting_frr:
      Image.new!(%{
        name: "quay.io/frrouting/frr",
        tags: ~w(9.1.0),
        default_tag: "9.1.0"
      }),
    metrics_server:
      Image.new!(%{
        name: "registry.k8s.io/metrics-server/metrics-server",
        tags: ~w(v0.7.1 v0.7.2),
        default_tag: "v0.7.2"
      }),
    node_exporter:
      Image.new!(%{
        name: "quay.io/prometheus/node-exporter",
        tags: ~w(v1.8.1 v1.8.2),
        default_tag: "v1.8.2"
      }),
    nvidia_device_plugin:
      Image.new!(%{
        name: "nvcr.io/nvidia/k8s-device-plugin",
        tags: ~w(v0.16.2),
        default_tag: "v0.16.2"
      }),
    ollama:
      Image.new!(%{
        name: "ollama/ollama",
        tags: ~w(0.3.9 0.3.10 0.5.7),
        default_tag: "0.5.7"
      }),
    oauth2_proxy:
      Image.new!(%{
        name: "quay.io/oauth2-proxy/oauth2-proxy",
        tags: ~w(v7.6.0),
        default_tag: "v7.6.0"
      }),
    promtail:
      Image.new!(%{
        name: "grafana/promtail",
        tags: ~w(2.9.8 3.3.0),
        default_tag: "2.9.8"
      }),
    redis:
      Image.new!(%{
        name: "quay.io/opstree/redis",
        tags: ~w(v7.2.3 v7.2.6),
        default_tag: "v7.2.6"
      }),
    redis_exporter:
      Image.new!(%{
        name: "quay.io/opstree/redis-exporter",
        tags: ~w(v1.45.0 v1.48.0),
        default_tag: "v1.48.0"
      }),
    redis_operator:
      Image.new!(%{
        name: "ghcr.io/ot-container-kit/redis-operator/redis-operator",
        tags: ~w(v0.18.0 v0.18.1),
        default_tag: "v0.18.1"
      }),
    smtp4dev:
      Image.new!(%{
        name: "rnwood/smtp4dev",
        tags: ~w(3.1.4 3.5.1),
        default_tag: "3.5.1"
      }),
    trivy_operator:
      Image.new!(%{
        name: "ghcr.io/aquasecurity/trivy-operator",
        tags: ~w(0.22.0),
        default_tag: "0.22.0"
      }),
    aqua_node_collector:
      Image.new!(%{
        name: "ghcr.io/aquasecurity/node-collector",
        tags: ~w(0.3.1),
        default_tag: "0.3.1"
      }),
    aqua_trivy_checks:
      Image.new!(%{
        name: "ghcr.io/aquasecurity/trivy-checks",
        tags: ~w(0.13.0),
        default_tag: "0.13.0"
      }),
    trust_manager:
      Image.new!(%{
        name: "quay.io/jetstack/trust-manager",
        tags: ~w(v0.11.0 v0.12.0),
        default_tag: "v0.11.0"
      }),
    trust_manager_init:
      Image.new!(%{
        name: "quay.io/jetstack/cert-manager-package-debian",
        tags: ~w(20210119.0),
        default_tag: "20210119.0"
      }),
    vm_operator:
      Image.new!(%{
        name: "victoriametrics/operator",
        tags: ~w(v0.44.0),
        default_tag: "v0.44.0"
      }),
    knative_serving_activator:
      Image.new!(%{
        name: "gcr.io/knative-releases/knative.dev/serving/cmd/activator",
        tags: @knative_allowed_tags,
        default_tag: @knative_default_tag
      }),
    knative_serving_autoscaler:
      Image.new!(%{
        name: "gcr.io/knative-releases/knative.dev/serving/cmd/autoscaler",
        tags: @knative_allowed_tags,
        default_tag: @knative_default_tag
      }),
    knative_serving_controller:
      Image.new!(%{
        name: "gcr.io/knative-releases/knative.dev/serving/cmd/controller",
        tags: @knative_allowed_tags,
        default_tag: @knative_default_tag
      }),
    knative_serving_queue:
      Image.new!(%{
        name: "gcr.io/knative-releases/knative.dev/serving/cmd/queue",
        tags: @knative_allowed_tags,
        default_tag: @knative_default_tag
      }),
    knative_serving_webhook:
      Image.new!(%{
        name: "gcr.io/knative-releases/knative.dev/serving/cmd/webhook",
        tags: @knative_allowed_tags,
        default_tag: @knative_default_tag
      }),
    knative_istio_controller:
      Image.new!(%{
        name: "gcr.io/knative-releases/knative.dev/net-istio/cmd/controller",
        tags: @knative_istio_allowed_tags,
        default_tag: @knative_istio_default_tag
      }),
    knative_istio_webhook:
      Image.new!(%{
        name: "gcr.io/knative-releases/knative.dev/net-istio/cmd/webhook",
        tags: @knative_istio_allowed_tags,
        default_tag: @knative_istio_default_tag
      }),
    __schema_test:
      Image.new!(%{
        name: "ecto/schema/test",
        tags: ~w(1.2.3 1.2.4 latest),
        default_tag: "1.2.3"
      })
  }

  @spec get_image(atom()) :: Image.t() | nil
  def get_image(name) do
    @registry
    |> Enum.filter(fn {k, _v} -> k == name end)
    |> Enum.map(fn {_k, v} -> v end)
    |> List.first()
  end

  @spec get_image!(atom()) :: Image.t()
  def get_image!(name) do
    case get_image(name) do
      nil ->
        raise "Image #{name} not found"

      image ->
        image
    end
  end

  @spec vm_cluster_tag() :: String.t()
  def vm_cluster_tag, do: "v1.102.0-cluster"

  @spec vm_tag() :: String.t()
  def vm_tag, do: "v1.93.9"

  @spec batteries_included_version() :: String.t()
  def batteries_included_version do
    override =
      :common_core
      |> Application.get_env(CommonCore.Defaults)
      |> Keyword.get(:version_override, nil)

    if override == nil do
      @batteries_included_base
    else
      override
    end
  end

  @spec control_server_image() :: String.t()
  def control_server_image do
    ver = batteries_included_version()
    "ghcr.io/batteries-included/control-server:#{ver}"
  end

  @spec bootstrap_image() :: String.t()
  def bootstrap_image do
    ver = batteries_included_version()
    "ghcr.io/batteries-included/kube-bootstrap:#{ver}"
  end

  @spec home_base_image() :: String.t()
  def home_base_image do
    ver = batteries_included_version()
    "ghcr.io/batteries-included/home-base:#{ver}"
  end
end
