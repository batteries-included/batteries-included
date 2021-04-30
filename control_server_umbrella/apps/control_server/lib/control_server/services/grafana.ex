defmodule ControlServer.Services.Grafana do
  @moduledoc """
  Add on context for Grafana configuration.
  """

  alias ControlServer.Services.MonitoringSettings

  @datasources_configmap "battery-grafana-datasources"
  @dashboards_configmap "battery-grafana-dashboards"

  def service_account(config) do
    account = MonitoringSettings.grafana_name(config)
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => account,
        "namespace" => namespace
      }
    }
  end

  def prometheus_datasource_config(config) do
    prometheus_name = MonitoringSettings.prometheus_name(config)
    namespace = MonitoringSettings.namespace(config)

    {:ok, file_contents} =
      Jason.encode(%{
        "apiVersion" => 1,
        "datasources" => [
          %{
            "access" => "proxy",
            "editable" => false,
            "name" => prometheus_name,
            "orgId" => 1,
            "type" => "prometheus",
            "url" => "http://#{prometheus_name}.#{namespace}.svc:9090",
            "version" => 1
          }
        ]
      })

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{"name" => @datasources_configmap, "namespace" => namespace},
      "data" => %{
        "datasources.json" => file_contents
      }
    }
  end

  def dashboard_sources_config(config) do
    namespace = MonitoringSettings.namespace(config)

    {:ok, file_contents} =
      Jason.encode(%{
        "apiVersion" => 1,
        "providers" => [
          %{
            "folder" => "Default",
            "name" => "0",
            "options" => %{
              "path" => "/grafana-dashboard-definitions/0"
            },
            "orgId" => 1,
            "type" => "file"
          }
        ]
      })

    %{
      "apiVersion" => "v1",
      "data" => %{
        "dashboards.json": file_contents
      },
      "kind" => "ConfigMap",
      "metadata" => %{
        "name" => @dashboards_configmap,
        "namespace" => namespace
      }
    }
  end

  def deployment(config) do
    namespace = MonitoringSettings.namespace(config)
    name = MonitoringSettings.grafana_name(config)
    image = MonitoringSettings.grafana_image(config)
    version = MonitoringSettings.grafana_version(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app" => name
        },
        "name" => name,
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app" => name
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app" => name
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "env" => [],
                "image" => "#{image}:#{version}",
                "name" => name,
                "ports" => [
                  %{
                    "containerPort" => 3000,
                    "name" => "http"
                  }
                ],
                "readinessProbe" => %{
                  "httpGet" => %{
                    "path" => "/api/health",
                    "port" => "http"
                  }
                },
                "resources" => %{
                  "limits" => %{
                    "cpu" => "200m",
                    "memory" => "200Mi"
                  },
                  "requests" => %{
                    "cpu" => "100m",
                    "memory" => "100Mi"
                  }
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/var/lib/grafana",
                    "name" => "grafana-storage",
                    "readOnly" => false
                  },
                  %{
                    "mountPath" => "/etc/grafana/provisioning/datasources",
                    "name" => @datasources_configmap,
                    "readOnly" => false
                  },
                  %{
                    "mountPath" => "/etc/grafana/provisioning/dashboards",
                    "name" => @dashboards_configmap,
                    "readOnly" => false
                  }
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/apiserver",
                  #     "name" => "grafana-dashboard-apiserver",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/cluster-total",
                  #     "name" => "grafana-dashboard-cluster-total",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/controller-manager",
                  #     "name" => "grafana-dashboard-controller-manager",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/k8s-resources-cluster",
                  #     "name" => "grafana-dashboard-k8s-resources-cluster",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/k8s-resources-namespace",
                  #     "name" => "grafana-dashboard-k8s-resources-namespace",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/k8s-resources-node",
                  #     "name" => "grafana-dashboard-k8s-resources-node",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/k8s-resources-pod",
                  #     "name" => "grafana-dashboard-k8s-resources-pod",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/k8s-resources-workload",
                  #     "name" => "grafana-dashboard-k8s-resources-workload",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/k8s-resources-workloads-namespace",
                  #     "name" => "grafana-dashboard-k8s-resources-workloads-namespace",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/kubelet",
                  #     "name" => "grafana-dashboard-kubelet",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/namespace-by-pod",
                  #     "name" => "grafana-dashboard-namespace-by-pod",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/namespace-by-workload",
                  #     "name" => "grafana-dashboard-namespace-by-workload",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/node-cluster-rsrc-use",
                  #     "name" => "grafana-dashboard-node-cluster-rsrc-use",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/node-rsrc-use",
                  #     "name" => "grafana-dashboard-node-rsrc-use",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/nodes",
                  #     "name" => "grafana-dashboard-nodes",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/persistentvolumesusage",
                  #     "name" => "grafana-dashboard-persistentvolumesusage",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/pod-total",
                  #     "name" => "grafana-dashboard-pod-total",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/prometheus-remote-write",
                  #     "name" => "grafana-dashboard-prometheus-remote-write",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/prometheus",
                  #     "name" => "grafana-dashboard-prometheus",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/proxy",
                  #     "name" => "grafana-dashboard-proxy",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/scheduler",
                  #     "name" => "grafana-dashboard-scheduler",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/statefulset",
                  #     "name" => "grafana-dashboard-statefulset",
                  #     "readOnly" => false
                  # },
                  # %{
                  #     "mountPath" => "/grafana-dashboard-definitions/0/workload-total",
                  #     "name" => "grafana-dashboard-workload-total",
                  #     "readOnly" => false
                  # }
                ]
              }
            ],
            "nodeSelector" => %{
              "beta.kubernetes.io/os": "linux"
            },
            "securityContext" => %{
              "runAsNonRoot" => true,
              "runAsUser" => 65_534
            },
            "serviceAccountName" => name,
            "volumes" => [
              %{
                "emptyDir" => %{},
                "name" => "grafana-storage"
              },
              %{
                "name" => @datasources_configmap,
                "configMap" => %{
                  "name" => @datasources_configmap
                }
              },
              %{
                "configMap" => %{
                  "name" => @dashboards_configmap
                },
                "name" => @dashboards_configmap
              }
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-apiserver"
              #     },
              #     "name" => "grafana-dashboard-apiserver"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-cluster-total"
              #     },
              #     "name" => "grafana-dashboard-cluster-total"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-controller-manager"
              #     },
              #     "name" => "grafana-dashboard-controller-manager"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-k8s-resources-cluster"
              #     },
              #     "name" => "grafana-dashboard-k8s-resources-cluster"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-k8s-resources-namespace"
              #     },
              #     "name" => "grafana-dashboard-k8s-resources-namespace"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-k8s-resources-node"
              #     },
              #     "name" => "grafana-dashboard-k8s-resources-node"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-k8s-resources-pod"
              #     },
              #     "name" => "grafana-dashboard-k8s-resources-pod"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-k8s-resources-workload"
              #     },
              #     "name" => "grafana-dashboard-k8s-resources-workload"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-k8s-resources-workloads-namespace"
              #     },
              #     "name" => "grafana-dashboard-k8s-resources-workloads-namespace"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-kubelet"
              #     },
              #     "name" => "grafana-dashboard-kubelet"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-namespace-by-pod"
              #     },
              #     "name" => "grafana-dashboard-namespace-by-pod"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-namespace-by-workload"
              #     },
              #     "name" => "grafana-dashboard-namespace-by-workload"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-node-cluster-rsrc-use"
              #     },
              #     "name" => "grafana-dashboard-node-cluster-rsrc-use"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-node-rsrc-use"
              #     },
              #     "name" => "grafana-dashboard-node-rsrc-use"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-nodes"
              #     },
              #     "name" => "grafana-dashboard-nodes"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-persistentvolumesusage"
              #     },
              #     "name" => "grafana-dashboard-persistentvolumesusage"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-pod-total"
              #     },
              #     "name" => "grafana-dashboard-pod-total"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-prometheus-remote-write"
              #     },
              #     "name" => "grafana-dashboard-prometheus-remote-write"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-prometheus"
              #     },
              #     "name" => "grafana-dashboard-prometheus"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-proxy"
              #     },
              #     "name" => "grafana-dashboard-proxy"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-scheduler"
              #     },
              #     "name" => "grafana-dashboard-scheduler"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-statefulset"
              #     },
              #     "name" => "grafana-dashboard-statefulset"
              # },
              # %{
              #     "configMap" => %{
              #         "name" => "grafana-dashboard-workload-total"
              #     },
              #     "name" => "grafana-dashboard-workload-total"
              # }
            ]
          }
        }
      }
    }
  end

  def service(config) do
    name = MonitoringSettings.grafana_name(config)
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => "http",
            "port" => 3000,
            "targetPort" => "http"
          }
        ],
        "selector" => %{
          "app" => name
        }
      }
    }
  end
end
