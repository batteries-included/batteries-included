defmodule KubeResources.TektonOperator do
  use KubeExt.IncludeResource,
    tektonchains_operator_tekton_dev:
      "priv/manifests/tekton_operator/tektonchains_operator_tekton_dev.yaml",
    tektonconfigs_operator_tekton_dev:
      "priv/manifests/tekton_operator/tektonconfigs_operator_tekton_dev.yaml",
    tektondashboards_operator_tekton_dev:
      "priv/manifests/tekton_operator/tektondashboards_operator_tekton_dev.yaml",
    tektonhubs_operator_tekton_dev:
      "priv/manifests/tekton_operator/tektonhubs_operator_tekton_dev.yaml",
    tektoninstallersets_operator_tekton_dev:
      "priv/manifests/tekton_operator/tektoninstallersets_operator_tekton_dev.yaml",
    tektonpipelines_operator_tekton_dev:
      "priv/manifests/tekton_operator/tektonpipelines_operator_tekton_dev.yaml",
    tektonresults_operator_tekton_dev:
      "priv/manifests/tekton_operator/tektonresults_operator_tekton_dev.yaml",
    tektontriggers_operator_tekton_dev:
      "priv/manifests/tekton_operator/tektontriggers_operator_tekton_dev.yaml",
    zap_logger_config: "priv/raw_files/tekton_operator/zap-logger-config"

  use KubeExt.ResourceGenerator

  import KubeExt.Yaml

  alias KubeResources.DevtoolsSettings, as: Settings

  @app "tekton_operator"

  resource(:cluster_role_binding_tekton_config_read_rolebinding) do
    B.build_resource(:cluster_role_binding)
    |> B.name("tekton-config-read-rolebinding")
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref("tekton-config-read-role"))
    |> B.subject(B.build_group("system:authenticated", "default"))
  end

  resource(:cluster_role_binding_tekton_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:cluster_role_binding)
    |> B.name("tekton-operator")
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref("tekton-operator"))
    |> B.subject(B.build_service_account("tekton-operator", namespace))
  end

  resource(:cluster_role_tekton_config_read) do
    rules = [
      %{
        "apiGroups" => ["operator.tekton.dev"],
        "resources" => ["tektonconfigs"],
        "verbs" => ["get", "watch", "list"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("tekton-config-read-role")
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  resource(:cluster_role_tekton_operator) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => [
          "pods",
          "services",
          "endpoints",
          "persistentvolumeclaims",
          "events",
          "configmaps",
          "secrets",
          "pods/log",
          "limitranges"
        ],
        "verbs" => [
          "delete",
          "deletecollection",
          "create",
          "patch",
          "get",
          "list",
          "update",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["extensions", "apps", "networking.k8s.io"],
        "resources" => ["ingresses", "ingresses/status"],
        "verbs" => ["delete", "create", "patch", "get", "list", "update", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["namespaces/finalizers"], "verbs" => ["update"]},
      %{
        "apiGroups" => ["apps"],
        "resources" => [
          "deployments",
          "daemonsets",
          "replicasets",
          "statefulsets",
          "deployments/finalizers"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "deletecollection",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["monitoring.coreos.com"],
        "resources" => ["servicemonitors"],
        "verbs" => ["get", "create", "delete"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterroles", "roles"],
        "verbs" => ["get", "create", "update", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["serviceaccounts"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch", "impersonate"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterrolebindings", "rolebindings"],
        "verbs" => ["get", "create", "update", "delete"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions", "customresourcedefinitions/status"],
        "verbs" => ["get", "create", "update", "delete", "list", "patch", "watch"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{
        "apiGroups" => ["build.knative.dev"],
        "resources" => ["builds", "buildtemplates", "clusterbuildtemplates"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{
        "apiGroups" => ["extensions"],
        "resources" => ["deployments"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{
        "apiGroups" => ["extensions"],
        "resources" => ["deployments/finalizers"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{
        "apiGroups" => ["policy"],
        "resources" => ["podsecuritypolicies"],
        "verbs" => ["get", "create", "update", "delete", "use"]
      },
      %{
        "apiGroups" => ["operator.tekton.dev"],
        "resources" => ["*", "tektonaddons"],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "deletecollection",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["tekton.dev"],
        "resources" => [
          "tasks",
          "clustertasks",
          "taskruns",
          "pipelines",
          "pipelineruns",
          "pipelineresources",
          "conditions",
          "tasks/status",
          "clustertasks/status",
          "taskruns/status",
          "pipelines/status",
          "pipelineruns/status",
          "pipelineresources/status",
          "taskruns/finalizers",
          "pipelineruns/finalizers",
          "runs",
          "runs/status",
          "runs/finalizers"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "deletecollection",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["triggers.tekton.dev", "operator.tekton.dev"],
        "resources" => ["*"],
        "verbs" => [
          "add",
          "get",
          "list",
          "create",
          "update",
          "delete",
          "deletecollection",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["dashboard.tekton.dev"],
        "resources" => ["*", "tektonaddons", "extensions"],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "deletecollection",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["security.openshift.io"],
        "resources" => ["securitycontextconstraints"],
        "verbs" => ["use"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "list", "create", "update", "delete", "patch", "watch"]
      },
      %{
        "apiGroups" => ["autoscaling"],
        "resources" => ["horizontalpodautoscalers"],
        "verbs" => [
          "delete",
          "deletecollection",
          "create",
          "patch",
          "get",
          "list",
          "update",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["policy"],
        "resources" => ["poddisruptionbudgets"],
        "verbs" => [
          "delete",
          "deletecollection",
          "create",
          "patch",
          "get",
          "list",
          "update",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["serving.knative.dev"],
        "resources" => ["*", "*/status", "*/finalizers"],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "deletecollection",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["cronjobs", "jobs"],
        "verbs" => ["delete", "create", "patch", "get", "list", "update", "watch"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"],
        "verbs" => ["delete", "create", "patch", "get", "list", "update", "watch"]
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
        "apiGroups" => ["results.tekton.dev"],
        "resources" => ["*"],
        "verbs" => [
          "delete",
          "deletecollection",
          "create",
          "patch",
          "get",
          "list",
          "update",
          "watch"
        ]
      },
      %{
        "apiGroups" => ["resolution.tekton.dev"],
        "resources" => ["resolutionrequests", "resolutionrequests/status"],
        "verbs" => ["get", "list", "watch", "create", "delete", "update", "patch"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("tekton-operator")
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  resource(:config_map_logging, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data =
      %{}
      |> Map.put("loglevel.controller", "info")
      |> Map.put("loglevel.webhook", "info")
      |> Map.put("zap-logger-config", get_resource(:zap_logger_config))

    B.build_resource(:config_map)
    |> B.name("config-logging")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  resource(:config_map_tekton_defaults, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data =
      %{}
      |> Map.put("AUTOINSTALL_COMPONENTS", "true")
      |> Map.put("DEFAULT_TARGET_NAMESPACE", "tekton-pipelines")

    B.build_resource(:config_map)
    |> B.name("tekton-config-defaults")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  resource(:config_map_tekton_observability, battery, _state) do
    namespace = Settings.namespace(battery.config)
    data = %{}

    B.build_resource(:config_map)
    |> B.name("tekton-config-observability")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  resource(:config_map_tekton_operator_info, battery, _state) do
    namespace = Settings.namespace(battery.config)
    data = %{"version" => "v0.62.0"}

    B.build_resource(:config_map)
    |> B.name("tekton-operator-info")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  resource(:crd_tektonchains_operator_tekton_dev) do
    yaml(get_resource(:tektonchains_operator_tekton_dev))
  end

  resource(:crd_tektonconfigs_operator_tekton_dev) do
    yaml(get_resource(:tektonconfigs_operator_tekton_dev))
  end

  resource(:crd_tektondashboards_operator_tekton_dev) do
    yaml(get_resource(:tektondashboards_operator_tekton_dev))
  end

  resource(:crd_tektonhubs_operator_tekton_dev) do
    yaml(get_resource(:tektonhubs_operator_tekton_dev))
  end

  resource(:crd_tektoninstallersets_operator_tekton_dev) do
    yaml(get_resource(:tektoninstallersets_operator_tekton_dev))
  end

  resource(:crd_tektonpipelines_operator_tekton_dev) do
    yaml(get_resource(:tektonpipelines_operator_tekton_dev))
  end

  resource(:crd_tektonresults_operator_tekton_dev) do
    yaml(get_resource(:tektonresults_operator_tekton_dev))
  end

  resource(:crd_tektontriggers_operator_tekton_dev) do
    yaml(get_resource(:tektontriggers_operator_tekton_dev))
  end

  resource(:deployment_tekton_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"name" => "tekton-operator"}})
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "tekton_operator",
              "battery/managed" => "true",
              "name" => "tekton-operator"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "-controllers",
                  "tektonconfig,tektonpipeline,tektontrigger,tektonhub,tektonchain,tektonresults,tektondashboard",
                  "-unique-process-name",
                  "tekton-operator-lifecycle"
                ],
                "env" => [
                  %{
                    "name" => "SYSTEM_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{"name" => "OPERATOR_NAME", "value" => "tekton-operator"},
                  %{
                    "name" => "IMAGE_PIPELINES_PROXY",
                    "value" =>
                      "gcr.io/tekton-releases/github.com/tektoncd/operator/cmd/kubernetes/proxy-webhook:v0.62.0@sha256:3c079de954e7a8c56fea86ba064b436d4a668da68f034b26d498d4197b4448f7"
                  },
                  %{
                    "name" => "IMAGE_JOB_PRUNER_TKN",
                    "value" =>
                      "gcr.io/tekton-releases/dogfooding/tkn@sha256:025de221fb059ca24a3b2d988889ea34bce48dc76c0cf0d6b4499edb8c21325f"
                  },
                  %{"name" => "METRICS_DOMAIN", "value" => "tekton.dev/operator"},
                  %{"name" => "VERSION", "value" => "devel"},
                  %{
                    "name" => "CONFIG_OBSERVABILITY_NAME",
                    "value" => "tekton-config-observability"
                  },
                  %{
                    "name" => "AUTOINSTALL_COMPONENTS",
                    "valueFrom" => %{
                      "configMapKeyRef" => %{
                        "key" => "AUTOINSTALL_COMPONENTS",
                        "name" => "tekton-config-defaults"
                      }
                    }
                  },
                  %{
                    "name" => "DEFAULT_TARGET_NAMESPACE",
                    "valueFrom" => %{
                      "configMapKeyRef" => %{
                        "key" => "DEFAULT_TARGET_NAMESPACE",
                        "name" => "tekton-config-defaults"
                      }
                    }
                  }
                ],
                "image" =>
                  "gcr.io/tekton-releases/github.com/tektoncd/operator/cmd/kubernetes/operator:v0.62.0@sha256:7f9071864b49439de21eb0413ef4fe5773116b00db34b73214920c21e26fd640",
                "imagePullPolicy" => "Always",
                "name" => "tekton-operator-lifecycle"
              },
              %{
                "args" => [
                  "-controllers",
                  "tektoninstallerset",
                  "-unique-process-name",
                  "tekton-operator-cluster-operations"
                ],
                "env" => [
                  %{
                    "name" => "SYSTEM_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{"name" => "OPERATOR_NAME", "value" => "tekton-operator"},
                  %{"name" => "PROFILING_PORT", "value" => "9009"},
                  %{"name" => "VERSION", "value" => "devel"},
                  %{"name" => "METRICS_DOMAIN", "value" => "tekton.dev/operator"}
                ],
                "image" =>
                  "gcr.io/tekton-releases/github.com/tektoncd/operator/cmd/kubernetes/operator:v0.62.0@sha256:7f9071864b49439de21eb0413ef4fe5773116b00db34b73214920c21e26fd640",
                "imagePullPolicy" => "Always",
                "name" => "tekton-operator-cluster-operations"
              }
            ],
            "serviceAccountName" => "tekton-operator"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("tekton-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("version", "v0.62.0")
    |> B.spec(spec)
  end

  resource(:deployment_tekton_operator_webhook, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"name" => "tekton-operator-webhook"}})
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "tekton_operator",
              "battery/managed" => "true",
              "name" => "tekton-operator-webhook"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "env" => [
                  %{
                    "name" => "SYSTEM_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{"name" => "CONFIG_LOGGING_NAME", "value" => "config-logging"},
                  %{"name" => "WEBHOOK_SERVICE_NAME", "value" => "tekton-operator-webhook"},
                  %{"name" => "WEBHOOK_SECRET_NAME", "value" => "tekton-operator-webhook-certs"},
                  %{"name" => "METRICS_DOMAIN", "value" => "tekton.dev/operator"}
                ],
                "image" =>
                  "gcr.io/tekton-releases/github.com/tektoncd/operator/cmd/kubernetes/webhook:v0.62.0@sha256:af242fc4ca25235e64db10fb478031cb55d882cc1f783d4a5392d048605e5b35",
                "name" => "tekton-operator-webhook",
                "ports" => [%{"containerPort" => 8443, "name" => "https-webhook"}]
              }
            ],
            "serviceAccountName" => "tekton-operator"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("tekton-operator-webhook")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("version", "v0.62.0")
    |> B.spec(spec)
  end

  resource(:role_binding_tekton_operator_info, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:role_binding)
    |> B.name("tekton-operator-info")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_role_ref("tekton-operator-info"))
    |> B.subject(B.build_group("system:authenticated", "default"))
  end

  resource(:role_tekton_operator_info, battery, _state) do
    namespace = Settings.namespace(battery.config)

    rules = [
      %{
        "apiGroups" => [""],
        "resourceNames" => ["tekton-operator-info"],
        "resources" => ["configmaps"],
        "verbs" => ["get"]
      }
    ]

    B.build_resource(:role)
    |> B.name("tekton-operator-info")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  resource(:secret_tekton_operator_webhook_certs, battery, _state) do
    namespace = Settings.namespace(battery.config)
    data = %{}

    B.build_resource(:secret)
    |> B.name("tekton-operator-webhook-certs")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "tekton-operator")
    |> B.label("name", "tekton-operator-webhook")
    |> B.data(data)
  end

  resource(:service_account_tekton_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_account)
    |> B.name("tekton-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  resource(:service_tekton_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 9090, "protocol" => "TCP", "targetPort" => 9090}
      ])
      |> Map.put("selector", %{"battery/app" => "tekton_operator", "name" => "tekton-operator"})

    B.build_resource(:service)
    |> B.name("tekton-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "tekton-pipelines-controller")
    |> B.label("version", "v0.62.0")
    |> B.spec(spec)
  end

  resource(:service_tekton_operator_webhook, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec =
      %{}
      |> Map.put("ports", [%{"name" => "https-webhook", "port" => 443, "targetPort" => 8443}])
      |> Map.put(
        "selector",
        %{"battery/app" => "tekton_operator", "name" => "tekton-operator-webhook"}
      )

    B.build_resource(:service)
    |> B.name("tekton-operator-webhook")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "tekton-operator")
    |> B.label("name", "tekton-operator-webhook")
    |> B.label("version", "devel")
    |> B.spec(spec)
  end
end
