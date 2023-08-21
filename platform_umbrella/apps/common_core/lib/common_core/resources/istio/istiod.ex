defmodule CommonCore.Resources.Istiod do
  @moduledoc false
  use CommonCore.IncludeResource,
    config: "priv/raw_files/istiod/config",
    mesh: "priv/raw_files/istiod/mesh",
    values: "priv/raw_files/istiod/values"

  use CommonCore.Resources.ResourceGenerator, app_name: "istiod"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  resource(:cluster_role_binding_clusterrole_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istiod-clusterrole-battery-istio")
    |> B.role_ref(B.build_cluster_role_ref("istiod-clusterrole-battery-istio"))
    |> B.subject(B.build_service_account("istiod", namespace))
  end

  resource(:cluster_role_binding_gateway_controller_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istiod-gateway-controller-battery-istio")
    |> B.role_ref(B.build_cluster_role_ref("istiod-gateway-controller-battery-istio"))
    |> B.subject(B.build_service_account("istiod", namespace))
  end

  resource(:cluster_role_binding_istio_reader_clusterrole_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istio-reader-clusterrole-battery-istio")
    |> B.component_label("istio-reader")
    |> B.role_ref(B.build_cluster_role_ref("istio-reader-clusterrole-battery-istio"))
    |> B.subject(B.build_service_account("istio-reader-service-account", namespace))
  end

  resource(:cluster_role_clusterrole_battery_istio) do
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
        "resources" => ["workloadentries/status"],
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
        "apiGroups" => ["networking.x-k8s.io", "gateway.networking.k8s.io"],
        "resources" => ["*"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["networking.x-k8s.io", "gateway.networking.k8s.io"],
        "resources" => ["*"],
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
    |> B.name("istiod-clusterrole-battery-istio")
    |> B.rules(rules)
  end

  resource(:cluster_role_gateway_controller_battery_istio) do
    rules = [
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments"],
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
    |> B.name("istiod-gateway-controller-battery-istio")
    |> B.rules(rules)
  end

  resource(:cluster_role_istio_reader_clusterrole_battery_istio) do
    rules = [
      %{
        "apiGroups" => [
          "config.istio.io",
          "security.istio.io",
          "networking.istio.io",
          "authentication.istio.io",
          "rbac.istio.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "endpoints",
          "pods",
          "services",
          "nodes",
          "replicationcontrollers",
          "namespaces",
          "secrets"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceexports"],
        "verbs" => ["get", "list", "watch", "create", "delete"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceimports"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["replicasets"],
        "verbs" => ["get", "list", "watch"]
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
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("istio-reader-clusterrole-battery-istio")
    |> B.component_label("istio-reader")
    |> B.rules(rules)
  end

  resource(:config_map_istio, _battery, state) do
    namespace = istio_namespace(state)
    data = %{} |> Map.put("meshNetworks", "networks: {}") |> Map.put("mesh", get_resource(:mesh))

    :config_map
    |> B.build_resource()
    |> B.name("istio")
    |> B.namespace(namespace)
    |> B.label("install.operator.istio.io/owning-resource", "unknown")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.data(data)
  end

  resource(:config_map_istio_sidecar_injector, _battery, state) do
    namespace = istio_namespace(state)

    data =
      %{} |> Map.put("config", get_resource(:config)) |> Map.put("values", get_resource(:values))

    :config_map
    |> B.build_resource()
    |> B.name("istio-sidecar-injector")
    |> B.namespace(namespace)
    |> B.label("install.operator.istio.io/owning-resource", "unknown")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.data(data)
  end

  resource(:deployment_main, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"istio" => "pilot"}})
      |> Map.put(
        "strategy",
        %{"rollingUpdate" => %{"maxSurge" => "100%", "maxUnavailable" => "25%"}}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "annotations" => %{
              "ambient.istio.io/redirection" => "disabled",
              "prometheus.io/port" => "15014",
              "prometheus.io/scrape" => "true",
              "sidecar.istio.io/inject" => "false"
            },
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => "Pilot",
              "battery/managed" => "true",
              "install.operator.istio.io/owning-resource" => "unknown",
              "istio" => "pilot",
              "istio.io/rev" => "default",
              "sidecar.istio.io/inject" => "false"
            }
          },
          "spec" => %{
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
                  %{"name" => "JWT_POLICY", "value" => "third-party-jwt"},
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
                      "fieldRef" => %{
                        "apiVersion" => "v1",
                        "fieldPath" => "spec.serviceAccountName"
                      }
                    }
                  },
                  %{"name" => "KUBECONFIG", "value" => "/var/run/secrets/remote/config"},
                  %{"name" => "PILOT_TRACE_SAMPLING", "value" => "1"},
                  %{"name" => "PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_OUTBOUND", "value" => "true"},
                  %{"name" => "PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_INBOUND", "value" => "true"},
                  %{"name" => "ISTIOD_ADDR", "value" => "istiod.battery-istio.svc:15012"},
                  %{"name" => "PILOT_ENABLE_ANALYSIS", "value" => "false"},
                  %{"name" => "CLUSTER_ID", "value" => "Kubernetes"},
                  %{
                    "name" => "GOMEMLIMIT",
                    "valueFrom" => %{"resourceFieldRef" => %{"resource" => "limits.memory"}}
                  }
                ],
                "image" => "docker.io/istio/pilot:1.18.2",
                "name" => "discovery",
                "ports" => [
                  %{"containerPort" => 8080, "protocol" => "TCP"},
                  %{"containerPort" => 15_010, "protocol" => "TCP"},
                  %{"containerPort" => 15_017, "protocol" => "TCP"}
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
                  "runAsGroup" => 1337,
                  "runAsNonRoot" => true,
                  "runAsUser" => 1337
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/var/run/secrets/tokens",
                    "name" => "istio-token",
                    "readOnly" => true
                  },
                  %{"mountPath" => "/var/run/secrets/istio-dns", "name" => "local-certs"},
                  %{"mountPath" => "/etc/cacerts", "name" => "cacerts", "readOnly" => true},
                  %{
                    "mountPath" => "/var/run/secrets/remote",
                    "name" => "istio-kubeconfig",
                    "readOnly" => true
                  },
                  %{
                    "mountPath" => "/var/run/secrets/istiod/tls",
                    "name" => "istio-csr-dns-cert",
                    "readOnly" => true
                  },
                  %{
                    "mountPath" => "/var/run/secrets/istiod/ca",
                    "name" => "istio-csr-ca-configmap",
                    "readOnly" => true
                  }
                ]
              }
            ],
            "securityContext" => %{"fsGroup" => 1337},
            "serviceAccountName" => "istiod",
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
              %{
                "name" => "cacerts",
                "secret" => %{"optional" => true, "secretName" => "cacerts"}
              },
              %{
                "name" => "istio-kubeconfig",
                "secret" => %{"optional" => true, "secretName" => "istio-kubeconfig"}
              },
              %{
                "name" => "istio-csr-dns-cert",
                "secret" => %{"optional" => true, "secretName" => "istiod-tls"}
              },
              %{
                "configMap" => %{
                  "defaultMode" => 420,
                  "name" => "istio-ca-root-cert",
                  "optional" => true
                },
                "name" => "istio-csr-ca-configmap"
              }
            ]
          }
        }
      )

    :deployment
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.label("install.operator.istio.io/owning-resource", "unknown")
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.spec(spec)
  end

  resource(:horizontal_pod_autoscaler_main, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("maxReplicas", 5)
      |> Map.put("metrics", [
        %{
          "resource" => %{
            "name" => "cpu",
            "target" => %{"averageUtilization" => 80, "type" => "Utilization"}
          },
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
    |> B.namespace(namespace)
    |> B.label("install.operator.istio.io/owning-resource", "unknown")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.spec(spec)
  end

  resource(:mutating_webhook_config_istio_sidecar_injector_battery_istio) do
    :mutating_webhook_config
    |> B.build_resource()
    |> B.name("istio-sidecar-injector-battery-istio")
    |> B.component_label("sidecar-injector")
    |> B.label("install.operator.istio.io/owning-resource", "unknown")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "istiod",
            "namespace" => "battery-istio",
            "path" => "/inject",
            "port" => 443
          }
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
          "matchExpressions" => [
            %{"key" => "sidecar.istio.io/inject", "operator" => "NotIn", "values" => ["false"]}
          ]
        },
        "rules" => [
          %{
            "apiGroups" => [""],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE"],
            "resources" => ["pods"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "istiod",
            "namespace" => "battery-istio",
            "path" => "/inject",
            "port" => 443
          }
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
        "rules" => [
          %{
            "apiGroups" => [""],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE"],
            "resources" => ["pods"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "istiod",
            "namespace" => "battery-istio",
            "path" => "/inject",
            "port" => 443
          }
        },
        "failurePolicy" => "Fail",
        "name" => "namespace.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "istio-injection", "operator" => "In", "values" => ["enabled"]}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "sidecar.istio.io/inject", "operator" => "NotIn", "values" => ["false"]}
          ]
        },
        "rules" => [
          %{
            "apiGroups" => [""],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE"],
            "resources" => ["pods"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "istiod",
            "namespace" => "battery-istio",
            "path" => "/inject",
            "port" => 443
          }
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
        "rules" => [
          %{
            "apiGroups" => [""],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE"],
            "resources" => ["pods"]
          }
        ],
        "sideEffects" => "None"
      }
    ])
  end

  resource(:pod_disruption_budget_main, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("minAvailable", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "istio" => "pilot"}})

    :pod_disruption_budget
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.label("install.operator.istio.io/owning-resource", "unknown")
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.spec(spec)
  end

  resource(:role_binding_main, _battery, state) do
    namespace = istio_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("istiod"))
    |> B.subject(B.build_service_account("istiod", namespace))
  end

  resource(:role_main, _battery, state) do
    namespace = istio_namespace(state)

    rules = [
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["gateways"],
        "verbs" => ["create"]
      },
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
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:service_account_main, _battery, state) do
    namespace = istio_namespace(state)
    :service_account |> B.build_resource() |> B.name("istiod") |> B.namespace(namespace)
  end

  resource(:service_main, _battery, state) do
    namespace = istio_namespace(state)

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
    |> B.namespace(namespace)
    |> B.label("install.operator.istio.io/owning-resource", "unknown")
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.spec(spec)
  end
end
