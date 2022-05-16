defmodule KubeState.ApiVersionKind do
  @known [
    namespaces: {"v1", "Namespace"},
    pods: {"v1", "Pod"},
    services: {"v1", "Service"},
    service_accounts: {"v1", "ServiceAccount"},
    nodes: {"v1", "Node"},
    config_maps: {"v1", "ConfigMap"},
    secrets: {"v1", "Secret"},
    daemon_sets: {"apps/v1", "DaemonSet"},
    deployments: {"apps/v1", "Deployment"},
    stateful_sets: {"apps/v1", "StatefulSet"},
    role: {"rbac.authorization.k8s.io/v1", "Role"},
    role_bindings: {"rbac.authorization.k8s.io/v1", "RoleBinding"},
    cluster_roles: {"rbac.authorization.k8s.io/v1", "ClusterRole"},
    cluster_role_bindings: {"rbac.authorization.k8s.io/v1", "ClusterRoleBinding"},
    crds: {"apiextensions.k8s.io/v1", "CustomResourceDefinition"},
    validating_webhook_configs:
      {"admissionregistration.k8s.io/v1", "ValidatingWebhookConfiguration"},
    mutating_webhook_configs: {"admissionregistration.k8s.io/v1", "MutatingWebhookConfiguration"},
    ingresses: {"networking.k8s.io/v1", "Ingress"},
    pod_disruption_budgets: {"policy/v1beta1", "PodDisruptionBudget"},
    horizontal_pod_autoscalers: {"autoscaling/v2beta2", "HorizontalPodAutoscaler"},
    istio_gateway: {"networking.istio.io/v1alpha3", "Gateway"},
    istio_virtual_services: {"networking.istio.io/v1alpha3", "VirtualService"},
    istio_envoy_filters: {"networking.istio.io/v1alpha3", "EnvoyFilter"},
    istio_telemetry: {"telemetry.istio.io/v1alpha1", "Telemetry"},
    service_monitors: {"monitoring.coreos.com/v1", "ServiceMonitor"},
    pod_monitors: {"monitoring.coreos.com/v1", "PodMonitor"},
    prometheus: {"monitoring.coreos.com/v1", "Prometheus"},
    alertmanagers: {"monitoring.coreos.com/v1", "Alertmanager"},
    alertmanager_configs: {"monitoring.coreos.com/v1alpha1", "AlertmanagerConfig"},
    knative_servings: {"operator.knative.dev/v1alpha1", "KnativeServing"},
    knative_services: {"serving.knative.dev/v1", "Service"},
    postgresqls: {"acid.zalan.do/v1", "postgresql"},
    postgresql_operator_configs: {"acid.zalan.do/v1", "OperatorConfiguration"},
    keycloaks: {"keycloak.org/v1alpha1", "Keycloak"}
  ]

  def from_resource_type(resource_type), do: Keyword.get(@known, resource_type, nil)

  def all_known, do: Keyword.keys(@known)

  def is_watchable({api_version, kind}), do: is_watchable(api_version, kind)

  def is_watchable(api_version, kind) do
    Enum.any?(@known, fn {_key, {known_api, known_kind}} ->
      api_version == known_api && kind == known_kind
    end)
  end
end
