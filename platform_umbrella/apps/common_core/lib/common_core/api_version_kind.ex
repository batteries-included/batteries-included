defmodule CommonCore.ApiVersionKind do
  @known [
    namespace: {"v1", "Namespace"},
    pod: {"v1", "Pod"},
    service: {"v1", "Service"},
    service_account: {"v1", "ServiceAccount"},
    node: {"v1", "Node"},
    config_map: {"v1", "ConfigMap"},
    secret: {"v1", "Secret"},
    persistent_volume_claim: {"v1", "PersistentVolumeClaim"},
    job: {"batch/v1", "Job"},
    daemon_set: {"apps/v1", "DaemonSet"},
    deployment: {"apps/v1", "Deployment"},
    replicaset: {"apps/v1", "ReplicaSet"},
    stateful_set: {"apps/v1", "StatefulSet"},
    role: {"rbac.authorization.k8s.io/v1", "Role"},
    role_binding: {"rbac.authorization.k8s.io/v1", "RoleBinding"},
    cluster_role: {"rbac.authorization.k8s.io/v1", "ClusterRole"},
    cluster_role_binding: {"rbac.authorization.k8s.io/v1", "ClusterRoleBinding"},
    crd: {"apiextensions.k8s.io/v1", "CustomResourceDefinition"},
    validating_webhook_config:
      {"admissionregistration.k8s.io/v1", "ValidatingWebhookConfiguration"},
    mutating_webhook_config: {"admissionregistration.k8s.io/v1", "MutatingWebhookConfiguration"},
    ingress: {"networking.k8s.io/v1", "Ingress"},
    pod_disruption_budget: {"policy/v1beta1", "PodDisruptionBudget"},
    pod_security_policy: {"policy/v1beta1", "PodSecurityPolicy"},
    horizontal_pod_autoscaler: {"autoscaling/v2", "HorizontalPodAutoscaler"},
    istio_gateway: {"networking.istio.io/v1beta1", "Gateway"},
    istio_virtual_service: {"networking.istio.io/v1beta1", "VirtualService"},
    istio_envoy_filter: {"networking.istio.io/v1alpha3", "EnvoyFilter"},
    istio_telemetry: {"telemetry.istio.io/v1alpha1", "Telemetry"},
    istio_peer_auth: {"security.istio.io/v1beta1", "PeerAuthentication"},
    istio_auth_policy: {"security.istio.io/v1beta1", "AuthorizationPolicy"},
    istio_request_auth: {"security.istio.io/v1beta1", "RequestAuthentication"},
    istio_wasm_plugin: {"extensions.istio.io/v1alpha1", "WasmPlugin"},
    kiali: {"kiali.io/v1alpha1", "Kiali"},
    knative_serving: {"operator.knative.dev/v1beta1", "KnativeServing"},
    knative_eventing: {"operator.knative.dev/v1beta1", "KnativeEventing"},
    knative_service: {"serving.knative.dev/v1", "Service"},
    knative_configuration: {"serving.knative.dev/v1", "Configuration"},
    knative_revision: {"serving.knative.dev/v1", "Revision"},
    postgresql: {"acid.zalan.do/v1", "postgresql"},
    postgresql_operator_config: {"acid.zalan.do/v1", "OperatorConfiguration"},
    postgres_team: {"acid.zalan.do/v1", "PostgresTeam"},
    redis_failover: {"databases.spotahome.com/v1", "RedisFailover"},
    certmanger_certificate: {"cert-manager.io/v1", "Certificate"},
    certmanger_challenge: {"acme.cert-manager.io/v1", "Challenge"},
    certmanager_order: {"acme.cert-manager.io/v1", "Order"},
    certmanger_issuer: {"cert-manager.io/v1", "Issuer"},
    certmanger_cluster_issuer: {"cert-manager.io/v1", "ClusterIssuer"},
    certmanager_certificate_request: {"cert-manager.io/v1", "CertificateRequest"},
    trustmanager_bundle: {"trust.cert-manager.io/v1alpha1", "Bundle"},
    ceph_cluster: {"ceph.rook.io/v1", "CephCluster"},
    ceph_filesystem: {"ceph.rook.io/v1", "CephFilesystem"},
    metal_ip_address_pool: {"metallb.io/v1beta1", "IPAddressPool"},
    metal_address_pool: {"metallb.io/v1beta1", "AddressPool"},
    metal_l2_advertisement: {"metallb.io/v1beta1", "L2Advertisement"},
    monitoring_service_monitor: {"monitoring.coreos.com/v1", "ServiceMonitor"},
    monitoring_pod_monitor: {"monitoring.coreos.com/v1", "PodMonitor"}
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
    {key, _} =
      Enum.find(@known, {nil, nil}, fn {_type, {api_version, kind}} ->
        api_version == api_version(resource) && kind == kind(resource)
      end)

    key
  end

  def resource_type!(resource) do
    {key, _} =
      Enum.find(@known, fn {_key, {api_version, kind}} ->
        api_version == api_version(resource) && kind == kind(resource)
      end)

    key
  end

  @spec is_watchable({binary(), binary()}) :: boolean
  def is_watchable({api_version, kind}), do: is_watchable(api_version, kind)

  @spec is_watchable(binary(), binary()) :: boolean
  def is_watchable(api_version, kind) do
    Enum.any?(@known, fn {_key, {known_api, known_kind}} ->
      api_version == known_api && kind == known_kind
    end)
  end

  defp api_version(%{} = res), do: Map.get(res, "apiVersion")
  defp kind(%{} = res), do: Map.get(res, "kind")
end
