defmodule CommonCore.Resources.Kiali do
  use CommonCore.Resources.ResourceGenerator, app_name: "kiali"

  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.Hosts

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.IstioConfig.VirtualService

  resource(:service_account_main, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:service_account)
    |> B.name("kiali")
    |> B.namespace(namespace)
  end

  resource(:cluster_role_binding_main, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:cluster_role_binding)
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

    B.build_resource(:cluster_role)
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

    B.build_resource(:cluster_role)
    |> B.name("kiali-viewer")
    |> B.rules(rules)
  end

  resource(:config_map_main, _battery, state) do
    namespace = istio_namespace(state)

    data = %{
      "config.yaml" => %{
        "auth" => %{
          "openid" => %{},
          "openshift" => %{"client_id_prefix" => "kiali"},
          "strategy" => "anonymous"
        },
        "deployment" => %{
          "accessible_namespaces" => ["**"],
          "additional_service_yaml" => %{},
          "affinity" => %{"node" => %{}, "pod" => %{}, "pod_anti" => %{}},
          "configmap_annotations" => %{},
          "custom_secrets" => [],
          "host_aliases" => [],
          "hpa" => %{"api_version" => "autoscaling/v2", "spec" => %{}},
          "image_digest" => "",
          "image_name" => "quay.io/kiali/kiali",
          "image_pull_policy" => "Always",
          "image_pull_secrets" => [],
          "image_version" => "v1.71.0",
          "ingress" => %{
            "additional_labels" => %{},
            "class_name" => "nginx",
            "override_yaml" => %{"metadata" => %{}}
          },
          "instance_name" => "kiali",
          "logger" => %{
            "log_format" => "text",
            "log_level" => "debug",
            "sampler_rate" => "1",
            "time_field_format" => "2006-01-02T15:04:05Z07:00"
          },
          "namespace" => "battery-istio",
          "node_selector" => %{},
          "pod_annotations" => %{},
          "pod_labels" => %{},
          "priority_class_name" => "",
          "replicas" => 1,
          "resources" => %{
            "limits" => %{"memory" => "1Gi"},
            "requests" => %{"cpu" => "10m", "memory" => "64Mi"}
          },
          "secret_name" => "kiali",
          "security_context" => %{},
          "service_annotations" => %{},
          "service_type" => "",
          "tolerations" => [],
          "version_label" => "v1.71.0",
          "view_only_mode" => false
        },
        "external_services" => %{
          "custom_dashboards" => %{"enabled" => true},
          "istio" => %{"root_namespace" => "battery-istio"}
        },
        "identity" => %{"cert_file" => "", "private_key_file" => ""},
        "istio_namespace" => "battery-istio",
        "kiali_feature_flags" => %{
          "certificates_information_indicators" => %{
            "enabled" => true,
            "secrets" => ["cacerts", "istio-ca-secret"]
          },
          "clustering" => %{
            "autodetect_secrets" => %{
              "enabled" => true,
              "label" => "kiali.io/multiCluster=true"
            },
            "clusters" => []
          },
          "disabled_features" => [],
          "validations" => %{"ignore" => ["KIA1301"]}
        },
        "login_token" => %{"signing_key" => "gEmf58MPasrZkPsh"},
        "server" => %{
          "metrics_enabled" => true,
          "metrics_port" => 9090,
          "port" => 20_001,
          "web_root" => "/kiali"
        }
      }
    }

    B.build_resource(:config_map)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:role_binding_controlplane, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:role_binding)
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

    B.build_resource(:role)
    |> B.name("kiali-controlplane")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:deployment_main, battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )
      |> Map.put(
        "strategy",
        %{"rollingUpdate" => %{"maxSurge" => 1, "maxUnavailable" => 1}, "type" => "RollingUpdate"}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "annotations" => %{
              "kiali.io/dashboards" => "go,kiali",
              "prometheus.io/port" => "9090",
              "prometheus.io/scrape" => "true"
            },
            "labels" => %{
              "battery/app" => @app_name,
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
                "imagePullPolicy" => "Always",
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
      )

    B.build_resource(:deployment)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_main, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"appProtocol" => "http", "name" => "http", "port" => 20_001, "protocol" => "TCP"},
        %{"appProtocol" => "http", "name" => "http-metrics", "port" => 9090, "protocol" => "TCP"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:virtual_service, _battery, state) do
    namespace = istio_namespace(state)

    spec = VirtualService.fallback_port("kiali", 20_001, hosts: [kiali_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.name("kiali")
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end
end
