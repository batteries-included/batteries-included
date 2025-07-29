defmodule CommonCore.Resources.Knative.NetGateway do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "knative-serving"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.Secret

  resource(:cluster_role_knative_gateway_api_admin) do
    rules = []

    :cluster_role
    |> B.build_resource()
    |> B.name("knative-gateway-api-admin")
    |> B.component_labels("net-gateway-api")
    |> B.label("networking.knative.dev/ingress-provider", "net-gateway-api")
    |> Map.put("aggregationRule", %{
      "clusterRoleSelectors" => [%{"matchLabels" => %{"serving.knative.dev/controller" => "true"}}]
    })
    |> B.rules(rules)
  end

  resource(:cluster_role_knative_gateway_api_core) do
    rules = [
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => ["httproutes", "referencegrants", "referencepolicies"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => ["gateways"],
        "verbs" => ["get", "list", "update", "patch", "watch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("knative-gateway-api-core")
    |> B.component_labels("net-gateway-api")
    |> B.component_labels("knative-serving")
    |> B.label("networking.knative.dev/ingress-provider", "net-gateway-api")
    |> B.label("serving.knative.dev/controller", "true")
    |> B.rules(rules)
  end

  resource(:config_map_gateway, _battery, state) do
    namespace = knative_namespace(state)

    data = %{
      # This is used for "external" services - e.g. publicly accessible
      "external-gateways" =>
        Ymlr.document!([
          %{
            class: "istio",
            gateway: "#{istio_namespace(state)}/istio-ingressgateway",
            service: "#{istio_namespace(state)}/istio-ingressgateway"
          }
        ]),
      # This is used for "internal" services - e.g. not publicly accessible
      # By default, it is going to try to use the `istio-system` ns
      "local-gateways" =>
        Ymlr.document!([
          %{
            class: "istio",
            gateway: "#{namespace}/knative-local-gateway",
            service: "#{namespace}/knative-local-gateway-istio"
          }
        ])
    }

    :config_map
    |> B.build_resource()
    |> B.name("config-gateway")
    |> B.namespace(namespace)
    |> B.component_labels("net-gateway-api")
    |> B.component_labels("knative-serving")
    |> B.label("networking.knative.dev/ingress-provider", "net-gateway-api")
    |> B.data(data)
  end

  resource(:deployment_net_gateway_api_controller, battery, state) do
    namespace = knative_namespace(state)

    template =
      %{}
      |> Map.put("spec", %{
        "affinity" => %{
          "podAntiAffinity" => %{
            "preferredDuringSchedulingIgnoredDuringExecution" => [
              %{
                "podAffinityTerm" => %{
                  "labelSelector" => %{"matchLabels" => %{"app" => "net-gateway-api-controller"}},
                  "topologyKey" => "kubernetes.io/hostname"
                },
                "weight" => 100
              }
            ]
          }
        },
        "containers" => [
          %{
            "env" => [
              %{
                "name" => "SYSTEM_NAMESPACE",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
              },
              %{"name" => "CONFIG_LOGGING_NAME", "value" => "config-logging"},
              %{"name" => "CONFIG_OBSERVABILITY_NAME", "value" => "config-observability"},
              %{"name" => "METRICS_DOMAIN", "value" => "knative.dev/net-gateway-api"}
            ],
            "image" => battery.config.gateway_controller_image,
            "name" => "controller",
            "ports" => [
              %{"containerPort" => 9090, "name" => "metrics"},
              %{"containerPort" => 8008, "name" => "profiling"}
            ],
            "resources" => %{
              "limits" => %{"cpu" => "1000m", "memory" => "1000Mi"},
              "requests" => %{"cpu" => "100m", "memory" => "100Mi"}
            },
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true,
              "seccompProfile" => %{"type" => "RuntimeDefault"}
            }
          }
        ],
        "serviceAccountName" => "controller"
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "net-gateway-api"}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("net-gateway-api-controller")
    |> B.namespace(namespace)
    |> B.component_labels("net-gateway-api")
    |> B.label("networking.knative.dev/ingress-provider", "net-gateway-api")
    |> B.spec(spec)
  end

  resource(:deployment_net_gateway_api_webhook, battery, state) do
    namespace = knative_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{"labels" => %{"role" => "net-gateway-api-webhook"}})
      |> Map.put("spec", %{
        "containers" => [
          %{
            "env" => [
              %{
                "name" => "SYSTEM_NAMESPACE",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
              },
              %{"name" => "CONFIG_LOGGING_NAME", "value" => "config-logging"},
              %{"name" => "CONFIG_OBSERVABILITY_NAME", "value" => "config-observability"},
              %{"name" => "METRICS_DOMAIN", "value" => "knative.dev/net-gateway-api"},
              %{"name" => "WEBHOOK_NAME", "value" => "net-gateway-api-webhook"},
              %{"name" => "WEBHOOK_PORT", "value" => "8443"}
            ],
            "image" => battery.config.gateway_webhook_image,
            "livenessProbe" => %{
              "failureThreshold" => 6,
              "httpGet" => %{"port" => 8443, "scheme" => "HTTPS"},
              "initialDelaySeconds" => 20,
              "periodSeconds" => 1
            },
            "name" => "webhook",
            "ports" => [
              %{"containerPort" => 9090, "name" => "metrics"},
              %{"containerPort" => 8008, "name" => "profiling"},
              %{"containerPort" => 8443, "name" => "https-webhook"}
            ],
            "readinessProbe" => %{
              "failureThreshold" => 3,
              "httpGet" => %{"port" => 8443, "scheme" => "HTTPS"},
              "periodSeconds" => 1
            },
            "resources" => %{
              "limits" => %{"cpu" => "200m", "memory" => "200Mi"},
              "requests" => %{"cpu" => "20m", "memory" => "20Mi"}
            },
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "runAsNonRoot" => true,
              "seccompProfile" => %{"type" => "RuntimeDefault"}
            }
          }
        ],
        "serviceAccountName" => "controller"
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "role" => "net-gateway-api-webhook"}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("net-gateway-api-webhook")
    |> B.namespace(namespace)
    |> B.component_labels("net-gateway-api")
    |> B.label("networking.knative.dev/ingress-provider", "gateway-api")
    |> B.spec(spec)
  end

  resource(:secret_net_gateway_api_webhook_certs, _battery, state) do
    namespace = knative_namespace(state)

    data = Secret.encode(%{})

    :secret
    |> B.build_resource()
    |> B.name("net-gateway-api-webhook-certs")
    |> B.namespace(namespace)
    |> B.component_labels("net-gateway-api")
    |> B.label("networking.knative.dev/ingress-provider", "gateway-api")
    |> B.data(data)
  end

  resource(:service_net_gateway_api_webhook, _battery, state) do
    namespace = knative_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 9090, "targetPort" => "metrics"},
        %{"name" => "http-profiling", "port" => 8008, "targetPort" => "profiling"},
        %{"name" => "https-webhook", "port" => 443, "targetPort" => "https-webhook"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "role" => "net-gateway-api-webhook"})

    :service
    |> B.build_resource()
    |> B.name("net-gateway-api-webhook")
    |> B.namespace(namespace)
    |> B.component_labels("net-gateway-api")
    |> B.label("networking.knative.dev/ingress-provider", "gateway-api")
    |> B.label("role", "net-gateway-api-webhook")
    |> B.spec(spec)
  end

  resource(:validating_webhook_config_gateway_api_networking_internal_knative_dev) do
    :validating_webhook_config
    |> B.build_resource()
    |> B.name("config.webhook.gateway-api.networking.internal.knative.dev")
    |> B.component_labels("net-gateway-api")
    |> B.component_labels("knative-serving")
    |> B.label("networking.knative.dev/ingress-provider", "gateway-api")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1", "v1beta1"],
        "clientConfig" => %{
          "service" => %{"name" => "net-gateway-api-webhook", "namespace" => "knative-serving"}
        },
        "failurePolicy" => "Fail",
        "name" => "config.webhook.gateway-api.networking.internal.knative.dev",
        "objectSelector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/component" => "net-gateway-api",
            "app.kubernetes.io/name" => "knative-serving"
          }
        },
        "sideEffects" => "None"
      }
    ])
  end

  resource(:gateway_knative_local, battery, _state) do
    ns = battery.config.namespace

    spec =
      %{}
      |> Map.put("gatewayClassName", "istio")
      |> Map.put("listeners", [%{"name" => "http", "port" => 80, "protocol" => "HTTP"}])

    :gateway
    |> B.build_resource()
    |> B.name("knative-local-gateway")
    |> B.namespace(ns)
    |> B.component_labels("net-gateway-api")
    |> B.label("networking.knative.dev/ingress-provider", "gateway-api")
    |> B.spec(spec)
  end
end
