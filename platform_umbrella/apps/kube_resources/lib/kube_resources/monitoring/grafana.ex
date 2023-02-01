defmodule KubeResources.Grafana do
  use CommonCore.IncludeResource,
    provider_yaml: "priv/raw_files/grafana/provider.yaml"

  use KubeExt.ResourceGenerator, app_name: "grafana"

  import CommonCore.SystemState.Namespaces
  import CommonCore.SystemState.Hosts

  alias KubeResources.IstioConfig.VirtualService
  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeExt.Secret
  alias KubeResources.IniConfig

  resource(:cluster_role_binding_clusterrolebinding, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("grafana-clusterrolebinding")
    |> B.role_ref(B.build_cluster_role_ref("grafana-clusterrole"))
    |> B.subject(B.build_service_account("grafana", namespace))
  end

  resource(:cluster_role_clusterrole) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "secrets"],
        "verbs" => ["get", "watch", "list"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("grafana-clusterrole")
    |> B.rules(rules)
  end

  resource(:config_map_dashboards, _battery, state) do
    namespace = core_namespace(state)
    data = %{"provider.yaml" => get_resource(:provider_yaml)}

    B.build_resource(:config_map)
    |> B.name("grafana-config-dashboards")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  def config_contents(_battery, state) do
    %{
      "server" => %{
        "domain" => grafana_host(state),
        "root_url" => "http://#{grafana_host(state)}/"
      },
      "auth" => %{"oauth_auto_login" => true},
      "auth.generic_oauth" => %{
        "name" => "Batteries Included",
        "icon" => "signin",
        "enabled" => true,
        "scopes" => "openid offline offline_access profile email",
        "api_url" => "http://ory-hydra-public:4444/userinfo",
        "token_url" => "http://ory-hydra-public:4444/oauth2/token",
        "auth_url" => "http://#{hydra_host(state)}/oauth2/auth"
      },
      "security" => %{"allow_embedding" => true},
      "users" => %{
        "viewers_can_edit" => true,
        "auto_assign_org_role" => "Admin"
      },
      "analytics" => %{"reporting_enabled" => true},
      "log" => %{
        "filters" => "oauth.generic_oauth:debug",
        "mode" => "console",
        "info" => "trace"
      },
      "paths" => %{
        "data" => "/var/lib/grafana/",
        "logs" => "/var/log/grafana",
        "plugins" => "/var/lib/grafana/plugins",
        "provisioning" => "/etc/grafana/provisioning"
      }
    }
  end

  resource(:config_map_main, battery, state) do
    namespace = core_namespace(state)
    data = %{"grafana.ini" => IniConfig.to_ini(config_contents(battery, state))}

    B.build_resource(:config_map)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:oauth_client, _battery, state) do
    namespace = core_namespace(state)

    spec = %{
      "grantTypes" => [
        "authorization_code",
        "refresh_token",
        "implicit"
      ],
      "responseTypes" => ["token", "id_token", "code"],
      "scope" => "openid offline offline_access profile email",
      "secretName" => "grafana.oauth2-client",
      "redirectUris" => ["http://#{grafana_host(state)}/login/generic_oauth"]
    }

    B.build_resource(:ory_oauth_client)
    |> B.name("grafana-client")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end

  resource(:deployment_main, battery, state) do
    namespace = core_namespace(state)

    template = %{
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "env" => [
              %{"name" => "METHOD", "value" => "WATCH"},
              %{"name" => "LABEL", "value" => "grafana_alert"},
              %{"name" => "FOLDER", "value" => "/etc/grafana/provisioning/alerting"},
              %{"name" => "RESOURCE", "value" => "both"},
              %{
                "name" => "REQ_USERNAME",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-user", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-password", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_URL",
                "value" => "http://localhost:3000/api/admin/provisioning/alerting/reload"
              },
              %{"name" => "REQ_METHOD", "value" => "POST"}
            ],
            "image" => battery.config.sidecar_image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "grafana-sc-alerts",
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/grafana/provisioning/alerting",
                "name" => "sc-alerts-volume"
              }
            ]
          },
          %{
            "env" => [
              %{"name" => "METHOD", "value" => "WATCH"},
              %{"name" => "LABEL", "value" => "grafana_dashboard"},
              %{"name" => "FOLDER", "value" => "/tmp/dashboards/"},
              %{"name" => "RESOURCE", "value" => "both"},
              %{"name" => "FOLDER_ANNOTATION", "value" => "grafana_folder"},
              %{
                "name" => "REQ_USERNAME",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-user", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-password", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_URL",
                "value" => "http://localhost:3000/api/admin/provisioning/dashboards/reload"
              },
              %{"name" => "REQ_METHOD", "value" => "POST"}
            ],
            "image" => battery.config.sidecar_image,
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
              %{"name" => "FOLDER", "value" => "/etc/grafana/provisioning/datasources"},
              %{"name" => "RESOURCE", "value" => "both"},
              %{
                "name" => "REQ_USERNAME",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-user", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-password", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_URL",
                "value" => "http://localhost:3000/api/admin/provisioning/datasources/reload"
              },
              %{"name" => "REQ_METHOD", "value" => "POST"}
            ],
            "image" => battery.config.sidecar_image,
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
              %{"name" => "METHOD", "value" => "WATCH"},
              %{"name" => "LABEL", "value" => "grafana_notifier"},
              %{"name" => "FOLDER", "value" => "/etc/grafana/provisioning/notifiers"},
              %{"name" => "RESOURCE", "value" => "both"},
              %{
                "name" => "REQ_USERNAME",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-user", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-password", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_URL",
                "value" => "http://localhost:3000/api/admin/provisioning/notifications/reload"
              },
              %{"name" => "REQ_METHOD", "value" => "POST"}
            ],
            "image" => battery.config.sidecar_image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "grafana-sc-notifiers",
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/grafana/provisioning/notifiers",
                "name" => "sc-notifiers-volume"
              }
            ]
          },
          %{
            "env" => [
              %{"name" => "METHOD", "value" => "WATCH"},
              %{"name" => "LABEL", "value" => "grafana_plugin"},
              %{"name" => "FOLDER", "value" => "/etc/grafana/provisioning/plugins"},
              %{"name" => "RESOURCE", "value" => "both"},
              %{
                "name" => "REQ_USERNAME",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-user", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-password", "name" => "grafana"}
                }
              },
              %{
                "name" => "REQ_URL",
                "value" => "http://localhost:3000/api/admin/provisioning/plugins/reload"
              },
              %{"name" => "REQ_METHOD", "value" => "POST"}
            ],
            "image" => battery.config.sidecar_image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "grafana-sc-plugins",
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/grafana/provisioning/plugins",
                "name" => "sc-plugins-volume"
              }
            ]
          },
          %{
            "env" => [
              %{
                "name" => "GF_SECURITY_ADMIN_USER",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-user", "name" => "grafana"}
                }
              },
              %{
                "name" => "GF_SECURITY_ADMIN_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "admin-password", "name" => "grafana"}
                }
              },

              # Oauth
              %{
                "name" => "GF_AUTH_GENERIC_OAUTH_CLIENT_ID",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "client_id",
                    "name" => "grafana.oauth2-client"
                  }
                }
              },
              %{
                "name" => "GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "client_secret",
                    "name" => "grafana.oauth2-client"
                  }
                }
              },
              %{"name" => "GF_PATHS_DATA", "value" => "/var/lib/grafana/"},
              %{"name" => "GF_PATHS_LOGS", "value" => "/var/log/grafana"},
              %{"name" => "GF_PATHS_PLUGINS", "value" => "/var/lib/grafana/plugins"},
              %{"name" => "GF_PATHS_PROVISIONING", "value" => "/etc/grafana/provisioning"}
            ],
            "image" => battery.config.image,
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
              %{
                "mountPath" => "/etc/grafana/provisioning/alerting",
                "name" => "sc-alerts-volume"
              },
              %{"mountPath" => "/tmp/dashboards", "name" => "sc-dashboard-volume"},
              %{
                "mountPath" => "/etc/grafana/provisioning/dashboards/sc-dashboardproviders.yaml",
                "name" => "sc-dashboard-provider",
                "subPath" => "provider.yaml"
              },
              %{
                "mountPath" => "/etc/grafana/provisioning/datasources",
                "name" => "sc-datasources-volume"
              },
              %{
                "mountPath" => "/etc/grafana/provisioning/plugins",
                "name" => "sc-plugins-volume"
              },
              %{
                "mountPath" => "/etc/grafana/provisioning/notifiers",
                "name" => "sc-notifiers-volume"
              }
            ]
          }
        ],
        "enableServiceLinks" => true,
        "securityContext" => %{"fsGroup" => 472, "runAsGroup" => 472, "runAsUser" => 472},
        "serviceAccountName" => "grafana",
        "volumes" => [
          %{"configMap" => %{"name" => "grafana"}, "name" => "config"},
          %{"emptyDir" => %{}, "name" => "storage"},
          %{"emptyDir" => %{}, "name" => "sc-alerts-volume"},
          %{"emptyDir" => %{}, "name" => "sc-dashboard-volume"},
          %{
            "configMap" => %{"name" => "grafana-config-dashboards"},
            "name" => "sc-dashboard-provider"
          },
          %{"emptyDir" => %{}, "name" => "sc-datasources-volume"},
          %{"emptyDir" => %{}, "name" => "sc-plugins-volume"},
          %{"emptyDir" => %{}, "name" => "sc-notifiers-volume"}
        ]
      }
    }

    spec =
      %{}
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )
      |> Map.put("strategy", %{"type" => "RollingUpdate"})
      |> Map.put("template", template)

    B.build_resource(:deployment)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:horizontal_pod_autoscaler_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("maxReplicas", 5)
      |> Map.put("metrics", [
        %{
          "resource" => %{
            "name" => "cpu",
            "target" => %{"averageUtilization" => 80, "type" => "Utilization"}
          },
          "type" => "Resource"
        }
      ])
      |> Map.put("minReplicas", 1)
      |> Map.put(
        "scaleTargetRef",
        %{"apiVersion" => "apps/v1", "kind" => "Deployment", "name" => "grafana"}
      )

    B.build_resource(:horizontal_pod_autoscaler)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "honorLabels" => true,
          "interval" => "1m",
          "path" => "/metrics",
          "port" => "service",
          "scheme" => "http",
          "scrapeTimeout" => "30s"
        }
      ])
      |> Map.put("jobLabel", "grafana")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )

    B.build_resource(:monitoring_service_monitor)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:role_binding_main, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("grafana"))
    |> B.subject(B.build_service_account("grafana", namespace))
  end

  resource(:role_main, _battery, state) do
    namespace = core_namespace(state)

    rules = [
      %{
        "apiGroups" => ["extensions"],
        "resourceNames" => ["grafana"],
        "resources" => ["podsecuritypolicies"],
        "verbs" => ["use"]
      }
    ]

    B.build_resource(:role)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:secret_main, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("admin-password", "BWdlY6kXzvwrelwWyXjArb4Yk0CxFIS8iBPbltvb")
      |> Map.put("admin-user", "admin")
      |> Map.put("ldap-toml", "")
      |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_account_main, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("grafana")
    |> B.namespace(namespace)
  end

  resource(:service_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "service", "port" => 80, "protocol" => "TCP", "targetPort" => 3000}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("grafana", hosts: [grafana_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end
end
