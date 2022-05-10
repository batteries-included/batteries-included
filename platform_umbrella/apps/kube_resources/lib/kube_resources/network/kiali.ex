defmodule KubeResources.KialiServer do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeRawResources.NetworkSettings
  alias KubeResources.IstioConfig.VirtualService

  @app "kiali"

  @url_base "/x/kiali"

  def service_account(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:service_account)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: "/services/network/kiali"

  def url, do: "//control.#{KubeState.IstioIngress.single_address()}.sslip.io#{@url_base}"

  def virtual_service(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("kiali")
    |> B.spec(VirtualService.prefix(@url_base, "kiali", port: 20_001))
  end

  def config_map(config) do
    namespace = NetworkSettings.istio_namespace(config)
    istio_namespace = NetworkSettings.istio_namespace(config)

    config = %{
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
        "hpa" => %{"api_version" => "autoscaling/v2beta2", "spec" => %{}},
        "image_digest" => "",
        "image_name" => "quay.io/kiali/kiali",
        "image_pull_policy" => "Always",
        "image_pull_secrets" => [],
        "image_version" => "v1.50.0",
        "ingress" => %{},
        "instance_name" => "kiali",
        "logger" => %{
          "log_format" => "text",
          "log_level" => "TRACE",
          "sampler_rate" => "1",
          "time_field_format" => "2006-01-02T15:04:05Z07:00"
        },
        "namespace" => namespace,
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
        "service_annotations" => %{},
        "service_type" => "",
        "tolerations" => [],
        "version_label" => "v1.50.0",
        "view_only_mode" => false
      },
      "external_services" => %{
        "custom_dashboards" => %{"enabled" => true},
        "prometheus" => %{
          "url" => "http://prometheus-operated.battery-core.svc.cluster.local:9090/"
        },
        "grafana" => %{
          "in_cluster_url" => "http://grafana.battery-core.svc.cluster.local:3000/x/grafana",
          "url" => "http:#{KubeResources.Grafana.url()}"
        },
        "istio" => %{"root_namespace" => namespace}
      },
      "identity" => %{"cert_file" => "", "private_key_file" => ""},
      "istio_namespace" => istio_namespace,
      "kiali_feature_flags" => %{
        "certificates_information_indicators" => %{
          "enabled" => true,
          "secrets" => ["cacerts", "istio-ca-secret"]
        },
        "clustering" => %{"enabled" => false},
        "disabled_features" => [],
        "validations" => %{"ignore" => ["KIA1201", "KIA1106"]}
      },
      "login_token" => %{"signing_key" => "7qkkuRw1MT2Fvyn1"},
      "server" => %{
        "metrics_enabled" => true,
        "metrics_port" => 9090,
        "port" => 20_001,
        "web_root" => "/x/kiali"
      }
    }

    B.build_resource(:config_map)
    |> B.name("kiali")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> Map.put("data", %{"config.yaml" => Ymlr.document!(config)})
  end

  def cluster_role(_config) do
    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "configmaps",
          "endpoints",
          "pods/log"
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
          "namespaces",
          "pods",
          "replicationcontrollers",
          "services"
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
          "pods/portforward"
        ],
        "verbs" => [
          "create",
          "post"
        ]
      },
      %{
        "apiGroups" => [
          "extensions",
          "apps"
        ],
        "resources" => [
          "daemonsets",
          "deployments",
          "replicasets",
          "statefulsets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "batch"
        ],
        "resources" => [
          "cronjobs",
          "jobs"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "networking.istio.io",
          "security.istio.io"
        ],
        "resources" => [
          "*"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "apps.openshift.io"
        ],
        "resources" => [
          "deploymentconfigs"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "project.openshift.io"
        ],
        "resources" => [
          "projects"
        ],
        "verbs" => [
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "route.openshift.io"
        ],
        "resources" => [
          "routes"
        ],
        "verbs" => [
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "authentication.k8s.io"
        ],
        "resources" => [
          "tokenreviews"
        ],
        "verbs" => [
          "create"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("battery-kiali-viewer")
    |> B.app_labels(@app)
    |> Map.put("rules", rules)
  end

  def cluster_role_1(_config) do
    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "configmaps",
          "endpoints",
          "pods/log"
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
          "namespaces",
          "pods",
          "replicationcontrollers",
          "services"
        ],
        "verbs" => [
          "get",
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
          "pods/portforward"
        ],
        "verbs" => [
          "create",
          "post"
        ]
      },
      %{
        "apiGroups" => [
          "extensions",
          "apps"
        ],
        "resources" => [
          "daemonsets",
          "deployments",
          "replicasets",
          "statefulsets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "batch"
        ],
        "resources" => [
          "cronjobs",
          "jobs"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "networking.istio.io",
          "security.istio.io"
        ],
        "resources" => [
          "*"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "delete",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "apps.openshift.io"
        ],
        "resources" => [
          "deploymentconfigs"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "project.openshift.io"
        ],
        "resources" => [
          "projects"
        ],
        "verbs" => [
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "route.openshift.io"
        ],
        "resources" => [
          "routes"
        ],
        "verbs" => [
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "authentication.k8s.io"
        ],
        "resources" => [
          "tokenreviews"
        ],
        "verbs" => [
          "create"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("battery-kiali")
    |> B.app_labels(@app)
    |> Map.put("rules", rules)
  end

  def cluster_role_binding(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.app_labels(@app)
    |> B.name("battery-kiali")
    |> Map.put("roleRef", B.build_cluster_role_ref("battery-kiali"))
    |> Map.put("subjects", [B.build_service_account("kiali", namespace)])
  end

  def role(config) do
    namespace = NetworkSettings.istio_namespace(config)

    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "list"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          "cacerts",
          "istio-ca-secret"
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get", "list", "watch"]}
    ]

    B.build_resource(:role)
    |> B.namespace(namespace)
    |> B.name("kiali-controlplane")
    |> B.app_labels(@app)
    |> Map.put("rules", rules)
  end

  def role_binding(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:role_binding)
    |> B.namespace(namespace)
    |> B.name("kiali-controlplane")
    |> Map.put("roleRef", B.build_role_ref("kiali-controlplane"))
    |> Map.put("subjects", [B.build_service_account("kiali", namespace)])
  end

  def service(config) do
    namespace = NetworkSettings.istio_namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/instance" => "kiali",
          "battery/app" => "kiali",
          "battery/managed" => "true",
          "version" => "v1.50.0"
        },
        "name" => "kiali",
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => "http",
            "port" => 20_001,
            "protocol" => "TCP"
          },
          %{
            "name" => "http-metrics",
            "port" => 9090,
            "protocol" => "TCP"
          }
        ],
        "selector" => %{
          "app.kubernetes.io/instance" => "kiali"
        }
      }
    }
  end

  def deployment(config) do
    namespace = NetworkSettings.istio_namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/instance" => "kiali",
          "battery/app" => "kiali",
          "app" => "kiali",
          "battery/managed" => "true",
          "version" => "v1.50.0"
        },
        "name" => "kiali",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "kiali"
          }
        },
        "strategy" => %{
          "rollingUpdate" => %{
            "maxSurge" => 1,
            "maxUnavailable" => 1
          },
          "type" => "RollingUpdate"
        },
        "template" => %{
          "metadata" => %{
            "annotations" => %{
              "kiali.io/dashboards" => "go,kiali",
              "prometheus.io/port" => "9090",
              "prometheus.io/scrape" => "true"
            },
            "labels" => %{
              "app.kubernetes.io/instance" => "kiali",
              "battery/app" => "kiali",
              "app" => "kiali",
              "battery/managed" => "true"
            },
            "name" => "kiali"
          },
          "spec" => %{
            "containers" => [
              %{
                "command" => [
                  "/opt/kiali/kiali",
                  "-config",
                  "/kiali-configuration/config.yaml"
                ],
                "env" => [
                  %{
                    "name" => "ACTIVE_NAMESPACE",
                    "valueFrom" => %{
                      "fieldRef" => %{
                        "fieldPath" => "metadata.namespace"
                      }
                    }
                  }
                ],
                "image" => "quay.io/kiali/kiali:v1.50.0",
                "imagePullPolicy" => "Always",
                "livenessProbe" => %{
                  "httpGet" => %{
                    "path" => "/x/kiali/healthz",
                    "port" => "api-port",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 30
                },
                "name" => "kiali",
                "ports" => [
                  %{
                    "containerPort" => 20_001,
                    "name" => "api-port"
                  },
                  %{
                    "containerPort" => 9090,
                    "name" => "http-metrics"
                  }
                ],
                "readinessProbe" => %{
                  "httpGet" => %{
                    "path" => "/x/kiali/healthz",
                    "port" => "api-port",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 30
                },
                "resources" => %{
                  "limits" => %{
                    "memory" => "1Gi"
                  },
                  "requests" => %{
                    "cpu" => "10m",
                    "memory" => "64Mi"
                  }
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "privileged" => false,
                  "readOnlyRootFilesystem" => true,
                  "runAsNonRoot" => true
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/kiali-configuration",
                    "name" => "kiali-configuration"
                  },
                  %{
                    "mountPath" => "/kiali-cert",
                    "name" => "kiali-cert"
                  },
                  %{
                    "mountPath" => "/kiali-secret",
                    "name" => "kiali-secret"
                  },
                  %{
                    "mountPath" => "/kiali-cabundle",
                    "name" => "kiali-cabundle"
                  }
                ]
              }
            ],
            "serviceAccountName" => "kiali",
            "volumes" => [
              %{
                "configMap" => %{
                  "name" => "kiali"
                },
                "name" => "kiali-configuration"
              },
              %{
                "name" => "kiali-cert",
                "secret" => %{
                  "optional" => true,
                  "secretName" => "istio.kiali-service-account"
                }
              },
              %{
                "name" => "kiali-secret",
                "secret" => %{
                  "optional" => true,
                  "secretName" => "kiali"
                }
              },
              %{
                "configMap" => %{
                  "name" => "kiali-cabundle",
                  "optional" => true
                },
                "name" => "kiali-cabundle"
              }
            ]
          }
        }
      }
    }
  end

  def materialize(config) do
    %{
      "/0/service_account" => service_account(config),
      "/1/config_map" => config_map(config),
      "/2/cluster_role" => cluster_role(config),
      "/3/cluster_role_1" => cluster_role_1(config),
      "/4/cluster_role_binding" => cluster_role_binding(config),
      "/5/role" => role(config),
      "/6/role_binding" => role_binding(config),
      "/7/service" => service(config),
      "/8/deployment" => deployment(config)
    }
  end
end
