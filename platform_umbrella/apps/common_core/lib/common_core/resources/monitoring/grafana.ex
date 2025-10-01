defmodule CommonCore.Resources.Grafana do
  @moduledoc false
  use CommonCore.IncludeResource,
    provider_yaml: "priv/raw_files/grafana/provider.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "grafana"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.URLs

  alias CommonCore.INIConfig
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.RouteBuilder, as: R
  alias CommonCore.Resources.Secret
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.URLs

  require Logger

  @service_http_port 80

  resource(:cluster_role_binding_clusterrolebinding, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("grafana-clusterrolebinding")
    |> B.role_ref(B.build_cluster_role_ref("grafana-clusterrole"))
    |> B.subject(B.build_service_account(app_name(), namespace))
  end

  resource(:cluster_role_clusterrole) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps", "secrets"],
        "verbs" => ["get", "watch", "list"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("grafana-clusterrole")
    |> B.rules(rules)
  end

  resource(:config_map_dashboards, _battery, state) do
    namespace = core_namespace(state)
    data = %{"provider.yaml" => get_resource(:provider_yaml)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-config-dashboards")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  def config_contents(battery, state) do
    %{}
    |> add_common_config(battery, state)
    |> add_auth_config(battery, state)
  end

  defp add_common_config(config, battery, state) do
    config
    |> Map.put("server", %{
      "domain" => grafana_host(state),
      "root_url" => URLs.uri_for_battery(state, battery.type)
    })
    |> Map.put("security", %{"allow_embedding" => true})
    |> Map.put("users", %{
      "viewers_can_edit" => true,
      "auto_assign_org_role" => "Admin"
    })
    |> Map.put("analytics", %{"reporting_enabled" => false})
    |> Map.put("log", %{
      "mode" => "console",
      "info" => "debug"
    })
    |> Map.put("paths", %{
      "data" => "/var/lib/grafana/",
      "logs" => "/var/log/grafana",
      "plugins" => "/var/lib/grafana/plugins",
      "provisioning" => "/etc/grafana/provisioning"
    })
  end

  # https://web.archive.org/web/20230802094035/https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/
  # https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/
  defp add_auth_config(config, _battery, state) do
    if Batteries.sso_installed?(state) do
      case CommonCore.StateSummary.KeycloakSummary.client(state.keycloak_state, app_name()) do
        %{realm: realm, client: %{clientId: client_id, secret: client_secret}} ->
          keycloak_root_uri =
            state |> keycloak_uri_for_realm(realm) |> URI.append_path("/protocol/openid-connect")

          config
          |> Map.put("auth.generic_oauth", %{
            "allow_sign_up" => true,
            "enabled" => true,
            "icon" => "signin",
            "name" => "Batteries Included",

            # URLs
            "api_url" => keycloak_root_uri |> URI.append_path("/userinfo") |> URI.to_string(),
            "auth_url" => keycloak_root_uri |> URI.append_path("/auth") |> URI.to_string(),
            "token_url" => keycloak_root_uri |> URI.append_path("/token") |> URI.to_string(),

            # Client config
            "client_id" => client_id,
            "client_secret" => client_secret,
            "email_attribute_path" => "email",
            "login_attribute_path" => "username",
            "name_attribute_path" => "full_name",
            "role_attribute_path" =>
              "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'",
            "scopes" => "openid email profile offline_access roles"
          })
          |> Map.put("auth", %{"oauth_auto_login" => true})
          |> put_in(~w(log filters), "oauth.generic_oauth:debug")

        nil ->
          config
      end
    else
      Map.put(config, "auth.anonymous", %{"enabled" => true})
    end
  end

  resource(:config_map_main, battery, state) do
    namespace = core_namespace(state)
    data = %{"grafana.ini" => INIConfig.to_ini(config_contents(battery, state))}

    :config_map
    |> B.build_resource()
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:deployment_main, battery, state) do
    namespace = core_namespace(state)

    template =
      %{
        "metadata" => %{
          "labels" => %{
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "automountServiceAccountToken" => true,
          "containers" => [
            %{
              "env" => [
                %{"name" => "NAMESPACE", "value" => "ALL"},
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
                %{"name" => "NAMESPACE", "value" => "ALL"},
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
                %{"name" => "NAMESPACE", "value" => "ALL"},
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
                %{"name" => "NAMESPACE", "value" => "ALL"},
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
                %{"name" => "NAMESPACE", "value" => "ALL"},
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
            %{"configMap" => %{"name" => "grafana-config-dashboards"}, "name" => "sc-dashboard-provider"},
            %{"emptyDir" => %{}, "name" => "storage"},
            %{"emptyDir" => %{}, "name" => "sc-alerts-volume"},
            %{"emptyDir" => %{}, "name" => "sc-dashboard-volume"},
            %{"emptyDir" => %{}, "name" => "sc-datasources-volume"},
            %{"emptyDir" => %{}, "name" => "sc-plugins-volume"},
            %{"emptyDir" => %{}, "name" => "sc-notifiers-volume"}
          ]
        }
      }
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> Map.put("strategy", %{"type" => "RollingUpdate"})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.annotation("kubectl.kubernetes.io/default-container", @app_name)
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

    :horizontal_pod_autoscaler
    |> B.build_resource()
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
          "port" => "http",
          "scheme" => "http",
          "scrapeTimeout" => "30s"
        }
      ])
      |> Map.put("jobLabel", "grafana")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:role_binding_main, _battery, state) do
    namespace = core_namespace(state)

    :role_binding
    |> B.build_resource()
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

    :role
    |> B.build_resource()
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:secret_main, battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("admin-password", battery.config.admin_password)
      |> Map.put("admin-user", "admin")
      |> Map.put("ldap-toml", "")
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_account_main, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("grafana")
    |> B.namespace(namespace)
  end

  resource(:service_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"name" => "http", "port" => @service_http_port, "protocol" => "TCP", "targetPort" => 3000}])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.label("istio.io/ingress-use-waypoint", "true")
    |> B.spec(spec)
  end

  resource(:http_route, battery, state) do
    namespace = core_namespace(state)

    spec =
      battery
      |> R.new_httproute_spec(state)
      |> R.add_oauth2_proxy_rule(battery, state)
      |> R.add_backend("grafana", @service_http_port)

    :gateway_http_route
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
    |> F.require(R.valid?(spec))
  end
end
