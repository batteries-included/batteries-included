defmodule CommonCore.ApiVersionKind do
  @moduledoc false
  import CommonCore.Resources.FieldAccessors, only: [api_version: 1, kind: 1]

  @known [
    api_service: {"apiregistration.k8s.io/v1", "APIService"},
    aqua_cluster_compliance_report: {"aquasecurity.github.io/v1alpha1", "ClusterComplianceReport"},
    aqua_cluster_config_audit_config_report: {"aquasecurity.github.io/v1alpha1", "ClusterConfigAuditReport"},
    aqua_cluster_infra_assesment_report: {"aquasecurity.github.io/v1alpha1", "ClusterInfraAssessmentReport"},
    aqua_cluster_rbac_assessment_report: {"aquasecurity.github.io/v1alpha1", "ClusterRbacAssessmentReport"},
    aqua_cluster_sbom_report: {"aquasecurity.github.io/v1alpha1", "ClusterSbomReport"},
    aqua_cluster_vulnerability_report: {"aquasecurity.github.io/v1alpha1", "ClusterVulnerabilityReport"},
    aqua_config_audit_report: {"aquasecurity.github.io/v1alpha1", "ConfigAuditReport"},
    aqua_exposed_secret_report: {"aquasecurity.github.io/v1alpha1", "ExposedSecretReport"},
    aqua_infra_assessment_report: {"aquasecurity.github.io/v1alpha1", "InfraAssessmentReport"},
    aqua_rbac_assessment_report: {"aquasecurity.github.io/v1alpha1", "RbacAssessmentReport"},
    aqua_sbom_report: {"aquasecurity.github.io/v1alpha1", "SbomReport"},
    aqua_vulnerability_report: {"aquasecurity.github.io/v1alpha1", "VulnerabilityReport"},
    certmanager_certificate: {"cert-manager.io/v1", "Certificate"},
    certmanager_certificate_request: {"cert-manager.io/v1", "CertificateRequest"},
    certmanager_challenge: {"acme.cert-manager.io/v1", "Challenge"},
    certmanager_cluster_issuer: {"cert-manager.io/v1", "ClusterIssuer"},
    certmanager_issuer: {"cert-manager.io/v1", "Issuer"},
    certmanager_order: {"acme.cert-manager.io/v1", "Order"},
    cloudnative_pg_backup: {"postgresql.cnpg.io/v1", "Backup"},
    cloudnative_pg_cluster: {"postgresql.cnpg.io/v1", "Cluster"},
    cloudnative_pg_cluster_image_catalog: {"postgresql.cnpg.io/v1", "ClusterImageCatalog"},
    cloudnative_pg_image_catalog: {"postgresql.cnpg.io/v1", "ImageCatalog"},
    cloudnative_pg_pooler: {"postgresql.cnpg.io/v1", "Pooler"},
    cloudnative_pg_scheduledbackup: {"postgresql.cnpg.io/v1", "ScheduledBackup"},
    cluster_role: {"rbac.authorization.k8s.io/v1", "ClusterRole"},
    cluster_role_binding: {"rbac.authorization.k8s.io/v1", "ClusterRoleBinding"},
    config_map: {"v1", "ConfigMap"},
    crd: {"apiextensions.k8s.io/v1", "CustomResourceDefinition"},
    daemon_set: {"apps/v1", "DaemonSet"},
    deployment: {"apps/v1", "Deployment"},
    endpoint: {"v1", "Endpoints"},
    event: {"v1", "Event"},
    horizontal_pod_autoscaler: {"autoscaling/v2", "HorizontalPodAutoscaler"},
    ingress: {"networking.k8s.io/v1", "Ingress"},
    ingress_class: {"networking.k8s.io/v1", "IngressClass"},
    ingress_class_params: {"elbv2.k8s.aws/v1beta1", "IngressClassParams"},
    istio_auth_policy: {"security.istio.io/v1beta1", "AuthorizationPolicy"},
    istio_envoy_filter: {"networking.istio.io/v1alpha3", "EnvoyFilter"},
    istio_gateway: {"networking.istio.io/v1beta1", "Gateway"},
    istio_peer_auth: {"security.istio.io/v1beta1", "PeerAuthentication"},
    istio_request_auth: {"security.istio.io/v1beta1", "RequestAuthentication"},
    istio_telemetry: {"telemetry.istio.io/v1alpha1", "Telemetry"},
    istio_virtual_service: {"networking.istio.io/v1beta1", "VirtualService"},
    istio_wasm_plugin: {"extensions.istio.io/v1alpha1", "WasmPlugin"},
    job: {"batch/v1", "Job"},
    karpenter_ec2node_class: {"karpenter.k8s.aws/v1", "EC2NodeClass"},
    karpenter_node_pool: {"karpenter.sh/v1", "NodePool"},
    knative_configuration: {"serving.knative.dev/v1", "Configuration"},
    knative_image: {"caching.internal.knative.dev/v1alpha1", "Image"},
    knative_revision: {"serving.knative.dev/v1", "Revision"},
    knative_route: {"serving.knative.dev/v1", "Route"},
    knative_service: {"serving.knative.dev/v1", "Service"},
    knative_serving: {"operator.knative.dev/v1beta1", "KnativeServing"},
    metal_address_pool: {"metallb.io/v1beta1", "AddressPool"},
    metal_ip_address_pool: {"metallb.io/v1beta1", "IPAddressPool"},
    metal_l2_advertisement: {"metallb.io/v1beta1", "L2Advertisement"},
    monitoring_endpoint_monitor: {"operator.victoriametrics.com/v1beta1", "VMStaticScrape"},
    monitoring_node_monitor: {"operator.victoriametrics.com/v1beta1", "VMNodeScrape"},
    monitoring_pod_monitor: {"operator.victoriametrics.com/v1beta1", "VMPodScrape"},
    monitoring_probe: {"operator.victoriametrics.com/v1beta1", "VMProbe"},
    monitoring_rule: {"operator.victoriametrics.com/v1beta1", "VMRule"},
    monitoring_service_monitor: {"operator.victoriametrics.com/v1beta1", "VMServiceScrape"},
    monitoring_scrape_config: {"operator.victoriametrics.com/v1beta1", "VMScrapeConfig"},
    mutating_webhook_config: {"admissionregistration.k8s.io/v1", "MutatingWebhookConfiguration"},
    namespace: {"v1", "Namespace"},
    node: {"v1", "Node"},
    node_feature: {"nfd.k8s-sigs.io/v1alpha1", "NodeFeature"},
    node_feature_group: {"nfd.k8s-sigs.io/v1alpha1", "NodeFeatureGroup"},
    node_feature_rule: {"nfd.k8s-sigs.io/v1alpha1", "NodeFeatureRule"},
    persistent_volume_claim: {"v1", "PersistentVolumeClaim"},
    pod: {"v1", "Pod"},
    pod_disruption_budget: {"policy/v1", "PodDisruptionBudget"},
    redis: {"redis.redis.opstreelabs.in/v1beta2", "Redis"},
    redis_cluster: {"redis.redis.opstreelabs.in/v1beta2", "RedisCluster"},
    redis_replication: {"redis.redis.opstreelabs.in/v1beta2", "RedisReplication"},
    redis_sentinel: {"redis.redis.opstreelabs.in/v1beta2", "RedisSentinel"},
    replicaset: {"apps/v1", "ReplicaSet"},
    role: {"rbac.authorization.k8s.io/v1", "Role"},
    role_binding: {"rbac.authorization.k8s.io/v1", "RoleBinding"},
    secret: {"v1", "Secret"},
    service: {"v1", "Service"},
    service_account: {"v1", "ServiceAccount"},
    stateful_set: {"apps/v1", "StatefulSet"},
    storage_class: {"storage.k8s.io/v1", "StorageClass"},
    trustmanager_bundle: {"trust.cert-manager.io/v1alpha1", "Bundle"},
    validating_webhook_config: {"admissionregistration.k8s.io/v1", "ValidatingWebhookConfiguration"},
    vm_agent: {"operator.victoriametrics.com/v1beta1", "VMAgent"},
    vm_alert: {"operator.victoriametrics.com/v1beta1", "VMAlert"},
    vm_alertmanager: {"operator.victoriametrics.com/v1beta1", "VMAlertmanager"},
    vm_alertmanager_config: {"operator.victoriametrics.com/v1beta1", "VMAlertmanagerConfig"},
    vm_cluster: {"operator.victoriametrics.com/v1beta1", "VMCluster"},
    vm_single: {"operator.victoriametrics.com/v1beta1", "VMSingle"}
  ]

  @alternatives [
    {:monitoring_service_monitor, {"monitoring.coreos.com/v1", "ServiceMonitor"}},
    {:monitoring_pod_monitor, {"monitoring.coreos.com/v1", "PodMonitor"}}
  ]

  @spec from_resource_type(atom) :: {binary(), binary()} | nil
  def from_resource_type(resource_type), do: Keyword.get(@known, resource_type, nil)

  @spec from_resource_type!(atom) :: {binary(), binary()}
  def from_resource_type!(resource_type), do: Keyword.fetch!(@known, resource_type)

  @spec all_known :: [atom()]
  def all_known, do: Keyword.keys(@known)

  @spec resource_type(map()) :: atom() | nil
  def resource_type(nil), do: nil

  def resource_type(resource) do
    case find_known(resource) do
      nil ->
        find_alternative(resource)

      val ->
        val
    end
  end

  defp find_known(resource) do
    resource_api_ver = api_version(resource)
    resource_kind = kind(resource)

    Enum.find_value(@known, nil, fn {type, {api_version, kind}} ->
      if api_version == resource_api_ver && kind == resource_kind, do: type
    end)
  end

  defp find_alternative(resource) do
    resource_api_ver = api_version(resource)
    resource_kind = kind(resource)

    Enum.find_value(@alternatives, nil, fn {type, {api_version, kind}} ->
      if api_version == resource_api_ver && kind == resource_kind, do: type
    end)
  end

  @spec resource_type!(map()) :: atom()
  def resource_type!(resource) do
    case resource_type(resource) do
      nil ->
        resource_api_ver = api_version(resource)
        resource_kind = kind(resource)
        raise "Unable to find suitable resource type for {#{resource_api_ver}, #{resource_kind}}"

      val ->
        val
    end
  end

  @spec watchable?({binary(), binary()}) :: boolean
  def watchable?({api_version, kind}), do: watchable?(api_version, kind)

  @spec watchable?(binary(), binary()) :: boolean
  def watchable?(api_version, kind) do
    Enum.any?(@known, fn {_key, {known_api, known_kind}} ->
      api_version == known_api && kind == known_kind
    end)
  end
end
