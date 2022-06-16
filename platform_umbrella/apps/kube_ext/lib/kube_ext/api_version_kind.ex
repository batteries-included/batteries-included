defmodule KubeExt.ApiVersionKind do
  import K8s.Resource

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
    horizontal_pod_autoscaler: {"autoscaling/v2beta2", "HorizontalPodAutoscaler"},
    istio_gateway: {"networking.istio.io/v1alpha3", "Gateway"},
    istio_virtual_service: {"networking.istio.io/v1alpha3", "VirtualService"},
    istio_envoy_filter: {"networking.istio.io/v1alpha3", "EnvoyFilter"},
    istio_telemetry: {"telemetry.istio.io/v1alpha1", "Telemetry"},
    service_monitor: {"monitoring.coreos.com/v1", "ServiceMonitor"},
    pod_monitor: {"monitoring.coreos.com/v1", "PodMonitor"},
    prometheus: {"monitoring.coreos.com/v1", "Prometheus"},
    alertmanager: {"monitoring.coreos.com/v1", "Alertmanager"},
    alertmanager_config: {"monitoring.coreos.com/v1alpha1", "AlertmanagerConfig"},
    knative_serving: {"operator.knative.dev/v1beta1", "KnativeServing"},
    knative_service: {"serving.knative.dev/v1", "Service"},
    knative_configuration: {"serving.knative.dev/v1", "Configuration"},
    knative_revision: {"serving.knative.dev/v1", "Revision"},
    postgresql: {"acid.zalan.do/v1", "postgresql"},
    postgresql_operator_config: {"acid.zalan.do/v1", "OperatorConfiguration"},
    keycloak: {"keycloak.org/v1alpha1", "Keycloak"},
    tekton_task: {"tekton.dev/v1beta1", "Task"},
    redis_failover: {"databases.spotahome.com/v1", "RedisFailover"},
    certmanger_certificate: {"cert-manager.io/v1", "Certificate"},
    certmanger_issuer: {"cert-manager.io/v1", "Issuer"}
  ]

  def from_resource_type(resource_type), do: Keyword.get(@known, resource_type, nil)

  def all_known, do: Keyword.keys(@known)

  def resource_type(resource) do
    {key, _} =
      Enum.find(@known, {nil, nil}, fn {_key, {api_version, kind}} ->
        api_version == api_version(resource) && kind == kind(resource)
      end)

    key
  end

  def is_watchable({api_version, kind}), do: is_watchable(api_version, kind)

  def is_watchable(api_version, kind) do
    Enum.any?(@known, fn {_key, {known_api, known_kind}} ->
      api_version == known_api && kind == known_kind
    end)
  end
end
