defmodule CommonCore.Defaults.Images do
  def control_server_image, do: "battery-registry:5000/battery/control:c6f4bd1-dirty1"

  def postgres_operator_image,
    do: "registry.opensource.zalan.do/acid/postgres-operator:v1.9.0-8-g645fcc01"

  def spilo_image, do: "registry.opensource.zalan.do/acid/spilo-15:2.1-p9"

  def postgres_logical_backup_image,
    do: "registry.opensource.zalan.do/acid/logical-backup:v1.9.0-8-g645fcc01"

  def postgres_bouncer_image, do: "registry.opensource.zalan.do/acid/pgbouncer:master-27"

  def redis_operator_image, do: "quay.io/spotahome/redis-operator:v1.2.4"

  def ceph_image, do: "quay.io/ceph/ceph:v17.2.5"

  def gitea_image, do: "gitea/gitea:1.18.3"

  def harbor_core_image, do: "goharbor/harbor-core:v2.5.6"
  def harbor_portal_image, do: "goharbor/harbor-portal:v2.5.6"
  def harbor_exporter_image, do: "goharbor/harbor-exporter:v2.5.6"
  def harbor_jobservice_image, do: "goharbor/harbor-jobservice:v2.5.6"
  def harbor_photon_image, do: "goharbor/registry-photon:v2.5.6"
  def harbor_ctl_image, do: "goharbor/harbor-registryctl:v2.5.6"
  def harbor_trivy_adapter_image, do: "goharbor/trivy-adapter-photon:v2.5.6"

  def grafana_image, do: "grafana/grafana:9.3.6"
  def kiwigrid_sidecar_image, do: "quay.io/kiwigrid/k8s-sidecar:1.22.2"

  def node_exporter_image, do: "quay.io/prometheus/node-exporter:v1.5.0"
  def kube_state_metrics_image, do: "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.7.0"
  def alertmanager_image, do: "quay.io/prometheus/alertmanager:v0.24.0"

  def promtail_image, do: "grafana/promtail:2.7.4"
  def loki_image, do: "grafana/loki:2.7.4"

  def istio_pilot_image, do: "istio/pilot:1.17.1-distroless"

  def knative_operator_webhook_image,
    do: "gcr.io/knative-releases/knative.dev/operator/cmd/webhook:v1.8.4"

  def knative_operator_image,
    do: "gcr.io/knative-releases/knative.dev/operator/cmd/operator:v1.8.4"

  def kiali_operator_image, do: "quay.io/kiali/kiali-operator:v1.62.0"

  def metallb_speaker_image, do: "quay.io/metallb/speaker:v0.13.7"
  def metallb_controller_image, do: "quay.io/metallb/controller:v0.13.9"

  def vm_cluster_tag, do: "v1.88.0-cluster"
  def vm_tag, do: "v1.88.0"

  def vmoperator_image, do: "victoriametrics/operator:v0.30.4"

  def smtp4dev_image, do: "rnwood/smtp4dev:3.1.4"
end
