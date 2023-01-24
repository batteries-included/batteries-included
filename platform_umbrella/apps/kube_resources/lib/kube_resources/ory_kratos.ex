defmodule KubeResources.OryKratos do
  use CommonCore.IncludeResource,
    identity_schema: "priv/raw_files/ory_kratos/batteriesincl.schema.json"

  use KubeExt.ResourceGenerator, app_name: "ory-kratos"

  import CommonCore.SystemState.Namespaces
  import CommonCore.SystemState.Hosts
  import CommonCore.Yaml

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeExt.Secret
  alias KubeResources.IstioConfig.VirtualService

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("ory-kratos-public", hosts: [kratos_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("kratos")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:virtual_service_admin, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("ory-kratos-admin", hosts: [kratos_admin_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("kratos-admin")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  defp config(battery, state) do
    base_namspace = base_namespace(state)

    %{
      "cookies" => %{
        "domain" => "ip.batteriesincl.com",
        "same_site" => "Lax"
      },
      "courier" => %{
        "smtp" => %{
          "connection_uri" =>
            "smtps://test:test@mailhog.#{base_namspace}.svc:1025/?skip_ssl_verify=true"
        }
      },
      "identity" => %{
        "default_schema_id" => "batteriesincl",
        "schemas" => [
          %{
            "id" => "batteriesincl",
            "url" => "file:///etc/config/batteriesincl.schema.json"
          }
        ]
      },
      "log" => %{
        "format" => "text",
        "leak_sensitive_values" => false,
        "level" => "debug"
      },
      "dev" => battery.config.dev,
      "sqa-opt-out" => true,
      "selfservice" => %{
        "allowed_return_urls" => ["http://control.127.0.0.1.ip.batteriesincl.com:4000/"],
        "default_browser_return_url" => "http://control.127.0.0.1.ip.batteriesincl.com:4000/",
        "methods" => %{
          "link" => %{"enabled" => false},
          "lookup_secret" => %{"enabled" => true},
          "password" => %{"enabled" => true},
          "totp" => %{
            "config" => %{"issuer" => "BatteriesIncluded"},
            "enabled" => true
          }
        },
        "flows" => %{
          "registration" => %{
            "ui_url" => "http://control.127.0.0.1.ip.batteriesincl.com:4000/auth/register"
          }
        }
      },
      "session" => %{
        "cookie" => %{
          "domain" => "ip.batteriesincl.com",
          "same_site" => "Lax"
        }
      },
      "serve" => %{
        "admin" => %{
          "port" => 4434,
          "host" => "0.0.0.0"
        },
        "public" => %{
          "port" => 4433,
          "base_url" => "http://#{kratos_host(state)}/",
          "host" => "0.0.0.0",
          "cors" => %{
            "enabled" => true,
            "allowed_origins" => [
              "http://*.ip.batteriesincl.com",
              "http://*.ip.batteriesincl.com:4000",
              "https://*.ip.batteriesincl.com"
            ],
            "allowed_methods" => ["POST", "GET", "PUT", "PATCH", "DELETE"],
            "allowed_headers" => ["Authorization", "Cookie", "Content-Type"],
            "exposed_headers" => ["Content-Type", "Set-Cookie"]
          }
        }
      }
    }
  end

  resource(:config_map_ory_kratos, battery, state) do
    namespace = core_namespace(state)

    data = %{
      "kratos.yaml" => to_yaml(config(battery, state)),
      "batteriesincl.schema.json" => get_resource(:identity_schema)
    }

    B.build_resource(:config_map)
    |> B.name("ory-kratos-config")
    |> B.namespace(namespace)
    |> B.component_label("kratos")
    |> B.data(data)
  end

  resource(:secret_ory_kratos, battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("secretsCipher", battery.config.secret_cipher)
      |> Map.put("secretsCookie", battery.config.secret_cookie)
      |> Map.put("secretsDefault", battery.config.secret_default)
      |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("ory-kratos")
    |> B.namespace(namespace)
    |> B.component_label("kratos")
    |> B.data(data)
  end

  resource(:service_account_ory_kratos, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("ory-kratos")
    |> B.component_label("kratos")
    |> B.namespace(namespace)
  end

  resource(:service_ory_kratos_courier, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 80, "protocol" => "TCP", "targetPort" => "http-public"}
      ])
      |> Map.put(
        "selector",
        %{"battery/app" => @app_name, "battery/component" => "courier"}
      )

    B.build_resource(:service)
    |> B.name("ory-kratos-courier")
    |> B.namespace(namespace)
    |> B.component_label("courier")
    |> B.spec(spec)
  end

  resource(:service_ory_kratos_public, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 80, "protocol" => "TCP", "targetPort" => "http-public"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "kratos"})

    B.build_resource(:service)
    |> B.name("ory-kratos-public")
    |> B.namespace(namespace)
    |> B.component_label("public")
    |> B.spec(spec)
  end

  resource(:service_ory_kratos_admin, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 80, "protocol" => "TCP", "targetPort" => "http-admin"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "kratos"})

    B.build_resource(:service)
    |> B.name("ory-kratos-admin")
    |> B.namespace(namespace)
    |> B.component_label("admin")
    |> B.spec(spec)
  end

  resource(:stateful_set_ory_kratos_courier, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "battery/component" => "courier"
          }
        }
      )
      |> Map.put("serviceName", "ory-kratos-courier")
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "annotations" => nil,
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => "courier",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => ["courier", "watch", "--config", "/etc/config/kratos.yaml"],
                "env" => [
                  %{"name" => "LOG_FORMAT", "value" => "json"},
                  %{"name" => "LOG_LEVEL", "value" => "trace"},
                  %{
                    "name" => "POSTGRES_USER",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "username",
                        "name" => "orykratos.pg-ory.credentials.postgresql",
                        "optional" => false
                      }
                    }
                  },
                  %{
                    "name" => "POSTGRES_PASSWORD",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "password",
                        "name" => "orykratos.pg-ory.credentials.postgresql",
                        "optional" => false
                      }
                    }
                  },
                  %{
                    "name" => "DSN",
                    "value" =>
                      "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@pg-ory.battery-base.svc/kratos?sslmode=prefer"
                  },
                  %{
                    "name" => "SECRETS_DEFAULT",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "secretsDefault",
                        "name" => "ory-kratos",
                        "optional" => true
                      }
                    }
                  },
                  %{
                    "name" => "SECRETS_COOKIE",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "secretsCookie",
                        "name" => "ory-kratos",
                        "optional" => true
                      }
                    }
                  },
                  %{
                    "name" => "SECRETS_CIPHER",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "secretsCipher",
                        "name" => "ory-kratos",
                        "optional" => true
                      }
                    }
                  }
                ],
                "image" => battery.config.image,
                "imagePullPolicy" => "IfNotPresent",
                "name" => "ory-kratos-courier",
                "resources" => nil,
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]},
                  "privileged" => false,
                  "readOnlyRootFilesystem" => true,
                  "runAsNonRoot" => true,
                  "runAsUser" => 100
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/etc/config",
                    "name" => "ory-kratos-config-volume",
                    "readOnly" => true
                  }
                ]
              }
            ],
            "serviceAccountName" => "ory-kratos",
            "volumes" => [
              %{
                "configMap" => %{"name" => "ory-kratos-config"},
                "name" => "ory-kratos-config-volume"
              }
            ]
          }
        }
      )

    B.build_resource(:stateful_set)
    |> B.name("ory-kratos-courier")
    |> B.namespace(namespace)
    |> B.component_label("courier")
    |> B.spec(spec)
  end

  resource(:deployment_ory_kratos, battery, state) do
    namespace = core_namespace(state)

    template = %{
      "metadata" => %{
        "annotations" => nil,
        "labels" => %{
          "battery/app" => @app_name,
          "battery/component" => "kratos",
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "args" => ["serve", "all", "--config", "/etc/config/kratos.yaml", "--dev"],
            "command" => ["kratos"],
            "env" => [
              %{
                "name" => "LOG_LEVEL",
                "value" => "trace"
              },
              %{
                "name" => "POSTGRES_USER",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "username",
                    "name" => "orykratos.pg-ory.credentials.postgresql",
                    "optional" => false
                  }
                }
              },
              %{
                "name" => "POSTGRES_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "password",
                    "name" => "orykratos.pg-ory.credentials.postgresql",
                    "optional" => false
                  }
                }
              },
              %{
                "name" => "DSN",
                "value" =>
                  "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@pg-ory.battery-base.svc/kratos?sslmode=prefer"
              },
              %{
                "name" => "SECRETS_DEFAULT",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "secretsDefault",
                    "name" => "ory-kratos",
                    "optional" => true
                  }
                }
              },
              %{
                "name" => "SECRETS_COOKIE",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "secretsCookie",
                    "name" => "ory-kratos",
                    "optional" => true
                  }
                }
              },
              %{
                "name" => "SECRETS_CIPHER",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "secretsCipher",
                    "name" => "ory-kratos",
                    "optional" => true
                  }
                }
              }
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "IfNotPresent",
            "livenessProbe" => %{
              "failureThreshold" => 5,
              "httpGet" => %{
                "httpHeaders" => [%{"name" => "Host", "value" => kratos_admin_host(state)}],
                "path" => "/admin/health/ready",
                "port" => 4434
              },
              "initialDelaySeconds" => 5,
              "periodSeconds" => 10
            },
            "name" => "kratos",
            "ports" => [
              %{"containerPort" => 4434, "name" => "http-admin", "protocol" => "TCP"},
              %{"containerPort" => 4433, "name" => "http-public", "protocol" => "TCP"}
            ],
            "readinessProbe" => %{
              "failureThreshold" => 5,
              "httpGet" => %{
                "httpHeaders" => [%{"name" => "Host", "value" => kratos_admin_host(state)}],
                "path" => "/admin/health/ready",
                "port" => 4434
              },
              "initialDelaySeconds" => 5,
              "periodSeconds" => 10
            },
            "resources" => nil,
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "privileged" => false,
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true,
              "runAsUser" => 100
            },
            "startupProbe" => %{
              "failureThreshold" => 60,
              "httpGet" => %{
                "httpHeaders" => [%{"name" => "Host", "value" => kratos_admin_host(state)}],
                "path" => "/admin/health/ready",
                "port" => 4434
              },
              "periodSeconds" => 1,
              "successThreshold" => 1,
              "timeoutSeconds" => 1
            },
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/config",
                "name" => "kratos-config-volume",
                "readOnly" => true
              }
            ]
          }
        ],
        "initContainers" => [
          %{
            "args" => ["migrate", "sql", "-e", "--yes", "--config", "/etc/config/kratos.yaml"],
            "command" => ["kratos"],
            "env" => [
              %{
                "name" => "POSTGRES_USER",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "username",
                    "name" => "orykratos.pg-ory.credentials.postgresql"
                  }
                }
              },
              %{
                "name" => "POSTGRES_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "password",
                    "name" => "orykratos.pg-ory.credentials.postgresql"
                  }
                }
              },
              %{
                "name" => "DSN",
                "value" =>
                  "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@pg-ory.battery-base.svc/kratos?sslmode=prefer"
              }
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "kratos-automigrate",
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/config",
                "name" => "kratos-config-volume",
                "readOnly" => true
              }
            ]
          }
        ],
        "serviceAccountName" => "ory-kratos",
        "volumes" => [
          %{"configMap" => %{"name" => "ory-kratos-config"}, "name" => "kratos-config-volume"}
        ]
      }
    }

    spec =
      %{}
      |> Map.put("progressDeadlineSeconds", 3600)
      |> Map.put("replicas", battery.config.replicas)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "kratos"}}
      )
      |> Map.put(
        "strategy",
        %{
          "rollingUpdate" => %{"maxSurge" => "30%", "maxUnavailable" => 0},
          "type" => "RollingUpdate"
        }
      )
      |> Map.put("template", template)

    B.build_resource(:deployment)
    |> B.name("ory-kratos")
    |> B.namespace(namespace)
    |> B.component_label("kratos")
    |> B.spec(spec)
  end
end
