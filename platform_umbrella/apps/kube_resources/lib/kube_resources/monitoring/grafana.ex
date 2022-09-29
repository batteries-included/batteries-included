defmodule KubeResources.Grafana do
  use KubeExt.IncludeResource,
    datasource_yaml: "priv/raw_files/prometheus_stack/datasource.yaml",
    provider_yaml: "priv/raw_files/prometheus_stack/provider.yaml",
    run_sh: "priv/raw_files/prometheus_stack/run.sh"

  use KubeExt.ResourceGenerator

  alias KubeResources.MonitoringSettings, as: Settings
  alias KubeExt.KubeState.Hosts
  alias KubeResources.IniConfig
  alias KubeResources.IstioConfig.VirtualService

  @app "grafana"
  @url_base "/x/grafana"

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: "/services/monitoring/grafana"

  def url, do: "http://#{Hosts.control_host()}#{@url_base}"

  def virtual_service(config) do
    namespace = Settings.namespace(config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("grafana")
    |> B.spec(VirtualService.prefix("/x/grafana", "battery-grafana"))
  end

  resource(:cluster_role_battery_grafana_clusterrole) do
    B.build_resource(:cluster_role)
    |> B.name("battery-grafana-clusterrole")
    |> B.app_labels(@app)
    |> B.rules([
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "secrets"],
        "verbs" => ["get", "watch", "list"]
      }
    ])
  end

  resource(:cluster_role_binding_battery_grafana_clusterrolebinding, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-grafana-clusterrolebinding")
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref("battery-grafana-clusterrole"))
    |> B.subject(B.build_service_account("battery-grafana", namespace))
  end

  resource(:config_map_battery_grafana, config) do
    namespace = Settings.namespace(config)

    config = %{
      "server" => %{
        root_url: @url_base,
        serve_from_sub_path: true
      },
      "auth.anonymous" => %{
        enabled: true
      },
      "security" => %{
        allow_embedding: true
      },
      "users" => %{default_theme: "light", viewers_can_edit: true},
      "analytics" => %{reporting_enabled: false},
      "log" => %{
        "mode" => "console",
        "format" => "json",
        "info" => "debug"
      }
    }

    file_contents = IniConfig.to_ini(config)

    data = %{"grafana.ini" => file_contents}

    B.build_resource(:config_map)
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  resource(:config_map_grafana_datasource, config) do
    namespace = Settings.namespace(config)
    data = %{"datasource.yaml" => get_resource(:datasource_yaml)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-grafana-datasource")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_datasource", "1")
    |> B.data(data)
  end

  resource(:config_map_battery_grafana_test, config) do
    namespace = Settings.namespace(config)
    data = %{"run.sh" => get_resource(:run_sh)}

    B.build_resource(:config_map)
    |> B.name("battery-grafana-test")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  resource(:config_map_battery_grafana_dashboards, config) do
    namespace = Settings.namespace(config)
    data = %{"provider.yaml" => get_resource(:provider_yaml)}

    B.build_resource(:config_map)
    |> B.name("battery-grafana-config-dashboards")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  resource(:deployment_battery_grafana, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:deployment)
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "replicas" => 1,
      "revisionHistoryLimit" => 10,
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app}
      },
      "strategy" => %{"type" => "RollingUpdate"},
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app,
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "automountServiceAccountToken" => true,
          "containers" => [
            %{
              "env" => [
                %{"name" => "METHOD", "value" => "WATCH"},
                %{"name" => "LABEL", "value" => "grafana_dashboard"},
                %{"name" => "LABEL_VALUE", "value" => "1"},
                %{"name" => "FOLDER", "value" => "/tmp/dashboards"},
                %{"name" => "RESOURCE", "value" => "both"}
              ],
              "image" => "quay.io/kiwigrid/k8s-sidecar:1.19.2",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "grafana-sc-dashboard",
              "volumeMounts" => [
                %{"mountPath" => "/tmp/dashboards", "name" => "sc-dashboard-volume"}
              ]
            },
            %{
              "env" => [
                %{"name" => "METHOD", "value" => "WATCH"},
                %{"name" => "LABEL", "value" => "grafana_datasource"},
                %{"name" => "LABEL_VALUE", "value" => "1"},
                %{"name" => "FOLDER", "value" => "/etc/grafana/provisioning/datasources"},
                %{"name" => "RESOURCE", "value" => "both"},
                %{
                  "name" => "REQ_USERNAME",
                  "valueFrom" => %{
                    "secretKeyRef" => %{"key" => "admin-user", "name" => "battery-grafana"}
                  }
                },
                %{
                  "name" => "REQ_PASSWORD",
                  "valueFrom" => %{
                    "secretKeyRef" => %{"key" => "admin-password", "name" => "battery-grafana"}
                  }
                },
                %{
                  "name" => "REQ_URL",
                  "value" => "http://localhost:3000/api/admin/provisioning/datasources/reload"
                },
                %{"name" => "REQ_METHOD", "value" => "POST"}
              ],
              "image" => "quay.io/kiwigrid/k8s-sidecar:1.19.2",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "grafana-sc-datasources",
              "volumeMounts" => [
                %{
                  "mountPath" => "/etc/grafana/provisioning/datasources",
                  "name" => "sc-datasources-volume"
                }
              ]
            },
            %{
              "env" => [
                %{
                  "name" => "GF_SECURITY_ADMIN_USER",
                  "valueFrom" => %{
                    "secretKeyRef" => %{"key" => "admin-user", "name" => "battery-grafana"}
                  }
                },
                %{
                  "name" => "GF_SECURITY_ADMIN_PASSWORD",
                  "valueFrom" => %{
                    "secretKeyRef" => %{"key" => "admin-password", "name" => "battery-grafana"}
                  }
                },
                %{"name" => "GF_PATHS_DATA", "value" => "/var/lib/grafana/"},
                %{"name" => "GF_PATHS_LOGS", "value" => "/var/log/grafana"},
                %{"name" => "GF_PATHS_PLUGINS", "value" => "/var/lib/grafana/plugins"},
                %{"name" => "GF_PATHS_PROVISIONING", "value" => "/etc/grafana/provisioning"}
              ],
              "image" => "grafana/grafana:9.1.4",
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "failureThreshold" => 10,
                "httpGet" => %{"path" => "/api/health", "port" => 3000},
                "initialDelaySeconds" => 60,
                "timeoutSeconds" => 30
              },
              "name" => "grafana",
              "ports" => [%{"containerPort" => 3000, "name" => "grafana", "protocol" => "TCP"}],
              "readinessProbe" => %{"httpGet" => %{"path" => "/api/health", "port" => 3000}},
              "volumeMounts" => [
                %{
                  "mountPath" => "/etc/grafana/grafana.ini",
                  "name" => "config",
                  "subPath" => "grafana.ini"
                },
                %{"mountPath" => "/var/lib/grafana", "name" => "storage"},
                %{"mountPath" => "/tmp/dashboards", "name" => "sc-dashboard-volume"},
                %{
                  "mountPath" =>
                    "/etc/grafana/provisioning/dashboards/sc-dashboardproviders.yaml",
                  "name" => "sc-dashboard-provider",
                  "subPath" => "provider.yaml"
                },
                %{
                  "mountPath" => "/etc/grafana/provisioning/datasources",
                  "name" => "sc-datasources-volume"
                }
              ]
            }
          ],
          "enableServiceLinks" => true,
          "securityContext" => %{"fsGroup" => 472, "runAsGroup" => 472, "runAsUser" => 472},
          "serviceAccountName" => "battery-grafana",
          "volumes" => [
            %{"configMap" => %{"name" => "battery-grafana"}, "name" => "config"},
            %{"emptyDir" => %{}, "name" => "storage"},
            %{"emptyDir" => %{}, "name" => "sc-dashboard-volume"},
            %{
              "configMap" => %{"name" => "battery-grafana-config-dashboards"},
              "name" => "sc-dashboard-provider"
            },
            %{"emptyDir" => %{}, "name" => "sc-datasources-volume"}
          ]
        }
      }
    })
  end

  resource(:pod_battery_grafana_test, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:pod)
    |> B.name("battery-grafana-test")
    |> B.namespace(namespace)
    |> B.app_labels("grafana-test")
    |> B.spec(%{
      "containers" => [
        %{
          "command" => ["/opt/bats/bin/bats", "-t", "/tests/run.sh"],
          "image" => "bats/bats:v1.4.1",
          "imagePullPolicy" => "IfNotPresent",
          "name" => "battery-test",
          "volumeMounts" => [%{"mountPath" => "/tests", "name" => "tests", "readOnly" => true}]
        }
      ],
      "restartPolicy" => "Never",
      "serviceAccountName" => "battery-grafana-test",
      "volumes" => [%{"configMap" => %{"name" => "battery-grafana-test"}, "name" => "tests"}]
    })
  end

  resource(:role_battery_grafana, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:role)
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules([])
  end

  resource(:role_binding_battery_grafana, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_role_ref("battery-grafana"))
    |> B.subject(B.build_service_account("battery-grafana", namespace))
  end

  resource(:secret_battery_grafana, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:secret)
    |> Map.put(
      "data",
      %{"admin-password" => "cHJvbS1vcGVyYXRvcg==", "admin-user" => "YWRtaW4=", "ldap-toml" => ""}
    )
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  resource(:service_account_battery_grafana, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  resource(:service_account_battery_grafana_test, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("battery-grafana-test")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  resource(:service_battery_grafana, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service)
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "ports" => [
        %{"name" => "http-web", "port" => 80, "protocol" => "TCP", "targetPort" => 3000}
      ],
      "selector" => %{"battery/app" => @app},
      "type" => "ClusterIP"
    })
  end

  resource(:service_monitor_battery_grafana, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_monitor)
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "endpoints" => [
        %{
          "honorLabels" => true,
          "path" => "/metrics",
          "port" => "http-web",
          "scheme" => "http",
          "scrapeTimeout" => "30s"
        }
      ],
      "jobLabel" => "battery/app",
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app}
      }
    })
  end
end
