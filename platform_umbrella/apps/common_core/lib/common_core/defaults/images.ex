defmodule CommonCore.Defaults.Images do
  def control_server_image, do: "battery-registry:5000/battery/control:c6f4bd1-dirty1"

  def postgres_operator_image,
    do: "registry.opensource.zalan.do/acid/postgres-operator:v1.8.2-43-g3e148ea5"

  def spilo_image, do: "registry.opensource.zalan.do/acid/spilo-14:2.1-p7"

  def postgres_logical_backup_image,
    do: "registry.opensource.zalan.do/acid/logical-backup:v1.8.2-43-g3e148ea5"

  def postgres_bouncer_image, do: "registry.opensource.zalan.do/acid/pgbouncer:master-25"

  def redis_operator_image, do: "quay.io/spotahome/redis-operator:v1.2.2"

  def ceph_image, do: "quay.io/ceph/ceph:v17.2.3"

  def gitea_image, do: "gitea/gitea:1.16.8"

  def harbor_core_image, do: "goharbor/harbor-core:v2.6.2"
  def harbor_portal_image, do: "goharbor/harbor-portal:v2.6.2"
  def harbor_exporter_image, do: "goharbor/harbor-exporter:v2.6.2"
  def harbor_jobservice_image, do: "goharbor/harbor-jobservice:v2.6.2"
  def harbor_photon_image, do: "goharbor/registry-photon:v2.6.2"
  def harbor_ctl_image, do: "goharbor/harbor-registryctl:v2.6.2"
  def harbor_trivy_adapter_image, do: "goharbor/trivy-adapter-photon:v2.6.2"

  def prometheus_operator_image, do: "quay.io/prometheus-operator/prometheus-operator:v0.60.1"

  def prometheus_reloader_image,
    do: "quay.io/prometheus-operator/prometheus-config-reloader:v0.60.1"

  def prometheus_image, do: "quay.io/prometheus/prometheus:v2.39.2"

  def grafana_image, do: "grafana/grafana:9.2.4"
  def kiwigrid_sidecar_image, do: "quay.io/kiwigrid/k8s-sidecar:1.21.0"

  def node_exporter_image, do: "quay.io/prometheus/node-exporter:v1.4.0"
  def kube_state_metrics_image, do: "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.6.0"
  def alertmanager_image, do: "quay.io/prometheus/alertmanager:v0.24.0"

  def promtail_image, do: "grafana/promtail:2.7.0"
  def loki_image, do: "grafana/loki:2.7.0"
  def grafana_agent_operator_image, do: "grafana/agent-operator:v0.29.0"

  def istio_pilot_image, do: "istio/pilot:1.16.1"

  def knative_operator_webhook_image,
    do: "gcr.io/knative-releases/knative.dev/operator/cmd/webhook:v1.8.1"

  def knative_operator_image,
    do: "gcr.io/knative-releases/knative.dev/operator/cmd/operator:v1.8.1"

  def kiali_operator_image, do: "quay.io/kiali/kiali-operator:v1.59.1"

  def metallb_speaker_image, do: "quay.io/metallb/speaker:v0.13.7"
  def metallb_controller_image, do: "quay.io/metallb/controller:v0.13.7"

  def vm_cluster_tag, do: "v1.85.3-cluster"
  def vm_tag, do: "v1.85.3"

  def vmoperator_image, do: "victoriametrics/operator:v0.29.2"
end
