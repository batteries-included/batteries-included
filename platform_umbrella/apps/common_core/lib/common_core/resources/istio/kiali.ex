defmodule CommonCore.Resources.Kiali do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "kiali"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Istio.KialiConfigGenerator
  alias CommonCore.Resources.RouteBuilder, as: R

  @http_port 20_001

  resource(:service_account_main, _battery, state) do
    namespace = istio_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("kiali")
    |> B.namespace(namespace)
  end

  resource(:cluster_role_binding_main, _battery, state) do
    namespace = istio_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("kiali")
    |> B.role_ref(B.build_cluster_role_ref("kiali"))
    |> B.subject(B.build_service_account("kiali", namespace))
  end

  resource(:cluster_role_main) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "endpoints", "pods/log"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces", "pods", "replicationcontrollers", "services"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{"apiGroups" => [""], "resources" => ["pods/portforward"], "verbs" => ["create", "post"]},
      %{
        "apiGroups" => ["extensions", "apps"],
        "resources" => ["daemonsets", "deployments", "replicasets", "statefulsets"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["cronjobs", "jobs"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{
        "apiGroups" => [
          "networking.istio.io",
          "security.istio.io",
          "extensions.istio.io",
          "telemetry.istio.io",
          "gateway.networking.k8s.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch", "create", "delete", "patch"]
      },
      %{
        "apiGroups" => ["apps.openshift.io"],
        "resources" => ["deploymentconfigs"],
        "verbs" => ["get", "list", "watch", "patch"]
      },
      %{"apiGroups" => ["project.openshift.io"], "resources" => ["projects"], "verbs" => ["get"]},
      %{"apiGroups" => ["route.openshift.io"], "resources" => ["routes"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("kiali")
    |> B.rules(rules)
  end

  resource(:cluster_role_viewer) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "endpoints", "pods/log"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces", "pods", "replicationcontrollers", "services"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["pods/portforward"], "verbs" => ["create", "post"]},
      %{
        "apiGroups" => ["extensions", "apps"],
        "resources" => ["daemonsets", "deployments", "replicasets", "statefulsets"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["cronjobs", "jobs"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [
          "networking.istio.io",
          "security.istio.io",
          "extensions.istio.io",
          "telemetry.istio.io",
          "gateway.networking.k8s.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps.openshift.io"],
        "resources" => ["deploymentconfigs"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => ["project.openshift.io"], "resources" => ["projects"], "verbs" => ["get"]},
      %{"apiGroups" => ["route.openshift.io"], "resources" => ["routes"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("kiali-viewer")
    |> B.rules(rules)
  end

  resource(:config_map_main, battery, state) do
    namespace_istio = istio_namespace(state)

    data = %{"config.yaml" => Ymlr.document!(KialiConfigGenerator.materialize(battery, state))}

    :config_map
    |> B.build_resource()
    |> B.name("kiali")
    |> B.namespace(namespace_istio)
    |> B.data(data)
  end

  resource(:role_binding_controlplane, _battery, state) do
    namespace = istio_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("kiali-controlplane")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("kiali-controlplane"))
    |> B.subject(B.build_service_account("kiali", namespace))
  end

  resource(:role_controlplane, _battery, state) do
    namespace = istio_namespace(state)

    rules = [
      %{
        "apiGroups" => [""],
        "resourceNames" => ["cacerts", "istio-ca-secret"],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    :role
    |> B.build_resource()
    |> B.name("kiali-controlplane")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:deployment_main, battery, state) do
    namespace = istio_namespace(state)

    template =
      %{
        "metadata" => %{
          "annotations" => %{
            "kiali.io/dashboards" => "go,kiali",
            "prometheus.io/port" => "9090",
            "prometheus.io/scrape" => "true"
          },
          "labels" => %{
            "battery/managed" => "true"
          },
          "name" => "kiali"
        },
        "spec" => %{
          "containers" => [
            %{
              "command" => ["/opt/kiali/kiali", "-config", "/kiali-configuration/config.yaml"],
              "env" => [
                %{
                  "name" => "ACTIVE_NAMESPACE",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                },
                %{"name" => "LOG_LEVEL", "value" => "debug"},
                %{"name" => "LOG_FORMAT", "value" => "text"},
                %{"name" => "LOG_TIME_FIELD_FORMAT", "value" => "2006-01-02T15:04:05Z07:00"},
                %{"name" => "LOG_SAMPLER_RATE", "value" => "1"}
              ],
              "image" => battery.config.image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{
                  "path" => "/kiali/healthz",
                  "port" => "api-port",
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 5,
                "periodSeconds" => 30
              },
              "name" => "kiali",
              "ports" => [
                %{"containerPort" => 20_001, "name" => "api-port"},
                %{"containerPort" => 9090, "name" => "http-metrics"}
              ],
              "readinessProbe" => %{
                "httpGet" => %{
                  "path" => "/kiali/healthz",
                  "port" => "api-port",
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 5,
                "periodSeconds" => 30
              },
              "resources" => %{
                "limits" => %{"memory" => "1Gi"},
                "requests" => %{"cpu" => "10m", "memory" => "64Mi"}
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "privileged" => false,
                "readOnlyRootFilesystem" => true,
                "runAsNonRoot" => true
              },
              "volumeMounts" => [
                %{"mountPath" => "/kiali-configuration", "name" => "kiali-configuration"},
                %{"mountPath" => "/kiali-cert", "name" => "kiali-cert"},
                %{"mountPath" => "/kiali-secret", "name" => "kiali-secret"},
                %{"mountPath" => "/kiali-cabundle", "name" => "kiali-cabundle"}
              ]
            }
          ],
          "serviceAccountName" => "kiali",
          "volumes" => [
            %{"configMap" => %{"name" => "kiali"}, "name" => "kiali-configuration"},
            %{
              "name" => "kiali-cert",
              "secret" => %{"optional" => true, "secretName" => "istio.kiali-service-account"}
            },
            %{
              "name" => "kiali-secret",
              "secret" => %{"optional" => true, "secretName" => "kiali"}
            },
            %{
              "configMap" => %{"name" => "kiali-cabundle", "optional" => true},
              "name" => "kiali-cabundle"
            }
          ]
        }
      }
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("strategy", %{"rollingUpdate" => %{"maxSurge" => 1, "maxUnavailable" => 1}, "type" => "RollingUpdate"})
      |> B.match_labels_selector(@app_name)
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_main, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"appProtocol" => "http", "name" => "http", "port" => @http_port, "protocol" => "TCP"},
        %{"appProtocol" => "http", "name" => "http-metrics", "port" => 9090, "protocol" => "TCP"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:http_route, battery, state) do
    namespace = istio_namespace(state)

    spec =
      battery
      |> R.new_httproute_spec(state)
      |> R.add_oauth2_proxy_rule(battery, state)
      |> R.add_backend(@app_name, @http_port)

    :gateway_http_route
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end
end
