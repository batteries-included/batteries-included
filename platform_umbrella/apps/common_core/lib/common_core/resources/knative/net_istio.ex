defmodule CommonCore.Resources.KnativeNetIstio do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "knative-serving"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.SSL

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret

  resource(:cluster_role_knative_serving_istio) do
    rules = [
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["virtualservices", "gateways", "destinationrules"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("knative-serving-istio")
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.label("serving.knative.dev/controller", "true")
    |> B.rules(rules)
  end

  resource(:config_map_istio, battery, state) do
    # This determines the configuration of the virtual services for knative services
    data = %{
      # This is used for "external" services - e.g. publicly accessible
      "external-gateways" =>
        Ymlr.document!([
          %{
            name: "knative-ingress-gateway",
            namespace: battery.config.namespace,
            service: "istio-ingressgateway.#{istio_namespace(state)}.svc.cluster.local."
          }
        ]),
      # This is used for "internal" services - e.g. not publicly accessible
      # By default, it is going to try to use the `istio-system` ns
      "local-gateways" =>
        Ymlr.document!([
          %{
            name: "knative-local-gateway",
            namespace: battery.config.namespace,
            service: "knative-local-gateway.#{battery.config.namespace}.svc.cluster.local."
          }
        ])
    }

    :config_map
    |> B.build_resource()
    |> B.name("config-istio")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.data(data)
  end

  resource(:deployment_net_istio_controller, battery, _state) do
    template =
      %{
        "metadata" => %{
          "labels" => %{
            "battery/managed" => "true",
            "sidecar.istio.io/inject" => "false"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "env" => [
                %{"name" => "SYSTEM_NAMESPACE", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}},
                %{"name" => "CONFIG_LOGGING_NAME", "value" => "config-logging"},
                %{"name" => "CONFIG_OBSERVABILITY_NAME", "value" => "config-observability"},
                %{"name" => "ENABLE_SECRET_INFORMER_FILTERING_BY_CERT_UID", "value" => "false"},
                %{"name" => "METRICS_DOMAIN", "value" => "knative.dev/net-istio"}
              ],
              "image" => battery.config.istio_controller_image,
              "livenessProbe" => %{
                "failureThreshold" => 6,
                "httpGet" => %{"path" => "/health", "port" => "probes", "scheme" => "HTTP"},
                "periodSeconds" => 5
              },
              "name" => "controller",
              "ports" => [
                %{"containerPort" => 9090, "name" => "metrics"},
                %{"containerPort" => 8008, "name" => "profiling"},
                %{"containerPort" => 8080, "name" => "probes"}
              ],
              "readinessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{"path" => "/readiness", "port" => "probes", "scheme" => "HTTP"},
                "periodSeconds" => 5
              },
              "resources" => %{
                "limits" => %{"cpu" => "300m", "memory" => "400Mi"},
                "requests" => %{"cpu" => "30m", "memory" => "40Mi"}
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
        }
      }
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.label("role", "net-istio-controller")
      |> B.component_labels("net-istio")

    spec =
      %{}
      |> Map.put("selector", %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "battery/component" => "net-istio",
          "role" => "net-istio-controller"
        }
      })
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("net-istio-controller")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.spec(spec)
  end

  resource(:deployment_net_istio_webhook, battery, _state) do
    template =
      %{
        "metadata" => %{
          "labels" => %{
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "env" => [
                %{"name" => "SYSTEM_NAMESPACE", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}},
                %{"name" => "CONFIG_LOGGING_NAME", "value" => "config-logging"},
                %{"name" => "CONFIG_OBSERVABILITY_NAME", "value" => "config-observability"},
                %{"name" => "METRICS_DOMAIN", "value" => "knative.dev/net-istio"},
                %{"name" => "WEBHOOK_NAME", "value" => "net-istio-webhook"},
                %{"name" => "WEBHOOK_PORT", "value" => "8443"}
              ],
              "image" => battery.config.istio_webhook_image,
              "livenessProbe" => %{
                "failureThreshold" => 6,
                "httpGet" => %{
                  "httpHeaders" => [%{"name" => "k-kubelet-probe", "value" => "webhook"}],
                  "port" => 8443,
                  "scheme" => "HTTPS"
                },
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
                "httpGet" => %{
                  "httpHeaders" => [%{"name" => "k-kubelet-probe", "value" => "webhook"}],
                  "port" => 8443,
                  "scheme" => "HTTPS"
                },
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
        }
      }
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.label("role", "net-istio-webhook")
      |> B.component_labels("net-istio")

    spec =
      %{}
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "battery/component" => "net-istio",
            "role" => "net-istio-webhook"
          }
        }
      )
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("net-istio-webhook")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.spec(spec)
  end

  resource(:istio_gateway_knative_ingress, battery, state) do
    hosts =
      state.knative_services
      |> Enum.map(&knative_host(state, &1))
      |> Enum.filter(& &1)
      |> Enum.uniq()

    spec =
      %{}
      |> Map.put("selector", %{"istio" => "ingressgateway"})
      |> Map.put("servers", servers(hosts, ssl_enabled?(state)))

    :istio_gateway
    |> B.build_resource()
    |> B.name("knative-ingress-gateway")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.spec(spec)
    |> F.require_non_empty(hosts)
  end

  defp servers(hosts, false = _ssl_enabled?), do: [http_server(hosts)]
  defp servers(hosts, true = _ssl_enabled?), do: [http_server(hosts), https_server(hosts)]

  defp http_server(hosts), do: %{"hosts" => hosts, "port" => %{"name" => "http", "number" => 80, "protocol" => "HTTP"}}

  defp https_server(hosts),
    do: %{
      hosts: hosts,
      port: %{number: 443, name: "https", protocol: "HTTPS"},
      tls: %{mode: "SIMPLE", credentialName: "knative-ingress-cert"}
    }

  resource(:istio_gateway_knative_local, battery, _state) do
    ns = battery.config.namespace

    spec =
      %{}
      |> Map.put("selector", %{"istio" => "ingressgateway"})
      |> Map.put("servers", [
        %{
          "hosts" => [
            "*.#{ns}.svc.cluster.local",
            "*.#{ns}.svc",
            "*.#{ns}"
          ],
          "port" => %{"name" => "http", "number" => 8081, "protocol" => "HTTP"}
        }
      ])

    :istio_gateway
    |> B.build_resource()
    |> B.name("knative-local-gateway")
    |> B.namespace(ns)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.spec(spec)
  end

  resource(:service_knative_local_gateway, battery, _state) do
    spec =
      %{}
      |> Map.put("ports", [%{"name" => "http2", "port" => 80, "targetPort" => 8081}])
      |> Map.put("selector", %{"istio" => "ingressgateway"})

    :service
    |> B.build_resource()
    |> B.name("knative-local-gateway")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("experimental.istio.io/disable-gateway-port-translation", "true")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.spec(spec)
  end

  resource(:istio_peer_auth_net_webhook, battery, _state) do
    spec =
      %{}
      |> Map.put("portLevelMtls", %{"8443" => %{"mode" => "PERMISSIVE"}})
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "net-istio", "role" => "net-istio-webhook"}
      })

    :istio_peer_auth
    |> B.build_resource()
    |> B.name("net-istio-webhook")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.spec(spec)
  end

  resource(:istio_peer_auth_webhook, battery, _state) do
    spec =
      %{}
      |> Map.put("portLevelMtls", %{"8443" => %{"mode" => "PERMISSIVE"}})
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "webhook"}})

    :istio_peer_auth
    |> B.build_resource()
    |> B.name("webhook")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.spec(spec)
  end

  resource(:secret_net_istio_webhook_certs, battery, _state) do
    data = Secret.encode(%{})

    :secret
    |> B.build_resource()
    |> B.name("net-istio-webhook-certs")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.data(data)
  end

  resource(:service_net_istio_webhook, battery, _state) do
    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 9090, "targetPort" => "metrics"},
        %{"name" => "http-profiling", "port" => 8008, "targetPort" => "profiling"},
        %{"name" => "https-webhook", "port" => 443, "targetPort" => "https-webhook"}
      ])
      |> Map.put("selector", %{
        "battery/app" => @app_name,
        "battery/component" => "net-istio",
        "role" => "net-istio-webhook"
      })

    :service
    |> B.build_resource()
    |> B.name("net-istio-webhook")
    |> B.namespace(battery.config.namespace)
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> B.spec(spec)
  end

  resource(:validating_webhook_config_istio_networking_internal_knative_dev, battery, _state) do
    :validating_webhook_config
    |> B.build_resource()
    |> B.name("config.webhook.istio.networking.internal.knative.dev")
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1", "v1beta1"],
        "clientConfig" => %{"service" => %{"name" => "net-istio-webhook", "namespace" => battery.config.namespace}},
        "failurePolicy" => "Fail",
        "name" => "config.webhook.istio.networking.internal.knative.dev",
        "objectSelector" => %{
          "matchLabels" => %{"battery/component" => "net-istio", "battery/app" => @app_name}
        },
        "sideEffects" => "None"
      }
    ])
  end

  resource(:mutating_webhook_config_istio_networking_internal_knative_dev, battery, _state) do
    :mutating_webhook_config
    |> B.build_resource()
    |> B.name("webhook.istio.networking.internal.knative.dev")
    |> B.component_labels("net-istio")
    |> B.label("networking.knative.dev/ingress-provider", "istio")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1", "v1beta1"],
        "clientConfig" => %{"service" => %{"name" => "net-istio-webhook", "namespace" => battery.config.namespace}},
        "failurePolicy" => "Fail",
        "name" => "webhook.istio.networking.internal.knative.dev",
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "serving.knative.dev/configuration", "operator" => "Exists"}
          ]
        },
        "sideEffects" => "None"
      }
    ])
  end
end
