defmodule KubeResources.KnativeOperator do
  @moduledoc false
  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeResources.DevtoolsSettings

  @app_name "knative-operator"
  @knative_crd_path "priv/manifests/knative/operator-crds.yaml"

  def materialize(config) do
    %{
      "/0/crd" => yaml(knative_crd_content()),
      "/2/deployment" => deployment(config),
      "/3/cluster_role" => cluster_role(config),
      "/4/cluster_role_1" => cluster_role_1(config),
      "/5/cluster_role_2" => cluster_role_2(config),
      "/6/cluster_role_3" => cluster_role_3(config),
      "/7/cluster_role_binding" => cluster_role_binding(config),
      "/8/cluster_role_binding_1" => cluster_role_binding_1(config),
      "/9/cluster_role_binding_2" => cluster_role_binding_2(config),
      "/10/cluster_role_binding_3" => cluster_role_binding_3(config),
      "/11/service_account" => service_account(config),
      "/12/destination_namespace" => dest_namespace(config),
      "/13/knative_serving" => knative_serving(config)
    }
  end

  def config_map(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{
        "name" => "config-logging",
        "namespace" => namespace,
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
      },
      "data" => %{
        "_example" => """
        ################################
        #                              #
        #    EXAMPLE CONFIGURATION     #
        #                              #
        ################################

        # This block is not actually functional configuration,
        # but serves to illustrate the available configuration
        # options and document them in a way that is accessible
        # to users that `kubectl edit` this config map.
        #
        # These sample configuration options may be copied out of
        # this example block and unindented to be in the data block
        # to actually change the configuration.

        # Common configuration for all Knative codebase
        zap-logger-config: |
          %{
            \"level\" => \"info\",
            \"development\" => false,
            \"outputPaths\" => [\"stdout\"],
            \"errorOutputPaths\" => [\"stderr\"],
            \"encoding\" => \"json\",
            \"encoderConfig\" => %{
              \"timeKey\" => \"ts\",
              \"levelKey\" => \"level\",
              \"nameKey\" => \"logger\",
              \"callerKey\" => \"caller\",
              \"messageKey\" => \"msg\",
              \"stacktraceKey\" => \"stacktrace\",
              \"lineEnding\" => \"\",
              \"levelEncoder\" => \"\",
              \"timeEncoder\" => \"iso8601\",
              \"durationEncoder\" => \"\",
              \"callerEncoder\" => \"\"
            }
          }
        """
      }
    }
  end

  def config_map_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{
        "name" => "config-observability",
        "namespace" => namespace,
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
      },
      "data" => %{
        "_example" => """
        ################################
        #                              #
        #    EXAMPLE CONFIGURATION     #
        #                              #
        ################################

        # This block is not actually functional configuration,
        # but serves to illustrate the available configuration
        # options and document them in a way that is accessible
        # to users that `kubectl edit` this config map.
        #
        # These sample configuration options may be copied out of
        # this example block and unindented to be in the data block
        # to actually change the configuration.

        # logging.enable-var-log-collection defaults to false.
        # The fluentd daemon set will be set up to collect /var/log if
        # this flag is true.
        logging.enable-var-log-collection: false

        # logging.revision-url-template provides a template to use for producing the
        # logging URL that is injected into the status of each Revision.
        # This value is what you might use the the Knative monitoring bundle, and provides
        # access to Kibana after setting up kubectl proxy.
        logging.revision-url-template: |
          http://localhost:8001/api/v1/namespaces/knative-monitoring/services/kibana-logging/proxy/app/kibana#/discover?_a=(query:(match:(kubernetes.labels.serving-knative-dev%2FrevisionUID:(query:'$%{REVISION_UID}',type:phrase))))

        # If non-empty, this enables queue proxy writing request logs to stdout.
        # The value determines the shape of the request logs and it must be a valid go text/template.
        # It is important to keep this as a single line. Multiple lines are parsed as separate entities
        # by most collection agents and will split the request logs into multiple records.
        #
        # The following fields and functions are available to the template:
        #
        # Request: An http.Request (see https://golang.org/pkg/net/http/#Request)
        # representing an HTTP request received by the server.
        #
        # Response:
        # struct %{
        #   Code    int       // HTTP status code (see https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml)
        #   Size    int       // An int representing the size of the response.
        #   Latency float64   // A float64 representing the latency of the response in seconds.
        # }
        #
        # Revision:
        # struct %{
        #   Name          string  // Knative revision name
        #   Namespace     string  // Knative revision namespace
        #   Service       string  // Knative service name
        #   Configuration string  // Knative configuration name
        #   PodName       string  // Name of the pod hosting the revision
        #   PodIP         string  // IP of the pod hosting the revision
        # }
        #
        logging.request-log-template: '%{\"httpRequest\" => %{\"requestMethod\" => \"%{%{.Request.Method}}\", \"requestUrl\" => \"%{%{js .Request.RequestURI}}\", \"requestSize\" => \"%{%{.Request.ContentLength}}\", \"status\" => %{%{.Response.Code}}, \"responseSize\" => \"%{%{.Response.Size}}\", \"userAgent\" => \"%{%{js .Request.UserAgent}}\", \"remoteIp\" => \"%{%{js .Request.RemoteAddr}}\", \"serverIp\" => \"%{%{.Revision.PodIP}}\", \"referer\" => \"%{%{js .Request.Referer}}\", \"latency\" => \"%{%{.Response.Latency}}s\", \"protocol\" => \"%{%{.Request.Proto}}\"}, \"traceId\" => \"%{%{index .Request.Header \"X-B3-Traceid\"}}\"}'

        # metrics.backend-destination field specifies the system metrics destination.
        # It supports either prometheus (the default) or stackdriver.
        # Note: Using stackdriver will incur additional charges
        metrics.backend-destination: prometheus

        # metrics.request-metrics-backend-destination specifies the request metrics
        # destination. If non-empty, it enables queue proxy to send request metrics.
        # Currently supported values: prometheus, stackdriver.
        metrics.request-metrics-backend-destination: prometheus

        # metrics.stackdriver-project-id field specifies the stackdriver project ID. This
        # field is optional. When running on GCE, application default credentials will be
        # used if this field is not provided.
        metrics.stackdriver-project-id: \"<your stackdriver project id>\"

        # metrics.allow-stackdriver-custom-metrics indicates whether it is allowed to send metrics to
        # Stackdriver using \"global\" resource type and custom metric type if the
        # metrics are not supported by \"knative_revision\" resource type. Setting this
        # flag to \"true\" could cause extra Stackdriver charge.
        # If metrics.backend-destination is not Stackdriver, this is ignored.
        metrics.allow-stackdriver-custom-metrics: \"false\"
        """
      }
    }
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
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{"name" => "knative-operator", "battery/managed" => "True"}
        },
        "template" => %{
          "metadata" => %{
            "annotations" => %{"sidecar.istio.io/inject" => "false"},
            "labels" => %{
              "name" => "knative-operator",
              "battery/app" => @app_name,
              "battery/managed" => "True"
            }
          },
          "spec" => %{
            "serviceAccountName" => "knative-operator",
            "containers" => [
              %{
                "name" => "knative-operator",
                "image" => "#{knative_operator_image}@#{knative_operator_version}",
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
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
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
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
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
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
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
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
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
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
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
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
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
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
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

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "knative-operator",
        "namespace" => namespace,
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "True"}
      }
    }
  end

  def dest_namespace(config) do
    knative_dest_namespace = DevtoolsSettings.knative_destination_namespace(config)

    B.build_resource(:namespace)
    |> B.name(knative_dest_namespace)
    |> B.app_labels("knative-operator")
  end

  def knative_serving(config) do
    knative_dest_namespace = DevtoolsSettings.knative_destination_namespace(config)

    B.build_resource(:knative_serving)
    |> B.namespace(knative_dest_namespace)
    |> B.app_labels("knative-operator")
    |> B.name("knative-serving")
    |> B.spec(serving_spec(config))
  end

  defp serving_spec(_config) do
    %{}
    |> Map.put("config", %{
      "istio" => %{
        "gateway.battery-knative.knative-ingress-gateway" =>
          "istio-ingressgateway.battery-core.svc.cluster.local"
      }
    })
    |> Map.put("ingress", %{"istio" => %{"enabled" => true}})
  end

  defp knative_crd_content, do: unquote(File.read!(@knative_crd_path))
end
