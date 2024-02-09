defmodule CommonCore.Resources.CertManager.TrustManager do
  @moduledoc false
  use CommonCore.IncludeResource,
    bundles_trust_cert_manager_io: "priv/manifests/cert_manager/trust_manager/bundles_trust_cert_manager_io.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "trust-manager"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:certmanager_certificate_trust, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("commonName", "trust-manager.#{namespace}.svc")
      |> Map.put("dnsNames", ["trust-manager.#{namespace}.svc"])
      |> Map.put(
        "issuerRef",
        %{"group" => "cert-manager.io", "kind" => "ClusterIssuer", "name" => "battery-ca"}
      )
      |> Map.put("revisionHistoryLimit", 1)
      |> Map.put("secretName", "trust-manager-tls")

    :certmanager_certificate
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:cluster_role_binding_trust_manager, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.role_ref(B.build_cluster_role_ref(@app_name))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_trust_manager) do
    rules = [
      %{"apiGroups" => ["trust.cert-manager.io"], "resources" => ["bundles"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["trust.cert-manager.io"], "resources" => ["bundles/finalizers"], "verbs" => ["update"]},
      %{"apiGroups" => ["trust.cert-manager.io"], "resources" => ["bundles/status"], "verbs" => ["patch"]},
      %{"apiGroups" => ["trust.cert-manager.io"], "resources" => ["bundles"], "verbs" => ["update"]},
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["get", "list", "create", "update", "patch", "watch", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.rules(rules)
  end

  resource(:crd_bundles_trust_cert_manager_io) do
    YamlElixir.read_all_from_string!(get_resource(:bundles_trust_cert_manager_io))
  end

  resource(:deployment_trust_manager, battery, state) do
    namespace = base_namespace(state)

    template =
      %{}
      |> Map.put(
        "metadata",
        %{"labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}}
      )
      |> Map.put(
        "spec",
        %{
          "containers" => [
            %{
              "args" => [
                "--log-level=1",
                "--metrics-port=9402",
                "--readiness-probe-port=6060",
                "--readiness-probe-path=/readyz",
                "--trust-namespace=#{namespace}",
                "--webhook-host=0.0.0.0",
                "--webhook-port=6443",
                "--webhook-certificate-dir=/tls",
                "--default-package-location=/packages/cert-manager-package-debian.json"
              ],
              "command" => ["trust-manager"],
              "image" => "quay.io/jetstack/trust-manager:v0.8.0",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "trust-manager",
              "ports" => [%{"containerPort" => 6443}, %{"containerPort" => 9402}],
              "readinessProbe" => %{
                "httpGet" => %{"path" => "/readyz", "port" => 6060},
                "initialDelaySeconds" => 3,
                "periodSeconds" => 7
              },
              "resources" => %{},
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "readOnlyRootFilesystem" => true,
                "runAsNonRoot" => true,
                "seccompProfile" => %{"type" => "RuntimeDefault"}
              },
              "volumeMounts" => [
                %{"mountPath" => "/tls", "name" => "tls", "readOnly" => true},
                %{"mountPath" => "/packages", "name" => "packages", "readOnly" => true}
              ]
            }
          ],
          "initContainers" => [
            %{
              "args" => ["/copyandmaybepause", "/debian-package", "/packages"],
              "image" => "quay.io/jetstack/cert-manager-package-debian:20210119.0",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "cert-manager-package-debian",
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "readOnlyRootFilesystem" => true,
                "runAsNonRoot" => true,
                "seccompProfile" => %{"type" => "RuntimeDefault"}
              },
              "volumeMounts" => [%{"mountPath" => "/packages", "name" => "packages", "readOnly" => false}]
            }
          ],
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "serviceAccountName" => @app_name,
          "volumes" => [
            %{"emptyDir" => %{}, "name" => "packages"},
            %{"name" => "tls", "secret" => %{"defaultMode" => 420, "secretName" => "trust-manager-tls"}}
          ]
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:role_binding_trust_manager, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@app_name))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:role_binding_trust_manager_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("trust-manager:leaderelection")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("trust-manager:leaderelection"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:role_trust_manager, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]}
    ]

    :role
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_trust_manager_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "create", "update", "watch", "list"]
      }
    ]

    :role
    |> B.build_resource()
    |> B.name("trust-manager:leaderelection")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:service_account_trust_manager, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
  end

  resource(:service_trust_manager, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "webhook", "port" => 443, "protocol" => "TCP", "targetPort" => 6443}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})
      |> Map.put("type", "ClusterIP")

    :service
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_trust_manager_metrics, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "metrics", "port" => 9402, "protocol" => "TCP", "targetPort" => 9402}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})
      |> Map.put("type", "ClusterIP")

    :service
    |> B.build_resource()
    |> B.name("trust-manager-metrics")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:validating_webhook_config_trust_manager, _battery, state) do
    namespace = base_namespace(state)

    :validating_webhook_config
    |> B.build_resource()
    |> B.name(@app_name)
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "trust-manager",
            "namespace" => namespace,
            "path" => "/validate-trust-cert-manager-io-v1alpha1-bundle"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "trust.cert-manager.io",
        "rules" => [
          %{
            "apiGroups" => ["trust.cert-manager.io"],
            "apiVersions" => ["*"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["*/*"]
          }
        ],
        "sideEffects" => "None",
        "timeoutSeconds" => 5
      }
    ])
  end

  resource(:service_monitor_trust_manager, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "honorLabels" => false,
          "interval" => "60s",
          "path" => "/metrics",
          "scrapeTimeout" => "30s",
          "targetPort" => 9402
        }
      ])
      |> Map.put("jobLabel", @app_name)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("trust-manager")
    |> B.namespace(namespace)
    |> B.label("prometheus", "default")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
