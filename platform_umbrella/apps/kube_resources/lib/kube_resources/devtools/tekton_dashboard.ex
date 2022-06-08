defmodule KubeResources.TektonDashboard do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeResources.DevtoolsSettings
  alias KubeResources.IstioConfig.VirtualService
  alias KubeExt.KubeState.Hosts

  @app "tekton-dashboard"

  @service_account "tekton-dashboard"
  @service_name "tekton-dashboard"
  @info_role "tekton-dashboard-info"
  @tenant_cluster_role "battery-tekton-dashboard-tenant"
  @backend_cluster_role "battery-tekton-dashboard-backend"

  @info_configmap "tekton-dashboard-config-info"

  @url_base "/x/tekton_dashboard/"
  @iframe_base_url "/services/devtools/tekton_dashboard"

  def virtual_service(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("tekton-dashboard-http")
    |> B.spec(VirtualService.rewriting(@url_base, @service_name))
  end

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: iframe_url()

  def url, do: "//#{Hosts.control_host()}#{@url_base}"

  def iframe_url, do: @iframe_base_url

  def service_account(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name(@service_account)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def role(config) do
    namespace = DevtoolsSettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          @info_configmap
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "get"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.name(@info_role)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def cluster_role(_config) do
    rules = [
      %{
        "apiGroups" => [
          "apiextensions.k8s.io"
        ],
        "resources" => [
          "customresourcedefinitions"
        ],
        "verbs" => [
          "get",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          "security.openshift.io"
        ],
        "resources" => [
          "securitycontextconstraints"
        ],
        "verbs" => [
          "use"
        ]
      },
      %{
        "apiGroups" => [
          "tekton.dev"
        ],
        "resources" => [
          "clustertasks",
          "clustertasks/status"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "triggers.tekton.dev"
        ],
        "resources" => [
          "clusterinterceptors",
          "clustertriggerbindings"
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
          "serviceaccounts"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "dashboard.tekton.dev"
        ],
        "resources" => [
          "extensions"
        ],
        "verbs" => [
          "create",
          "update",
          "delete",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "tekton.dev"
        ],
        "resources" => [
          "clustertasks",
          "clustertasks/status"
        ],
        "verbs" => [
          "create",
          "update",
          "delete",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "triggers.tekton.dev"
        ],
        "resources" => [
          "clusterinterceptors",
          "clustertriggerbindings"
        ],
        "verbs" => [
          "create",
          "update",
          "delete",
          "patch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@backend_cluster_role)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def cluster_role_1(_config) do
    rules = [
      %{
        "apiGroups" => [
          "dashboard.tekton.dev"
        ],
        "resources" => [
          "extensions"
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
          "events",
          "namespaces",
          "pods",
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
          "tekton.dev"
        ],
        "resources" => [
          "tasks",
          "taskruns",
          "pipelines",
          "pipelineruns",
          "pipelineresources",
          "conditions",
          "tasks/status",
          "taskruns/status",
          "pipelines/status",
          "pipelineruns/status",
          "taskruns/finalizers",
          "pipelineruns/finalizers"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "triggers.tekton.dev"
        ],
        "resources" => [
          "eventlisteners",
          "triggerbindings",
          "triggers",
          "triggertemplates"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "tekton.dev"
        ],
        "resources" => [
          "tasks",
          "taskruns",
          "pipelines",
          "pipelineruns",
          "pipelineresources",
          "conditions",
          "taskruns/finalizers",
          "pipelineruns/finalizers",
          "tasks/status",
          "taskruns/status",
          "pipelines/status",
          "pipelineruns/status"
        ],
        "verbs" => [
          "create",
          "update",
          "delete",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "triggers.tekton.dev"
        ],
        "resources" => [
          "eventlisteners",
          "triggerbindings",
          "triggers",
          "triggertemplates"
        ],
        "verbs" => [
          "create",
          "update",
          "delete",
          "patch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@tenant_cluster_role)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def role_binding(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name(@info_role)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@info_role))
    |> B.subject(%{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "Group",
      "name" => "system:authenticated"
    })
  end

  def cluster_role_binding(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@backend_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@backend_cluster_role))
    |> B.subject(B.build_service_account(@service_account, namespace))
  end

  def cluster_role_binding_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@tenant_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@tenant_cluster_role))
    |> B.subject(B.build_service_account(@service_account, namespace))
  end

  def config_map(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "version" => "v0.26.0"
    }

    B.build_resource(:config_map)
    |> B.name(@info_configmap)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  def service(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "ports" => [
        %{
          "name" => "http",
          "port" => 9097,
          "protocol" => "TCP",
          "targetPort" => 9097
        }
      ],
      "selector" => %{
        "battery/app" => "tekton-dashboard"
      }
    }

    B.build_resource(:service)
    |> B.name(@service_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def deployment(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "tekton-dashboard"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "tekton-dashboard",
            "battery/managed" => "true"
          },
          "name" => "tekton-dashboard"
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "--port=9097",
                "--logout-url=",
                "--pipelines-namespace=#{namespace}",
                "--triggers-namespace=#{namespace}",
                "--read-only=false",
                "--log-level=info",
                "--log-format=json",
                "--namespace=",
                "--stream-logs=true",
                "--external-logs="
              ],
              "env" => [
                %{
                  "name" => "INSTALLED_NAMESPACE",
                  "valueFrom" => %{
                    "fieldRef" => %{
                      "fieldPath" => "metadata.namespace"
                    }
                  }
                }
              ],
              "image" =>
                "gcr.io/tekton-releases/github.com/tektoncd/dashboard/cmd/dashboard:v0.26.0@sha256:d3963622f12448e566e3d4afb27f9b47e71d8fd8b38bab7edbbacbb9c75e331e",
              "livenessProbe" => %{
                "httpGet" => %{
                  "path" => "/health",
                  "port" => 9097
                }
              },
              "name" => "tekton-dashboard",
              "ports" => [
                %{
                  "containerPort" => 9097
                }
              ],
              "readinessProbe" => %{
                "httpGet" => %{
                  "path" => "/readiness",
                  "port" => 9097
                }
              }
            }
          ],
          "nodeSelector" => %{
            "kubernetes.io/os" => "linux"
          },
          "securityContext" => %{
            "runAsNonRoot" => true,
            "runAsUser" => 65_532
          },
          "serviceAccountName" => @service_account,
          "volumes" => []
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("tekton-dashboard")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def materialize(config) do
    %{
      "/0/service_account" => service_account(config),
      "/1/role" => role(config),
      "/2/cluster_role" => cluster_role(config),
      "/3/cluster_role_1" => cluster_role_1(config),
      "/4/role_binding" => role_binding(config),
      "/5/cluster_role_binding" => cluster_role_binding(config),
      "/6/config_map" => config_map(config),
      "/7/service" => service(config),
      "/8/deployment" => deployment(config),
      "/9/cluster_role_binding_1" => cluster_role_binding_1(config)
    }
  end
end
