defmodule KubeResources.KnativeOperator do
  @moduledoc false

  use KubeExt.IncludeResource, crd: "priv/manifests/knative/operator-crds.yaml"

  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeResources.DevtoolsSettings

  @app_name "knative-operator"

  @aggregated_serving_cluster_role "battery-knative-aggregated-serving"
  @aggregated_serving_appname_cluster_role "battery-knative-aggregated-appname-serving"
  @aggregated_serving_battery_app_cluster_role "battery-knative-aggregated-battery-app-serving"

  @aggregated_eventing_cluster_role "battery-knative-aggregated-eventing"
  @aggregated_eventing_appname_cluster_role "battery-knative-aggregated-appname-eventing"
  @aggregated_eventing_battery_app_cluster_role "battery-knative-aggregated-battery-app-eventing"

  @serving_operator_cluster_role "battery-knative-serving"
  @eventing_operator_cluster_role "battery-knative-eventing"

  @webhook_cluster_role "battery-knative-webhook"

  @webhook_role "knative-operator-webhook"

  @operator_service_account "knative-operator"
  @webhook_service_account "knative-operator-webhook"

  @webhook_certs_secret "operator-webhook-certs"

  @logging_configmap "knative-config-logging"
  @observability_configmap "knative-config-observability"

  @webhook_service "knative-operator-webhook"

  defp aggregated_cluster_role(name, key) do
    B.build_resource(:cluster_role)
    |> B.app_labels(@app_name)
    |> B.name(name)
    |> B.rules([])
    |> Map.put("aggregationRule", %{
      "clusterRoleSelectors" => [
        %{
          "matchExpressions" => [
            %{"key" => key, "operator" => "Exists"}
          ]
        }
      ]
    })
  end

  defp aggregated_cluster_role(name, key, values) do
    B.build_resource(:cluster_role)
    |> B.app_labels(@app_name)
    |> B.name(name)
    |> B.rules([])
    |> Map.put("aggregationRule", %{
      "clusterRoleSelectors" => [
        %{
          "matchExpressions" => [
            %{
              "key" => key,
              "operator" => "In",
              "values" => values
            }
          ]
        }
      ]
    })
  end

  defp cluster_role_binding(name, cluster_role_name, service_account, namespace) do
    B.build_resource(:cluster_role_binding)
    |> B.name(name)
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref(cluster_role_name))
    |> B.subject(B.build_service_account(service_account, namespace))
  end

  def aggregated_cluster_role_serving(_config),
    do: aggregated_cluster_role(@aggregated_serving_cluster_role, "serving.knative.dev/release")

  def aggregated_cluster_role_serving_appname(_config),
    do:
      aggregated_cluster_role(
        @aggregated_serving_appname_cluster_role,
        "app.kubernetes.io/name",
        ["knative-serving"]
      )

  def aggregated_cluster_role_serving_battery_app(_config),
    do:
      aggregated_cluster_role(
        @aggregated_serving_battery_app_cluster_role,
        "battery/app",
        ["knative-serving", @app_name]
      )

  def aggregated_cluster_role_eventing(_config),
    do:
      aggregated_cluster_role(
        @aggregated_eventing_cluster_role,
        "eventing.knative.dev/release"
      )

  def aggregated_cluster_role_eventing_appname(_config),
    do:
      aggregated_cluster_role(
        @aggregated_eventing_appname_cluster_role,
        "app.kubernetes.io/name",
        ["knative-eventing"]
      )

  def aggregated_cluster_role_eventing_battery_app(_config),
    do:
      aggregated_cluster_role(
        @aggregated_eventing_battery_app_cluster_role,
        "battery/app",
        ["knative-eventing", @app_name]
      )

  def cluster_role_knative_serving_operator(_config) do
    rules = [
      %{
        "apiGroups" => [
          "operator.knative.dev"
        ],
        "resources" => [
          "*"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "rbac.authorization.k8s.io"
        ],
        "resourceNames" => [
          "system:auth-delegator"
        ],
        "resources" => [
          "clusterroles"
        ],
        "verbs" => [
          "bind",
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "rbac.authorization.k8s.io"
        ],
        "resourceNames" => [
          "extension-apiserver-authentication-reader"
        ],
        "resources" => [
          "roles"
        ],
        "verbs" => [
          "bind",
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "rbac.authorization.k8s.io"
        ],
        "resources" => [
          "clusterroles",
          "roles"
        ],
        "verbs" => [
          "create",
          "delete",
          "escalate",
          "get",
          "list",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "rbac.authorization.k8s.io"
        ],
        "resources" => [
          "clusterrolebindings",
          "rolebindings"
        ],
        "verbs" => [
          "create",
          "delete",
          "list",
          "get",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "apiregistration.k8s.io"
        ],
        "resources" => [
          "apiservices"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "services"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "caching.internal.knative.dev"
        ],
        "resources" => [
          "images"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "namespaces"
        ],
        "verbs" => [
          "get",
          "update",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "security.istio.io",
          "apps",
          "policy"
        ],
        "resources" => [
          "poddisruptionbudgets",
          "peerauthentications",
          "deployments",
          "daemonsets",
          "replicasets",
          "statefulsets"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list",
          "watch",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "apiregistration.k8s.io"
        ],
        "resources" => [
          "apiservices"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          "autoscaling"
        ],
        "resources" => [
          "horizontalpodautoscalers"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "apiextensions.k8s.io"
        ],
        "resources" => [
          "customresourcedefinitions"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          "knative-ingressgateway"
        ],
        "resources" => [
          "services",
          "deployments",
          "horizontalpodautoscalers"
        ],
        "verbs" => [
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          @observability_configmap,
          @logging_configmap,
          "config-controller"
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          @operator_service_account,
          @webhook_service_account
        ],
        "resources" => [
          "serviceaccounts"
        ],
        "verbs" => [
          "delete"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app_name)
    |> B.name(@serving_operator_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_knative_eventing_operator(_config) do
    rules = [
      %{
        "apiGroups" => [
          "operator.knative.dev"
        ],
        "resources" => [
          "*"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "rbac.authorization.k8s.io"
        ],
        "resources" => [
          "clusterroles",
          "roles"
        ],
        "verbs" => [
          "create",
          "delete",
          "escalate",
          "get",
          "list",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "rbac.authorization.k8s.io"
        ],
        "resources" => [
          "clusterrolebindings",
          "rolebindings"
        ],
        "verbs" => [
          "create",
          "delete",
          "list",
          "get",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "apiregistration.k8s.io"
        ],
        "resources" => [
          "apiservices"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "services"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "caching.internal.knative.dev"
        ],
        "resources" => [
          "images"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "namespaces"
        ],
        "verbs" => [
          "get",
          "update",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "apps"
        ],
        "resources" => [
          "deployments",
          "daemonsets",
          "replicasets",
          "statefulsets"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "apiregistration.k8s.io"
        ],
        "resources" => [
          "apiservices"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          "autoscaling"
        ],
        "resources" => [
          "horizontalpodautoscalers"
        ],
        "verbs" => [
          "create",
          "delete",
          "update",
          "get",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "apiextensions.k8s.io"
        ],
        "resources" => [
          "customresourcedefinitions"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "batch"
        ],
        "resources" => [
          "jobs"
        ],
        "verbs" => [
          "create",
          "delete",
          "update",
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          @operator_service_account,
          @webhook_service_account
        ],
        "resources" => [
          "serviceaccounts"
        ],
        "verbs" => [
          "delete"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app_name)
    |> B.name(@eventing_operator_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_operator_webhook(_config) do
    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "namespaces"
        ],
        "verbs" => [
          "get",
          "create",
          "update",
          "list",
          "watch",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "namespaces/finalizers"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "apps"
        ],
        "resources" => [
          "deployments"
        ],
        "verbs" => [
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "apps"
        ],
        "resources" => [
          "deployments/finalizers"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "admissionregistration.k8s.io"
        ],
        "resources" => [
          "mutatingwebhookconfigurations",
          "validatingwebhookconfigurations"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "apiextensions.k8s.io"
        ],
        "resources" => [
          "customresourcedefinitions"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
          "watch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@webhook_cluster_role)
    |> B.app_labels(@app_name)
    |> B.rules(rules)
  end

  def service_account_operator(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.namespace(namespace)
    |> B.name(@operator_service_account)
    |> B.app_labels(@app_name)
  end

  def service_account_webhook(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.namespace(namespace)
    |> B.name(@webhook_service_account)
    |> B.app_labels(@app_name)
  end

  def cluster_role_binding_serving_operator(config) do
    namespace = DevtoolsSettings.namespace(config)

    cluster_role_binding(
      @serving_operator_cluster_role,
      @serving_operator_cluster_role,
      @operator_service_account,
      namespace
    )
  end

  def cluster_role_binding_aggregated_serving(config) do
    namespace = DevtoolsSettings.namespace(config)

    cluster_role_binding(
      @aggregated_serving_cluster_role,
      @aggregated_serving_cluster_role,
      @operator_service_account,
      namespace
    )
  end

  def cluster_role_binding_aggregated_appname_serving(config) do
    namespace = DevtoolsSettings.namespace(config)

    cluster_role_binding(
      @aggregated_serving_appname_cluster_role,
      @aggregated_serving_appname_cluster_role,
      @operator_service_account,
      namespace
    )
  end

  def cluster_role_binding_aggregated_battery_app_serving(config) do
    namespace = DevtoolsSettings.namespace(config)

    cluster_role_binding(
      @aggregated_serving_battery_app_cluster_role,
      @aggregated_serving_battery_app_cluster_role,
      @operator_service_account,
      namespace
    )
  end

  def cluster_role_binding_eventing_operator(config) do
    namespace = DevtoolsSettings.namespace(config)

    cluster_role_binding(
      @eventing_operator_cluster_role,
      @eventing_operator_cluster_role,
      @operator_service_account,
      namespace
    )
  end

  def cluster_role_binding_aggregated_eventing(config) do
    namespace = DevtoolsSettings.namespace(config)

    cluster_role_binding(
      @aggregated_eventing_cluster_role,
      @aggregated_eventing_cluster_role,
      @operator_service_account,
      namespace
    )
  end

  def cluster_role_binding_aggregated_appname_eventing(config) do
    namespace = DevtoolsSettings.namespace(config)

    cluster_role_binding(
      @aggregated_eventing_appname_cluster_role,
      @aggregated_eventing_appname_cluster_role,
      @operator_service_account,
      namespace
    )
  end

  def cluster_role_binding_aggregated_battery_app_eventing(config) do
    namespace = DevtoolsSettings.namespace(config)

    cluster_role_binding(
      @aggregated_eventing_battery_app_cluster_role,
      @aggregated_eventing_battery_app_cluster_role,
      @operator_service_account,
      namespace
    )
  end

  def cluster_role_binding_operator_webhook(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@webhook_cluster_role)
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref(@webhook_cluster_role))
    |> B.subject(B.build_service_account(@webhook_service_account, namespace))
  end

  def role_operator_webhook(config) do
    namespace = DevtoolsSettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "create",
          "update",
          "list",
          "watch",
          "patch"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.name(@webhook_role)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.rules(rules)
  end

  def role_binding_operator_webhook(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name(@webhook_role)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_role_ref(@webhook_role))
    |> B.subject(B.build_service_account(@webhook_service_account, namespace))
  end

  def secret_webhook_certs(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:secret)
    |> B.name(@webhook_certs_secret)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def config_map_config_logging(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "_example" =>
        "################################\n#                              #\n#    EXAMPLE CONFIGURATION     #\n#                              #\n################################\n\n# This block is not actually functional configuration,\n# but serves to illustrate the available configuration\n# options and document them in a way that is accessible\n# to users that `kubectl edit` this config map.\n#\n# These sample configuration options may be copied out of\n# this example block and unindented to be in the data block\n# to actually change the configuration.\n\n# Common configuration for all Knative codebase\nzap-logger-config: |\n  %{\n    \"level\": \"info\",\n    \"development\": false,\n    \"outputPaths\": [\"stdout\"],\n    \"errorOutputPaths\": [\"stderr\"],\n    \"encoding\": \"json\",\n    \"encoderConfig\": %{\n      \"timeKey\": \"ts\",\n      \"levelKey\": \"level\",\n      \"nameKey\": \"logger\",\n      \"callerKey\": \"caller\",\n      \"messageKey\": \"msg\",\n      \"stacktraceKey\": \"stacktrace\",\n      \"lineEnding\": \"\",\n      \"levelEncoder\": \"\",\n      \"timeEncoder\": \"iso8601\",\n      \"durationEncoder\": \"\",\n      \"callerEncoder\": \"\"\n    }\n  }\n"
    }

    B.build_resource(:config_map)
    |> B.name(@logging_configmap)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  def deployment_webhook(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "operator-webhook",
          "role" => "operator-webhook"
        }
      },
      "template" => %{
        "metadata" => %{
          "annotations" => %{
            "cluster-autoscaler.kubernetes.io/safe-to-evict" => "false",
            "sidecar.istio.io/inject" => "false"
          },
          "labels" => %{
            "app.kubernetes.io/component" => "operator-webhook",
            "battery/app" => "operator-webhook",
            "battery/managed" => "true",
            "role" => "operator-webhook"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "env" => [
                %{
                  "name" => "POD_NAME",
                  "valueFrom" => %{
                    "fieldRef" => %{
                      "fieldPath" => "metadata.name"
                    }
                  }
                },
                %{
                  "name" => "SYSTEM_NAMESPACE",
                  "valueFrom" => %{
                    "fieldRef" => %{
                      "fieldPath" => "metadata.namespace"
                    }
                  }
                },
                %{
                  "name" => "CONFIG_LOGGING_NAME",
                  "value" => @logging_configmap
                },
                %{
                  "name" => "CONFIG_OBSERVABILITY_NAME",
                  "value" => @observability_configmap
                },
                %{
                  "name" => "WEBHOOK_NAME",
                  "value" => "operator-webhook"
                },
                %{
                  "name" => "WEBHOOK_PORT",
                  "value" => "8443"
                },
                %{
                  "name" => "METRICS_DOMAIN",
                  "value" => "knative.dev/operator"
                }
              ],
              "image" =>
                "gcr.io/knative-releases/knative.dev/operator/cmd/webhook@sha256:bcb52df48b96280209ae16eab953fc42e4cccbb00db09a6209101345b4e9fb63",
              "livenessProbe" => %{
                "failureThreshold" => 6,
                "httpGet" => %{
                  "httpHeaders" => [
                    %{
                      "name" => "k-kubelet-probe",
                      "value" => "webhook"
                    }
                  ],
                  "port" => 8443,
                  "scheme" => "HTTPS"
                },
                "initialDelaySeconds" => 20,
                "periodSeconds" => 1
              },
              "name" => "operator-webhook",
              "ports" => [
                %{
                  "containerPort" => 9090,
                  "name" => "metrics"
                },
                %{
                  "containerPort" => 8008,
                  "name" => "profiling"
                },
                %{
                  "containerPort" => 8443,
                  "name" => "https-webhook"
                }
              ],
              "readinessProbe" => %{
                "httpGet" => %{
                  "httpHeaders" => [
                    %{
                      "name" => "k-kubelet-probe",
                      "value" => "webhook"
                    }
                  ],
                  "port" => 8443,
                  "scheme" => "HTTPS"
                },
                "periodSeconds" => 1
              },
              "resources" => %{
                "limits" => %{
                  "memory" => "500Mi"
                },
                "requests" => %{
                  "cpu" => "100m",
                  "memory" => "100Mi"
                }
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{
                  "drop" => [
                    "all"
                  ]
                },
                "readOnlyRootFilesystem" => true,
                "runAsNonRoot" => true
              }
            }
          ],
          "serviceAccountName" => @webhook_service_account,
          "terminationGracePeriodSeconds" => 300
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("operator-webhook")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def config_map_config_observability(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "_example" =>
        "################################\n#                              #\n#    EXAMPLE CONFIGURATION     #\n#                              #\n################################\n\n# This block is not actually functional configuration,\n# but serves to illustrate the available configuration\n# options and document them in a way that is accessible\n# to users that `kubectl edit` this config map.\n#\n# These sample configuration options may be copied out of\n# this example block and unindented to be in the data block\n# to actually change the configuration.\n\n# logging.enable-var-log-collection defaults to false.\n# The fluentd daemon set will be set up to collect /var/log if\n# this flag is true.\nlogging.enable-var-log-collection: false\n\n# logging.revision-url-template provides a template to use for producing the\n# logging URL that is injected into the status of each Revision.\n# This value is what you might use the the Knative monitoring bundle, and provides\n# access to Kibana after setting up kubectl proxy.\nlogging.revision-url-template: |\n  http://localhost:8001/api/v1/namespaces/knative-monitoring/services/kibana-logging/proxy/app/kibana#/discover?_a=(query:(match:(kubernetes.labels.serving-knative-dev%2FrevisionUID:(query:'$%{REVISION_UID}',type:phrase))))\n\n# If non-empty, this enables queue proxy writing request logs to stdout.\n# The value determines the shape of the request logs and it must be a valid go text/template.\n# It is important to keep this as a single line. Multiple lines are parsed as separate entities\n# by most collection agents and will split the request logs into multiple records.\n#\n# The following fields and functions are available to the template:\n#\n# Request: An http.Request (see https://golang.org/pkg/net/http/#Request)\n# representing an HTTP request received by the server.\n#\n# Response:\n# struct %{\n#   Code    int       // HTTP status code (see https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml)\n#   Size    int       // An int representing the size of the response.\n#   Latency float64   // A float64 representing the latency of the response in seconds.\n# }\n#\n# Revision:\n# struct %{\n#   Name          string  // Knative revision name\n#   Namespace     string  // Knative revision namespace\n#   Service       string  // Knative service name\n#   Configuration string  // Knative configuration name\n#   PodName       string  // Name of the pod hosting the revision\n#   PodIP         string  // IP of the pod hosting the revision\n# }\n#\nlogging.request-log-template: '%{\"httpRequest\": %{\"requestMethod\": \"%{%{.Request.Method}}\", \"requestUrl\": \"%{%{js .Request.RequestURI}}\", \"requestSize\": \"%{%{.Request.ContentLength}}\", \"status\": %{%{.Response.Code}}, \"responseSize\": \"%{%{.Response.Size}}\", \"userAgent\": \"%{%{js .Request.UserAgent}}\", \"remoteIp\": \"%{%{js .Request.RemoteAddr}}\", \"serverIp\": \"%{%{.Revision.PodIP}}\", \"referer\": \"%{%{js .Request.Referer}}\", \"latency\": \"%{%{.Response.Latency}}s\", \"protocol\": \"%{%{.Request.Proto}}\"}, \"traceId\": \"%{%{index .Request.Header \"X-B3-Traceid\"}}\"}'\n\n# metrics.backend-destination field specifies the system metrics destination.\n# It supports either prometheus (the default) or stackdriver.\n# Note: Using stackdriver will incur additional charges\nmetrics.backend-destination: prometheus\n\n# metrics.request-metrics-backend-destination specifies the request metrics\n# destination. If non-empty, it enables queue proxy to send request metrics.\n# Currently supported values: prometheus, stackdriver.\nmetrics.request-metrics-backend-destination: prometheus\n\n# metrics.stackdriver-project-id field specifies the stackdriver project ID. This\n# field is optional. When running on GCE, application default credentials will be\n# used if this field is not provided.\nmetrics.stackdriver-project-id: \"<your stackdriver project id>\"\n\n# metrics.allow-stackdriver-custom-metrics indicates whether it is allowed to send metrics to\n# Stackdriver using \"global\" resource type and custom metric type if the\n# metrics are not supported by \"knative_revision\" resource type. Setting this\n# flag to \"true\" could cause extra Stackdriver charge.\n# If metrics.backend-destination is not Stackdriver, this is ignored.\nmetrics.allow-stackdriver-custom-metrics: \"false\"\n"
    }

    B.build_resource(:config_map)
    |> B.name(@observability_configmap)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  def deployment_knative_operator(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "name" => "knative-operator"
        }
      },
      "template" => %{
        "metadata" => %{
          "annotations" => %{
            "sidecar.istio.io/inject" => "false"
          },
          "labels" => %{
            "battery/app" => "knative-operator",
            "battery/managed" => "true",
            "name" => "knative-operator"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "env" => [
                %{
                  "name" => "POD_NAME",
                  "valueFrom" => %{
                    "fieldRef" => %{
                      "fieldPath" => "metadata.name"
                    }
                  }
                },
                %{
                  "name" => "SYSTEM_NAMESPACE",
                  "valueFrom" => %{
                    "fieldRef" => %{
                      "fieldPath" => "metadata.namespace"
                    }
                  }
                },
                %{
                  "name" => "METRICS_DOMAIN",
                  "value" => "knative.dev/operator"
                },
                %{
                  "name" => "CONFIG_LOGGING_NAME",
                  "value" => @logging_configmap
                },
                %{
                  "name" => "CONFIG_OBSERVABILITY_NAME",
                  "value" => @observability_configmap
                }
              ],
              "image" =>
                "gcr.io/knative-releases/knative.dev/operator/cmd/operator@sha256:e1ea271f1292aed1d4700d1e6e8d12b92a5befc6f293da20dde2599d722db699",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "knative-operator",
              "ports" => [
                %{
                  "containerPort" => 9090,
                  "name" => "metrics"
                }
              ]
            }
          ],
          "serviceAccountName" => @operator_service_account
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("knative-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def service_webhook(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "ports" => [
        %{"name" => "http-metrics", "port" => 9090, "targetPort" => 9090},
        %{"name" => "http-profiliing", "port" => 8008, "targetPort" => 8008},
        %{"name" => "https-webhook", "port" => 443, "targetPort" => 8443}
      ],
      "selector" => %{
        "role" => "operator-webhook"
      }
    }

    B.build_resource(:service)
    |> B.name(@webhook_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def change_conversion(%{"spec" => %{"conversion" => %{}}} = crd, config),
    do: do_chang_conversion(crd, config)

  def change_conversion(%{spec: %{conversion: %{}}} = crd, config),
    do: do_chang_conversion(crd, config)

  def change_conversion(crd, _), do: crd

  defp do_chang_conversion(crd, config) do
    namespace = DevtoolsSettings.namespace(config)

    update_in(crd, ~w(spec conversion webhook clientConfig service), fn s ->
      (s || %{})
      |> Map.put("name", @webhook_service)
      |> Map.put("namespace", namespace)
    end)
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

  def materialize(config) do
    %{
      "/crds" => yaml(get_resource(:crd)),
      "/service_account" => service_account_operator(config),
      "/webhook_service_account" => service_account_webhook(config),
      "/cluster_roles/webhook/main" => cluster_role_operator_webhook(config),
      "/cluster_roles/serving/main" => cluster_role_knative_serving_operator(config),
      "/cluster_roles/serving/aggregated" => aggregated_cluster_role_serving(config),
      "/cluster_roles/serving/aggregated_appname" =>
        aggregated_cluster_role_serving_appname(config),
      "/cluster_roles/serving/aggregated_battery" =>
        aggregated_cluster_role_serving_battery_app(config),
      "/cluster_roles/eventing/main" => cluster_role_knative_eventing_operator(config),
      "/cluster_roles/eventing/aggregated" => aggregated_cluster_role_eventing(config),
      "/cluster_roles/eventing/aggregated_appname" =>
        aggregated_cluster_role_eventing_appname(config),
      "/cluster_roles/eventing/aggregated_battery" =>
        aggregated_cluster_role_eventing_battery_app(config),
      "/cluster_role_bindings/webhook/main" => cluster_role_binding_operator_webhook(config),
      "/cluster_role_bindings/serving/main" => cluster_role_binding_serving_operator(config),
      "/cluster_role_bindings/serving/aggregated" =>
        cluster_role_binding_aggregated_serving(config),
      "/cluster_role_bindings/serving/aggregated_appname" =>
        cluster_role_binding_aggregated_appname_serving(config),
      "/cluster_role_bindings/serving/aggregated_battery" =>
        cluster_role_binding_aggregated_battery_app_serving(config),
      "/cluster_role_bindings/eventing/main" => cluster_role_binding_eventing_operator(config),
      "/cluster_role_bindings/eventing/aggregated" =>
        cluster_role_binding_aggregated_eventing(config),
      "/cluster_role_bindings/eventing/aggregated_appname" =>
        cluster_role_binding_aggregated_appname_eventing(config),
      "/cluster_role_bindings/eventing/aggregated_battery" =>
        cluster_role_binding_aggregated_battery_app_eventing(config),
      "/role/webhook" => role_operator_webhook(config),
      "/role_binding/webhook" => role_binding_operator_webhook(config),
      "/secret/webhook_certs" => secret_webhook_certs(config),
      "/configs/logging" => config_map_config_logging(config),
      "/configs/observability" => config_map_config_observability(config),
      "/deployments/webhook" => deployment_webhook(config),
      "/deployments/operator" => deployment_knative_operator(config)
    }
  end
end
