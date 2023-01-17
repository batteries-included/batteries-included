defmodule KubeResources.KnativeOperator do
  use CommonCore.IncludeResource,
    knativeeventings_operator_knative_dev:
      "priv/manifests/knative_operator/knativeeventings_operator_knative_dev.yaml",
    knativeservings_operator_knative_dev:
      "priv/manifests/knative_operator/knativeservings_operator_knative_dev.yaml"

  use KubeExt.ResourceGenerator, app_name: "knative-operator"

  import CommonCore.Yaml
  import CommonCore.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.Secret

  @webhook_service "knative-operator-webhook"

  resource(:cluster_role_binding_knative_eventing_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("knative-eventing-operator")
    |> B.role_ref(B.build_cluster_role_ref("knative-eventing-operator"))
    |> B.subject(B.build_service_account("knative-operator", namespace))
  end

  resource(:cluster_role_binding_knative_eventing_operator_aggregated, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("knative-eventing-operator-aggregated")
    |> B.role_ref(B.build_cluster_role_ref("knative-eventing-operator-aggregated"))
    |> B.subject(B.build_service_account("knative-operator", namespace))
  end

  resource(:cluster_role_binding_knative_eventing_operator_aggregated_stable, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("knative-eventing-operator-aggregated-stable")
    |> B.role_ref(B.build_cluster_role_ref("knative-eventing-operator-aggregated-stable"))
    |> B.subject(B.build_service_account("knative-operator", namespace))
  end

  resource(:cluster_role_binding_knative_serving_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("knative-serving-operator")
    |> B.role_ref(B.build_cluster_role_ref("knative-serving-operator"))
    |> B.subject(B.build_service_account("knative-operator", namespace))
  end

  resource(:cluster_role_binding_knative_serving_operator_aggregated, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("knative-serving-operator-aggregated")
    |> B.role_ref(B.build_cluster_role_ref("knative-serving-operator-aggregated"))
    |> B.subject(B.build_service_account("knative-operator", namespace))
  end

  resource(:cluster_role_binding_knative_serving_operator_aggregated_stable, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("knative-serving-operator-aggregated-stable")
    |> B.role_ref(B.build_cluster_role_ref("knative-serving-operator-aggregated-stable"))
    |> B.subject(B.build_service_account("knative-operator", namespace))
  end

  resource(:cluster_role_binding_knative_operator_webhook, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("knative-operator-webhook")
    |> B.role_ref(B.build_cluster_role_ref("knative-operator-webhook"))
    |> B.subject(B.build_service_account("knative-operator-webhook", namespace))
  end

  resource(:cluster_role_knative_eventing_operator) do
    rules = [
      %{"apiGroups" => ["operator.knative.dev"], "resources" => ["*"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterroles", "roles"],
        "verbs" => ["create", "delete", "escalate", "get", "list", "update"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterrolebindings", "rolebindings"],
        "verbs" => ["create", "delete", "list", "get", "update"]
      },
      %{
        "apiGroups" => ["apiregistration.k8s.io"],
        "resources" => ["apiservices"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["services"],
        "verbs" => ["create", "delete", "get", "list", "watch"]
      },
      %{
        "apiGroups" => ["caching.internal.knative.dev"],
        "resources" => ["images"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces"],
        "verbs" => ["get", "update", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "update", "patch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["create", "delete", "get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments", "daemonsets", "replicasets", "statefulsets"],
        "verbs" => ["create", "delete", "get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apiregistration.k8s.io"],
        "resources" => ["apiservices"],
        "verbs" => ["create", "delete", "get", "list"]
      },
      %{
        "apiGroups" => ["autoscaling"],
        "resources" => ["horizontalpodautoscalers"],
        "verbs" => ["create", "delete", "update", "get", "list"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["jobs"],
        "verbs" => ["create", "delete", "update", "get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resourceNames" => ["knative-eventing-operator"],
        "resources" => ["serviceaccounts"],
        "verbs" => ["delete"]
      },
      %{
        "apiGroups" => ["rabbitmq.com"],
        "resources" => ["rabbitmqclusters"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["rabbitmq.com"],
        "resources" => ["bindings", "queues", "exchanges"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["rabbitmq.com"],
        "resources" => ["bindings/status", "queues/status", "exchanges/status"],
        "verbs" => ["get"]
      },
      %{
        "apiGroups" => ["keda.sh"],
        "resources" => [
          "scaledobjects",
          "scaledobjects/finalizers",
          "scaledobjects/status",
          "triggerauthentications",
          "triggerauthentications/status"
        ],
        "verbs" => ["get", "list", "watch", "update", "create", "delete"]
      },
      %{
        "apiGroups" => ["internal.kafka.eventing.knative.dev"],
        "resources" => [
          "consumers",
          "consumers/status",
          "consumergroups",
          "consumergroups/status"
        ],
        "verbs" => ["create", "get", "list", "watch", "patch", "update", "delete"]
      },
      %{
        "apiGroups" => ["internal.kafka.eventing.knative.dev"],
        "resources" => ["consumers/finalizers", "consumergroups/finalizers"],
        "verbs" => ["update", "delete"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["statefulsets/scale"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterrolebindings"],
        "verbs" => ["watch"]
      },
      %{"apiGroups" => ["*"], "resources" => ["configmaps"], "verbs" => ["delete"]},
      %{
        "apiGroups" => ["*"],
        "resources" => ["configmaps", "services"],
        "verbs" => ["get", "list", "watch", "update", "create", "delete"]
      },
      %{
        "apiGroups" => ["*"],
        "resources" => ["pods"],
        "verbs" => ["list", "update", "get", "watch"]
      },
      %{
        "apiGroups" => ["*"],
        "resources" => ["pods/finalizers"],
        "verbs" => ["get", "list", "create", "update", "delete"]
      },
      %{"apiGroups" => ["*"], "resources" => ["events"], "verbs" => ["patch", "create"]},
      %{
        "apiGroups" => ["*"],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch", "update", "create", "delete"]
      },
      %{"apiGroups" => ["*"], "resources" => ["nodes"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["*"],
        "resources" => ["serviceaccounts"],
        "verbs" => ["get", "list", "watch", "update", "create", "delete"]
      },
      %{
        "apiGroups" => ["*"],
        "resourceNames" => ["kafka-channel-config"],
        "resources" => ["configmaps"],
        "verbs" => ["patch"]
      },
      %{
        "apiGroups" => ["*"],
        "resourceNames" => ["kafka-webhook"],
        "resources" => ["horizontalpodautoscalers"],
        "verbs" => ["delete"]
      },
      %{"apiGroups" => ["*"], "resources" => ["leases"], "verbs" => ["delete"]},
      %{
        "apiGroups" => ["*"],
        "resourceNames" => ["kafka-webhook"],
        "resources" => ["poddisruptionbudgets"],
        "verbs" => ["delete"]
      },
      %{"apiGroups" => ["*"], "resources" => ["services"], "verbs" => ["patch"]},
      %{"apiGroups" => ["apps"], "resources" => ["deployments"], "verbs" => ["deletecollection"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name("knative-eventing-operator")
    |> B.rules(rules)
  end

  resource(:cluster_role_knative_eventing_operator_aggregated) do
    rules = []

    B.build_resource(:cluster_role)
    |> B.aggregation_rule(%{
      "clusterRoleSelectors" => [
        %{
          "matchExpressions" => [
            %{"key" => "eventing.knative.dev/release", "operator" => "Exists"}
          ]
        }
      ]
    })
    |> B.name("knative-eventing-operator-aggregated")
    |> B.rules(rules)
  end

  resource(:cluster_role_knative_eventing_operator_aggregated_stable) do
    rules = []

    B.build_resource(:cluster_role)
    |> B.aggregation_rule(%{
      "clusterRoleSelectors" => [
        %{
          "matchExpressions" => [
            %{
              "key" => "app.kubernetes.io/name",
              "operator" => "In",
              "values" => ["knative-eventing"]
            }
          ]
        }
      ]
    })
    |> B.name("knative-eventing-operator-aggregated-stable")
    |> B.rules(rules)
  end

  resource(:cluster_role_knative_operator_webhook) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces"],
        "verbs" => ["get", "create", "update", "list", "watch", "patch"]
      },
      %{"apiGroups" => [""], "resources" => ["namespaces/finalizers"], "verbs" => ["update"]},
      %{"apiGroups" => ["apps"], "resources" => ["deployments"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments/finalizers"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("knative-operator-webhook")
    |> B.label("eventing.knative.dev/release", "devel")
    |> B.rules(rules)
  end

  resource(:cluster_role_knative_serving_operator) do
    rules = [
      %{"apiGroups" => ["operator.knative.dev"], "resources" => ["*"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resourceNames" => ["system:auth-delegator"],
        "resources" => ["clusterroles"],
        "verbs" => ["bind", "get"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resourceNames" => ["extension-apiserver-authentication-reader"],
        "resources" => ["roles"],
        "verbs" => ["bind", "get"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterroles", "roles"],
        "verbs" => ["create", "delete", "escalate", "get", "list", "update"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterrolebindings", "rolebindings"],
        "verbs" => ["create", "delete", "list", "get", "update"]
      },
      %{
        "apiGroups" => ["apiregistration.k8s.io"],
        "resources" => ["apiservices"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["services"],
        "verbs" => ["create", "delete", "get", "list", "watch"]
      },
      %{
        "apiGroups" => ["caching.internal.knative.dev"],
        "resources" => ["images"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces"],
        "verbs" => ["get", "update", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "update", "patch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["create", "delete", "get", "list", "watch"]
      },
      %{
        "apiGroups" => ["security.istio.io", "apps", "policy"],
        "resources" => [
          "poddisruptionbudgets",
          "peerauthentications",
          "deployments",
          "daemonsets",
          "replicasets",
          "statefulsets"
        ],
        "verbs" => ["create", "delete", "get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => ["apiregistration.k8s.io"],
        "resources" => ["apiservices"],
        "verbs" => ["create", "delete", "get", "list"]
      },
      %{
        "apiGroups" => ["autoscaling"],
        "resources" => ["horizontalpodautoscalers"],
        "verbs" => ["create", "delete", "get", "list"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["*"]},
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => [""],
        "resourceNames" => ["knative-ingressgateway"],
        "resources" => ["services", "deployments", "horizontalpodautoscalers"],
        "verbs" => ["delete"]
      },
      %{
        "apiGroups" => [""],
        "resourceNames" => ["config-controller"],
        "resources" => ["configmaps"],
        "verbs" => ["delete"]
      },
      %{
        "apiGroups" => [""],
        "resourceNames" => ["knative-serving-operator"],
        "resources" => ["serviceaccounts"],
        "verbs" => ["delete"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("knative-serving-operator")
    |> B.rules(rules)
  end

  resource(:cluster_role_knative_serving_operator_aggregated) do
    rules = []

    B.build_resource(:cluster_role)
    |> Map.put(
      "aggregationRule",
      %{
        "clusterRoleSelectors" => [
          %{
            "matchExpressions" => [
              %{"key" => "serving.knative.dev/release", "operator" => "Exists"}
            ]
          }
        ]
      }
    )
    |> B.name("knative-serving-operator-aggregated")
    |> B.rules(rules)
  end

  resource(:cluster_role_knative_serving_operator_aggregated_stable) do
    rules = []

    B.build_resource(:cluster_role)
    |> Map.put(
      "aggregationRule",
      %{
        "clusterRoleSelectors" => [
          %{
            "matchExpressions" => [
              %{
                "key" => "app.kubernetes.io/name",
                "operator" => "In",
                "values" => ["knative-serving"]
              }
            ]
          }
        ]
      }
    )
    |> B.name("knative-serving-operator-aggregated-stable")
    |> B.rules(rules)
  end

  resource(:config_map_logging, _battery, state) do
    namespace = core_namespace(state)
    data = %{}

    B.build_resource(:config_map)
    |> B.name("config-logging")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_observability, _battery, state) do
    namespace = core_namespace(state)
    data = %{}

    B.build_resource(:config_map)
    |> B.name("config-observability")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:crds, _battery, state) do
    namespace = core_namespace(state)

    [:knativeeventings_operator_knative_dev, :knativeservings_operator_knative_dev]
    |> Enum.map(&get_resource/1)
    |> Enum.flat_map(&yaml/1)
    |> Enum.map(fn crd ->
      KubeExt.CrdWebhook.change_conversion(crd, @webhook_service, namespace)
    end)
  end

  resource(:deployment_knative_operator, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "knative-operator"}
      })
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "annotations" => %{"sidecar.istio.io/inject" => "false"},
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => "knative-operator",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "env" => [
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{
                    "name" => "SYSTEM_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{"name" => "METRICS_DOMAIN", "value" => "knative.dev/operator"},
                  %{"name" => "CONFIG_LOGGING_NAME", "value" => "config-logging"},
                  %{"name" => "CONFIG_OBSERVABILITY_NAME", "value" => "config-observability"}
                ],
                "image" => battery.config.operator_image,
                "imagePullPolicy" => "IfNotPresent",
                "name" => "knative-operator",
                "ports" => [%{"containerPort" => 9090, "name" => "metrics"}]
              }
            ],
            "serviceAccountName" => "knative-operator"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("knative-operator")
    |> B.namespace(namespace)
    |> B.component_label("knative-operator")
    |> B.spec(spec)
  end

  resource(:deployment_operator_webhook, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "operator-webhook"}
      })
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "annotations" => %{
              "cluster-autoscaler.kubernetes.io/safe-to-evict" => "false",
              "sidecar.istio.io/inject" => "false"
            },
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => "operator-webhook",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "affinity" => %{
              "podAntiAffinity" => %{
                "preferredDuringSchedulingIgnoredDuringExecution" => [
                  %{
                    "podAffinityTerm" => %{
                      "labelSelector" => %{
                        "matchLabels" => %{
                          "battery/app" => @app_name,
                          "battery/component" => "operator-webhook"
                        }
                      },
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
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{
                    "name" => "SYSTEM_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{"name" => "CONFIG_LOGGING_NAME", "value" => "config-logging"},
                  %{"name" => "CONFIG_OBSERVABILITY_NAME", "value" => "config-observability"},
                  %{"name" => "WEBHOOK_NAME", "value" => "knative-operator-webhook"},
                  %{"name" => "WEBHOOK_PORT", "value" => "8443"},
                  %{"name" => "METRICS_DOMAIN", "value" => "knative.dev/operator"}
                ],
                "image" => battery.config.webhook_image,
                "livenessProbe" => %{
                  "failureThreshold" => 6,
                  "httpGet" => %{
                    "httpHeaders" => [%{"name" => "k-kubelet-probe", "value" => "webhook"}],
                    "port" => 8443,
                    "scheme" => "HTTPS"
                  },
                  "initialDelaySeconds" => 120,
                  "periodSeconds" => 1
                },
                "name" => "operator-webhook",
                "ports" => [
                  %{"containerPort" => 9090, "name" => "metrics"},
                  %{"containerPort" => 8008, "name" => "profiling"},
                  %{"containerPort" => 8443, "name" => "https-webhook"}
                ],
                "readinessProbe" => %{
                  "httpGet" => %{
                    "httpHeaders" => [%{"name" => "k-kubelet-probe", "value" => "webhook"}],
                    "port" => 8443,
                    "scheme" => "HTTPS"
                  },
                  "periodSeconds" => 1
                },
                "resources" => %{
                  "limits" => %{"cpu" => "500m", "memory" => "500Mi"},
                  "requests" => %{"cpu" => "100m", "memory" => "100Mi"}
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["all"]},
                  "readOnlyRootFilesystem" => true,
                  "runAsNonRoot" => true
                }
              }
            ],
            "serviceAccountName" => "knative-operator-webhook",
            "terminationGracePeriodSeconds" => 300
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("knative-operator-webhook")
    |> B.namespace(namespace)
    |> B.component_label("operator-webhook")
    |> B.spec(spec)
  end

  resource(:role_binding_knative_operator_webhook, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("knative-operator-webhook")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("knative-operator-webhook"))
    |> B.subject(B.build_service_account("knative-operator-webhook", namespace))
  end

  resource(:role_knative_operator_webhook, _battery, state) do
    namespace = core_namespace(state)

    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["get", "create", "update", "list", "watch", "patch"]
      }
    ]

    B.build_resource(:role)
    |> B.name("knative-operator-webhook")
    |> B.namespace(namespace)
    |> B.component_label("operator-webhook")
    |> B.rules(rules)
  end

  resource(:secret_operator_webhook_certs, _battery, state) do
    namespace = core_namespace(state)
    data = Secret.encode(%{})

    B.build_resource(:secret)
    |> B.name("operator-webhook-certs")
    |> B.namespace(namespace)
    |> B.component_label("operator-webhook")
    |> B.data(data)
  end

  resource(:service_account_knative_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("knative-operator")
    |> B.namespace(namespace)
  end

  resource(:service_account_knative_operator_webhook, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("knative-operator-webhook")
    |> B.namespace(namespace)
    |> B.component_label("operator-webhook")
  end

  resource(:service_knative_operator_webhook, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 9090, "targetPort" => 9090},
        %{"name" => "http-profiling", "port" => 8008, "targetPort" => 8008},
        %{"name" => "https-webhook", "port" => 443, "targetPort" => 8443}
      ])
      |> Map.put("selector", %{
        "battery/app" => @app_name,
        "battery/component" => "operator-webhook"
      })

    B.build_resource(:service)
    |> B.name(@webhook_service)
    |> B.namespace(namespace)
    |> B.component_label("operator-webhook")
    |> B.label("role", "operator-webhook")
    |> B.spec(spec)
  end
end
