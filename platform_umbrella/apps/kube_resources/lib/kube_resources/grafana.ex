defmodule KubeResources.Grafana do
  @moduledoc """
  Add on context for Grafana configuration.
  """

  alias KubeExt.IniConfig
  alias KubeResources.MonitoringSettings

  @datasources_configmap "grafana-datasources"
  @dashboards_configmap "grafana-dashboards"
  @main_configmap "grafana-config"

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-grafana",
        "namespace" => namespace
      }
    }
  end

  def prometheus_datasource_config(config) do
    namespace = MonitoringSettings.namespace(config)

    file_contents =
      Ymlr.Encoder.to_s!(%{
        "apiVersion" => 1,
        "datasources" => [
          %{
            "access" => "proxy",
            "editable" => false,
            "name" => "battery-prometheus",
            "orgId" => 1,
            "type" => "prometheus",
            "url" => "http://prometheus.#{namespace}.svc:9090",
            "version" => 1
          }
        ]
      })

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{"name" => @datasources_configmap, "namespace" => namespace},
      "data" => %{
        "prometheus.json" => file_contents
      }
    }
  end

  def dashboard_sources_config(config) do
    namespace = MonitoringSettings.namespace(config)

    file_contents =
      Ymlr.Encoder.to_s!(%{
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

  def main_config(config) do
    namespace = MonitoringSettings.namespace(config)

    config = %{
      "server" => %{
        root_url: "/x/grafana",
        serve_from_sub_path: true
      },
      "auth.anonymous" => %{
        enabled: true
      },
      "security" => %{
        allow_embedding: true
      },
      "users" => %{default_theme: "light"},
      "analytics" => %{reporting_enabled: false},
      "log" => %{
        "mode" => "console",
        "info" => "debug"
      }
    }

    file_contents = IniConfig.to_ini(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{"name" => @main_configmap, "namespace" => namespace},
      "data" => %{
        "grafana.ini" => file_contents
      }
    }
  end

  def deployment(config) do
    namespace = MonitoringSettings.namespace(config)
    image = MonitoringSettings.grafana_image(config)
    version = MonitoringSettings.grafana_version(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "grafana"
        },
        "name" => "grafana",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "grafana"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "grafana"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "env" => [],
                "image" => "#{image}:#{version}",
                "name" => "grafana",
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
                    "mountPath" => "/etc/grafana/grafana.ini",
                    "subPath" => "grafana.ini",
                    "name" => @main_configmap,
                    "readOnly" => true
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
            "serviceAccountName" => "battery-grafana",
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
                "name" => @main_configmap,
                "configMap" => %{
                  "name" => @main_configmap
                }
              },
              %{
                "configMap" => %{
                  "name" => @dashboards_configmap
                },
                "name" => @dashboards_configmap
              }
            ]
          }
        }
      }
    }
  end

  def service(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => "grafana",
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
          "battery/app" => "grafana"
        }
      }
    }
  end
end
