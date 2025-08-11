defmodule CommonCore.Resources.Istio.Istiod do
  @moduledoc false
  use CommonCore.IncludeResource,
    config: "priv/raw_files/istio/config",
    values: "priv/raw_files/istio/values"

  use CommonCore.Resources.ResourceGenerator, app_name: "istiod"

  alias CommonCore.Defaults.Image
  alias CommonCore.Resources.Builder, as: B

  resource(:cluster_role_binding_istiod_clusterrole, battery, _state) do
    namespace = battery.config.namespace

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istiod-clusterrole-#{namespace}")
    |> B.role_ref(B.build_cluster_role_ref("istiod-clusterrole-#{namespace}"))
    |> B.subject(B.build_service_account("istiod", namespace))
  end

  resource(:cluster_role_binding_istiod_gateway_controller, battery, _state) do
    namespace = battery.config.namespace

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istiod-gateway-controller-#{namespace}")
    |> B.role_ref(B.build_cluster_role_ref("istiod-gateway-controller-#{namespace}"))
    |> B.subject(B.build_service_account("istiod", namespace))
  end

  resource(:cluster_role_istiod_clusterrole, battery, _state) do
    rules = [
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["mutatingwebhookconfigurations"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations"],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => [
          "config.istio.io",
          "security.istio.io",
          "networking.istio.io",
          "authentication.istio.io",
          "rbac.istio.io",
          "telemetry.istio.io",
          "extensions.istio.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries/status", "serviceentries/status"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["security.istio.io"],
        "resources" => ["authorizationpolicies/status"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["services/status"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["pods", "nodes", "services", "namespaces", "endpoints"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses", "ingressclasses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses/status"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["create", "get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => ["authorization.k8s.io"],
        "resources" => ["subjectaccessreviews"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io", "gateway.networking.x-k8s.io"],
        "resources" => ["*"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["gateway.networking.x-k8s.io"],
        "resources" => ["xbackendtrafficpolicies/status"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => [
          "backendtlspolicies/status",
          "gatewayclasses/status",
          "gateways/status",
          "grpcroutes/status",
          "httproutes/status",
          "referencegrants/status",
          "tcproutes/status",
          "tlsroutes/status",
          "udproutes/status"
        ],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => ["gatewayclasses"],
        "verbs" => ["create", "update", "patch", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "watch", "list"]},
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceexports"],
        "verbs" => ["get", "watch", "list", "create", "delete"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceimports"],
        "verbs" => ["get", "watch", "list"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("istiod-clusterrole-#{battery.config.namespace}")
    |> B.rules(rules)
  end

  resource(:cluster_role_istiod_gateway_controller, battery, _state) do
    rules = [
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["autoscaling"],
        "resources" => ["horizontalpodautoscalers"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["policy"],
        "resources" => ["poddisruptionbudgets"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["services"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["serviceaccounts"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("istiod-gateway-controller-#{battery.config.namespace}")
    |> B.rules(rules)
  end

  resource(:config_map_istio_sidecar_injector, battery, state) do
    data = %{"values" => values(battery, state), "config" => config(battery, state)}

    :config_map
    |> B.build_resource()
    |> B.name("istio-sidecar-injector")
    |> B.namespace(battery.config.namespace)
    |> B.label("istio.io/rev", "default")
    |> B.data(data)
  end

  resource(:deployment_istiod, battery, _state) do
    namespace = battery.config.namespace

    template =
      %{}
      |> Map.put("metadata", %{
        "annotations" => %{
          "prometheus.io/port" => "15014",
          "prometheus.io/scrape" => "true",
          "sidecar.istio.io/inject" => "false"
        },
        "labels" => %{
          "istio.io/dataplane-mode" => "none",
          "istio.io/rev" => "default",
          "sidecar.istio.io/inject" => "false"
        }
      })
      |> B.spec(%{
        "containers" => [
          %{
            "args" => [
              "discovery",
              "--monitoringAddr=:15014",
              "--log_output_level=default:info",
              "--domain",
              "cluster.local",
              "--keepaliveMaxServerConnectionAge",
              "30m"
            ],
            "env" => [
              %{"name" => "REVISION", "value" => "default"},
              %{"name" => "PILOT_CERT_PROVIDER", "value" => "istiod"},
              %{
                "name" => "POD_NAME",
                "valueFrom" => %{
                  "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.name"}
                }
              },
              %{
                "name" => "POD_NAMESPACE",
                "valueFrom" => %{
                  "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.namespace"}
                }
              },
              %{
                "name" => "SERVICE_ACCOUNT",
                "valueFrom" => %{
                  "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "spec.serviceAccountName"}
                }
              },
              %{"name" => "KUBECONFIG", "value" => "/var/run/secrets/remote/config"},
              %{"name" => "CA_TRUSTED_NODE_ACCOUNTS", "value" => "#{battery.config.namespace}/ztunnel"},
              %{"name" => "PILOT_ENABLE_AMBIENT", "value" => "true"},
              %{"name" => "PILOT_ENABLE_ALPHA_GATEWAY_API", "value" => "true"},
              %{"name" => "PILOT_TRACE_SAMPLING", "value" => "1"},
              %{"name" => "PILOT_ENABLE_ANALYSIS", "value" => "false"},
              %{"name" => "CLUSTER_ID", "value" => "Kubernetes"},
              %{
                "name" => "GOMEMLIMIT",
                "valueFrom" => %{
                  "resourceFieldRef" => %{"divisor" => "1", "resource" => "limits.memory"}
                }
              },
              %{
                "name" => "GOMAXPROCS",
                "valueFrom" => %{
                  "resourceFieldRef" => %{"divisor" => "1", "resource" => "limits.cpu"}
                }
              },
              %{"name" => "PLATFORM", "value" => ""}
            ],
            "image" => battery.config.pilot_image,
            "name" => "discovery",
            "ports" => [
              %{"containerPort" => 8080, "name" => "http-debug", "protocol" => "TCP"},
              %{"containerPort" => 15_010, "name" => "grpc-xds", "protocol" => "TCP"},
              %{"containerPort" => 15_012, "name" => "tls-xds", "protocol" => "TCP"},
              %{"containerPort" => 15_017, "name" => "https-webhooks", "protocol" => "TCP"},
              %{"containerPort" => 15_014, "name" => "http-monitoring", "protocol" => "TCP"}
            ],
            "readinessProbe" => %{
              "httpGet" => %{"path" => "/ready", "port" => 8080},
              "initialDelaySeconds" => 1,
              "periodSeconds" => 3,
              "timeoutSeconds" => 5
            },
            "resources" => %{"requests" => %{"cpu" => "500m", "memory" => "2048Mi"}},
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true
            },
            "volumeMounts" => [
              %{"mountPath" => "/var/run/secrets/tokens", "name" => "istio-token", "readOnly" => true},
              %{"mountPath" => "/var/run/secrets/istio-dns", "name" => "local-certs"},
              %{"mountPath" => "/etc/cacerts", "name" => "cacerts", "readOnly" => true},
              %{"mountPath" => "/var/run/secrets/remote", "name" => "istio-kubeconfig", "readOnly" => true},
              %{"mountPath" => "/var/run/secrets/istiod/tls", "name" => "istio-csr-dns-cert", "readOnly" => true},
              %{"mountPath" => "/var/run/secrets/istiod/ca", "name" => "istio-csr-ca-configmap", "readOnly" => true}
            ]
          }
        ],
        "serviceAccountName" => "istiod",
        "tolerations" => [
          %{"key" => "cni.istio.io/not-ready", "operator" => "Exists"},
          %{"key" => "CriticalAddonsOnly", "operator" => "Exists"}
        ],
        "volumes" => [
          %{"emptyDir" => %{"medium" => "Memory"}, "name" => "local-certs"},
          %{
            "name" => "istio-token",
            "projected" => %{
              "sources" => [
                %{
                  "serviceAccountToken" => %{
                    "audience" => "istio-ca",
                    "expirationSeconds" => 43_200,
                    "path" => "istio-token"
                  }
                }
              ]
            }
          },
          %{"name" => "cacerts", "secret" => %{"optional" => true, "secretName" => "cacerts"}},
          %{"name" => "istio-kubeconfig", "secret" => %{"optional" => true, "secretName" => "istio-kubeconfig"}},
          %{"name" => "istio-csr-dns-cert", "secret" => %{"optional" => true, "secretName" => "istiod-tls"}},
          %{
            "configMap" => %{"defaultMode" => 420, "name" => "istio-ca-root-cert", "optional" => true},
            "name" => "istio-csr-ca-configmap"
          }
        ]
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.label("istio", "pilot")

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"istio" => "pilot"}})
      |> Map.put("strategy", %{"rollingUpdate" => %{"maxSurge" => "100%", "maxUnavailable" => "25%"}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  resource(:horizontal_pod_autoscaler_istiod, battery, _state) do
    spec =
      %{}
      |> Map.put("maxReplicas", 5)
      |> Map.put("metrics", [
        %{
          "resource" => %{"name" => "cpu", "target" => %{"averageUtilization" => 80, "type" => "Utilization"}},
          "type" => "Resource"
        }
      ])
      |> Map.put("minReplicas", 1)
      |> Map.put(
        "scaleTargetRef",
        %{"apiVersion" => "apps/v1", "kind" => "Deployment", "name" => "istiod"}
      )

    :horizontal_pod_autoscaler
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(battery.config.namespace)
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  resource(:mutating_webhook_config_sidecar_injector, battery, _state) do
    webhooks = [
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{"name" => "istiod", "namespace" => battery.config.namespace, "path" => "/inject", "port" => 443}
        },
        "failurePolicy" => "Fail",
        "name" => "rev.namespace.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "istio.io/rev", "operator" => "In", "values" => ["default"]},
            %{"key" => "istio-injection", "operator" => "DoesNotExist"}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [%{"key" => "sidecar.istio.io/inject", "operator" => "NotIn", "values" => ["false"]}]
        },
        "reinvocationPolicy" => "Never",
        "rules" => [%{"apiGroups" => [""], "apiVersions" => ["v1"], "operations" => ["CREATE"], "resources" => ["pods"]}],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{"name" => "istiod", "namespace" => battery.config.namespace, "path" => "/inject", "port" => 443}
        },
        "failurePolicy" => "Fail",
        "name" => "rev.object.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "istio.io/rev", "operator" => "DoesNotExist"},
            %{"key" => "istio-injection", "operator" => "DoesNotExist"}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "sidecar.istio.io/inject", "operator" => "NotIn", "values" => ["false"]},
            %{"key" => "istio.io/rev", "operator" => "In", "values" => ["default"]}
          ]
        },
        "reinvocationPolicy" => "Never",
        "rules" => [%{"apiGroups" => [""], "apiVersions" => ["v1"], "operations" => ["CREATE"], "resources" => ["pods"]}],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{"name" => "istiod", "namespace" => battery.config.namespace, "path" => "/inject", "port" => 443}
        },
        "failurePolicy" => "Fail",
        "name" => "namespace.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [%{"key" => "istio-injection", "operator" => "In", "values" => ["enabled"]}]
        },
        "objectSelector" => %{
          "matchExpressions" => [%{"key" => "sidecar.istio.io/inject", "operator" => "NotIn", "values" => ["false"]}]
        },
        "reinvocationPolicy" => "Never",
        "rules" => [%{"apiGroups" => [""], "apiVersions" => ["v1"], "operations" => ["CREATE"], "resources" => ["pods"]}],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{"name" => "istiod", "namespace" => battery.config.namespace, "path" => "/inject", "port" => 443}
        },
        "failurePolicy" => "Fail",
        "name" => "object.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "istio-injection", "operator" => "DoesNotExist"},
            %{"key" => "istio.io/rev", "operator" => "DoesNotExist"}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "sidecar.istio.io/inject", "operator" => "In", "values" => ["true"]},
            %{"key" => "istio.io/rev", "operator" => "DoesNotExist"}
          ]
        },
        "reinvocationPolicy" => "Never",
        "rules" => [%{"apiGroups" => [""], "apiVersions" => ["v1"], "operations" => ["CREATE"], "resources" => ["pods"]}],
        "sideEffects" => "None"
      }
    ]

    :mutating_webhook_config
    |> B.build_resource()
    |> B.name("istio-sidecar-injector-#{battery.config.namespace}")
    |> B.label("istio.io/rev", "default")
    |> Map.put("webhooks", webhooks)
  end

  resource(:pod_disruption_budget_istiod, battery, _state) do
    spec =
      %{}
      |> Map.put("minAvailable", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "istio" => "pilot"}})

    :pod_disruption_budget
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(battery.config.namespace)
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  resource(:role_binding_istiod, battery, _state) do
    :role_binding
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(battery.config.namespace)
    |> B.role_ref(B.build_role_ref("istiod"))
    |> B.subject(B.build_service_account("istiod", battery.config.namespace))
  end

  resource(:role_istiod, battery, _state) do
    rules = [
      %{"apiGroups" => ["networking.istio.io"], "resources" => ["gateways"], "verbs" => ["create"]},
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["create", "get", "watch", "list", "update", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["delete"]},
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "update", "patch", "create"]
      }
    ]

    :role
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(battery.config.namespace)
    |> B.rules(rules)
  end

  resource(:service_account_istiod, battery, _state) do
    :service_account
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(battery.config.namespace)
  end

  resource(:service_istiod, battery, _state) do
    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "grpc-xds", "port" => 15_010, "protocol" => "TCP"},
        %{"name" => "https-dns", "port" => 15_012, "protocol" => "TCP"},
        %{"name" => "https-webhook", "port" => 443, "protocol" => "TCP", "targetPort" => 15_017},
        %{"name" => "http-monitoring", "port" => 15_014, "protocol" => "TCP"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "istio" => "pilot"})

    :service
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(battery.config.namespace)
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  resource(:validating_webhook_config_validator_battery, battery, _state) do
    webhooks = [
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{"name" => "istiod", "namespace" => battery.config.namespace, "path" => "/validate"}
        },
        "failurePolicy" => "Ignore",
        "name" => "rev.validation.istio.io",
        "objectSelector" => %{
          "matchExpressions" => [%{"key" => "istio.io/rev", "operator" => "In", "values" => ["default"]}]
        },
        "rules" => [
          %{
            "apiGroups" => ["security.istio.io", "networking.istio.io", "telemetry.istio.io", "extensions.istio.io"],
            "apiVersions" => ["*"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["*"]
          }
        ],
        "sideEffects" => "None"
      }
    ]

    :validating_webhook_config
    |> B.build_resource()
    |> B.name("istio-validator-#{battery.config.namespace}")
    |> B.label("istio", "istiod")
    |> B.label("istio.io/rev", "default")
    |> Map.put("webhooks", webhooks)
  end

  # There's a pretty static json config full of values
  #
  # That json needs just a little updating.
  defp values(battery, _state) do
    namespace = battery.config.namespace
    proxy_img = CommonCore.Defaults.Images.get_image!(:istio_proxy)

    :values
    |> get_resource()
    |> Jason.decode!()
    # The whole value is wrapped in a "global"
    # update that here
    |> update_in(~w(global), fn val ->
      # The namespace is where the config is installed
      # and the tag is the default tag for this Batteries Included version
      val
      |> Map.put("namespace", namespace)
      |> Map.put("istioNamespace", namespace)
      |> Map.put("tag", proxy_img.default_tag)
      |> Map.put("logAsJson", true)
      |> put_in(~w(proxy image), Image.default_image(proxy_img))
      |> put_in(~w(proxy_init image), Image.default_image(proxy_img))
    end)
    |> Jason.encode!()
  end

  defp config(_battery, _state), do: get_resource(:config)
end
