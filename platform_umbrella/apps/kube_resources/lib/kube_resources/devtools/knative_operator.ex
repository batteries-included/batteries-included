defmodule KubeResources.KnativeOperator do
  @moduledoc false
  use KubeExt.IncludeResource, crd: "priv/manifests/knative/operator-crds.yaml"

  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeExt.KubeState.Hosts
  alias KubeResources.DevtoolsSettings

  @app_name "knative-operator"

  def materialize(config) do
    %{
      "/crd" => yaml(get_resource(:crd)),
      "/deployment" => deployment(config),
      "/cluster_role" => cluster_role(config),
      "/cluster_role_1" => cluster_role_1(config),
      "/cluster_role_2" => cluster_role_2(config),
      "/cluster_role_3" => cluster_role_3(config),
      "/cluster_role_binding" => cluster_role_binding(config),
      "/cluster_role_binding_1" => cluster_role_binding_1(config),
      "/cluster_role_binding_2" => cluster_role_binding_2(config),
      "/cluster_role_binding_3" => cluster_role_binding_3(config),
      "/service_account" => service_account(config),
      "/destination_namespace" => dest_namespace(config),
      "/knative_serving/main" => knative_serving(config),
      "/knative_serving/domain_config" => domain_config(config)
    }
  end

  def monitors(config) do
    [
      service_monitor_autoscaler(config),
      service_monitor_activator(config),
      service_monitor_controller(config),
      service_monitor_filter(config),
      service_monitor_webhook(config),
      service_monitor_broker_ingress(config),
      pod_monitor_eventing_controller(config),
      pod_monitor_imc_controller(config),
      pod_monitor_api_source(config),
      pod_monitor_ping_source(config)
    ]
  end

  def service_monitor_autoscaler(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "endpoints" => [
        %{
          "interval" => "30s",
          "port" => "http-metrics"
        }
      ],
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-serving",
          namespace
        ]
      },
      "selector" => %{
        "matchLabels" => %{
          "app" => "autoscaler"
        }
      }
    }

    B.build_resource(:service_monitor)
    |> B.app_labels(@app_name)
    |> B.name("knative-autoscaler")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def service_monitor_activator(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "endpoints" => [
        %{
          "interval" => "30s",
          "port" => "http-metrics"
        }
      ],
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-serving",
          namespace
        ]
      },
      "selector" => %{
        "matchLabels" => %{
          "app" => "activator"
        }
      }
    }

    B.build_resource(:service_monitor)
    |> B.app_labels(@app_name)
    |> B.name("knative-activator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def service_monitor_controller(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "endpoints" => [
        %{
          "interval" => "30s",
          "port" => "http-metrics"
        }
      ],
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-serving",
          namespace
        ]
      },
      "selector" => %{
        "matchLabels" => %{
          "app" => "controller"
        }
      }
    }

    B.build_resource(:service_monitor)
    |> B.app_labels(@app_name)
    |> B.name("knative-controller")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def service_monitor_filter(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "endpoints" => [
        %{
          "interval" => "30s",
          "port" => "http-metrics"
        }
      ],
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-eventing",
          namespace
        ]
      },
      "selector" => %{
        "matchLabels" => %{
          "eventing.knative.dev/brokerRole" => "filter"
        }
      }
    }

    B.build_resource(:service_monitor)
    |> B.app_labels(@app_name)
    |> B.name("knative-filter")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def service_monitor_webhook(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "endpoints" => [
        %{
          "interval" => "30s",
          "port" => "http-metrics"
        }
      ],
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-serving",
          namespace
        ]
      },
      "selector" => %{
        "matchLabels" => %{
          "app" => "activator"
        }
      }
    }

    B.build_resource(:service_monitor)
    |> B.app_labels(@app_name)
    |> B.name("knative-webhook")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def service_monitor_broker_ingress(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "endpoints" => [
        %{
          "interval" => "30s",
          "port" => "http-metrics"
        }
      ],
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-eventing",
          namespace
        ]
      },
      "selector" => %{
        "matchLabels" => %{
          "eventing.knative.dev/brokerRole" => "ingress"
        }
      }
    }

    B.build_resource(:service_monitor)
    |> B.app_labels(@app_name)
    |> B.name("knative-broker-ingress")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def pod_monitor_eventing_controller(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-eventing",
          namespace
        ]
      },
      "podMetricsEndpoints" => [
        %{
          "port" => "metrics"
        }
      ],
      "selector" => %{
        "matchLabels" => %{
          "app" => "eventing-controller"
        }
      }
    }

    B.build_resource(:pod_monitor)
    |> B.name("knative-eventing-contoller")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def pod_monitor_imc_controller(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-eventing",
          namespace
        ]
      },
      "podMetricsEndpoints" => [
        %{
          "port" => "metrics"
        }
      ],
      "selector" => %{
        "matchLabels" => %{
          "messaging.knative.dev/role" => "controller"
        }
      }
    }

    B.build_resource(:pod_monitor)
    |> B.name("knative-imc-contoller")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def pod_monitor_ping_source(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "namespaceSelector" => %{
        "matchNames" => [
          "knative-eventing",
          namespace
        ]
      },
      "podMetricsEndpoints" => [
        %{
          "port" => "metrics"
        }
      ],
      "selector" => %{
        "matchLabels" => %{
          "eventing.knative.dev/source" => "ping-source-controller"
        }
      }
    }

    B.build_resource(:pod_monitor)
    |> B.name("knative-ping-source")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def pod_monitor_api_source(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "namespaceSelector" => %{
        "any" => true
      },
      "podMetricsEndpoints" => [
        %{
          "port" => "metrics"
        }
      ],
      "selector" => %{
        "matchLabels" => %{
          "eventing.knative.dev/source" => "apiserver-source-controller"
        }
      }
    }

    B.build_resource(:pod_monitor)
    |> B.name("knative-ping-source")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def deployment(config) do
    namespace = DevtoolsSettings.namespace(config)
    knative_operator_image = DevtoolsSettings.knative_operator_image(config)
    knative_operator_version = DevtoolsSettings.knative_operator_version(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => "knative-operator",
        "namespace" => namespace,
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{"name" => "knative-operator", "battery/managed" => "true"}
        },
        "template" => %{
          "metadata" => %{
            "annotations" => %{"sidecar.istio.io/inject" => "false"},
            "labels" => %{
              "name" => "knative-operator",
              "battery/app" => @app_name,
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "serviceAccountName" => "knative-operator",
            "containers" => [
              %{
                "name" => "knative-operator",
                "image" => "#{knative_operator_image}:#{knative_operator_version}",
                "imagePullPolicy" => "IfNotPresent",
                "env" => [
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{
                    "name" => "SYSTEM_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{"name" => "METRICS_DOMAIN", "value" => "knative.dev/operator"}
                ],
                "ports" => [%{"name" => "metrics", "containerPort" => 9090}]
              }
            ]
          }
        }
      }
    }
  end

  def cluster_role(_config) do
    B.build_resource(:cluster_role)
    |> B.app_labels(@app_name)
    |> B.name("knative-serving-operator-aggregated")
    |> Map.put("rules", [])
    |> Map.put("aggregationRule", %{
      "clusterRoleSelectors" => [
        %{
          "matchExpressions" => [
            %{"key" => "serving.knative.dev/release", "operator" => "Exists"}
          ]
        }
      ]
    })
  end

  def cluster_role_1(_config) do
    %{
      "kind" => "ClusterRole",
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "metadata" => %{
        "name" => "knative-serving-operator",
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "rules" => [
        %{"apiGroups" => ["operator.knative.dev"], "resources" => ["*"], "verbs" => ["*"]},
        %{
          "apiGroups" => ["rbac.authorization.k8s.io"],
          "resources" => ["clusterroles"],
          "resourceNames" => ["system:auth-delegator"],
          "verbs" => ["bind", "get"]
        },
        %{
          "apiGroups" => ["rbac.authorization.k8s.io"],
          "resources" => ["roles"],
          "resourceNames" => ["extension-apiserver-authentication-reader"],
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
        %{
          "apiGroups" => [""],
          "resources" => ["events"],
          "verbs" => ["create", "update", "patch"]
        },
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
          "resources" => ["services", "deployments", "horizontalpodautoscalers"],
          "resourceNames" => ["knative-ingressgateway"],
          "verbs" => ["delete"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "resourceNames" => ["config-controller"],
          "verbs" => ["delete"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["serviceaccounts"],
          "resourceNames" => ["knative-serving-operator"],
          "verbs" => ["delete"]
        }
      ]
    }
  end

  def cluster_role_2(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "knative-eventing-operator-aggregated",
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "aggregationRule" => %{
        "clusterRoleSelectors" => [
          %{
            "matchExpressions" => [
              %{"key" => "eventing.knative.dev/release", "operator" => "Exists"}
            ]
          }
        ]
      },
      "rules" => []
    }
  end

  def cluster_role_3(_config) do
    %{
      "kind" => "ClusterRole",
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "metadata" => %{
        "name" => "knative-eventing-operator",
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "rules" => [
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
        %{
          "apiGroups" => [""],
          "resources" => ["events"],
          "verbs" => ["create", "update", "patch"]
        },
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
          "resources" => ["serviceaccounts"],
          "resourceNames" => ["knative-eventing-operator"],
          "verbs" => ["delete"]
        }
      ]
    }
  end

  def cluster_role_binding(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "knative-serving-operator",
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "knative-serving-operator"
      },
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "knative-operator", "namespace" => namespace}
      ]
    }
  end

  def cluster_role_binding_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "knative-serving-operator-aggregated",
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "knative-serving-operator-aggregated"
      },
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "knative-operator", "namespace" => namespace}
      ]
    }
  end

  def cluster_role_binding_2(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "knative-eventing-operator",
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "knative-eventing-operator"
      },
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "knative-operator", "namespace" => namespace}
      ]
    }
  end

  def cluster_role_binding_3(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "knative-eventing-operator-aggregated",
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "knative-eventing-operator-aggregated"
      },
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "knative-operator", "namespace" => namespace}
      ]
    }
  end

  def service_account(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.namespace(namespace)
    |> B.name("knative-operator")
    |> B.app_labels(@app_name)
  end

  def dest_namespace(config) do
    knative_dest_namespace = DevtoolsSettings.knative_destination_namespace(config)

    B.build_resource(:namespace)
    |> B.name(knative_dest_namespace)
    |> B.app_labels(@app_name)
    |> B.label("istio-injection", "enabled")
  end

  def knative_serving(config) do
    knative_dest_namespace = DevtoolsSettings.knative_destination_namespace(config)

    B.build_resource(:knative_serving)
    |> B.namespace(knative_dest_namespace)
    |> B.app_labels(@app_name)
    |> B.name("knative-serving")
    |> B.spec(serving_spec(config))
  end

  defp serving_spec(_config) do
    %{}
    |> Map.put("config", %{
      "istio" => %{
        "gateway.battery-knative.knative-ingress-gateway" =>
          "ingressgateway.battery-istio.svc.cluster.local",
        "local-gateway.battery-knative.knative-local-gateway" =>
          "knative-local-gateway.battery-istio.svc.cluster.local"
      }
    })
    |> Map.put("ingress", %{"istio" => %{"enabled" => true}})
  end

  defp domain_config(config) do
    namespace = DevtoolsSettings.knative_destination_namespace(config)

    data = Map.put(%{}, Hosts.knative(), "")

    B.build_resource(:config_map)
    |> B.name("config-domain")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> Map.put("data", data)
  end
end
