defmodule CommonCore.Resources.Harbor do
  @moduledoc false
  use CommonCore.IncludeResource,
    no_proxy: "priv/raw_files/harbor/NO_PROXY",
    jobservice_config_yml: "priv/raw_files/harbor/jobservice_config.yml",
    registry_config_yml: "priv/raw_files/harbor/registry_config.yml",
    nginx_conf: "priv/raw_files/harbor/nginx.conf",
    tls_crt: "priv/raw_files/harbor/tls.crt",
    tls_key: "priv/raw_files/harbor/tls.key"

  use CommonCore.Resources.ResourceGenerator, app_name: "harbor"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.IstioConfig.HttpRoute
  alias CommonCore.Resources.IstioConfig.VirtualService
  alias CommonCore.Resources.Secret

  @postgres_credentials "harbor.pg-harbor.credentials.postgresql"

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    :istio_virtual_service
    |> B.build_resource()
    |> B.namespace(namespace)
    |> B.name("harbor-host-vs")
    |> B.spec(
      VirtualService.new(
        http: [
          HttpRoute.prefix("/api/", "harbor-core"),
          HttpRoute.prefix("/service/", "harbor-core"),
          HttpRoute.prefix("/v2", "harbor-core"),
          HttpRoute.prefix("/chartrepo/", "harbor-core"),
          HttpRoute.prefix("/c/", "harbor-core"),
          HttpRoute.fallback("harbor-portal")
        ],
        hosts: [harbor_host(state)]
      )
    )
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:config_map_core, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("CONFIG_PATH", "/etc/core/app.conf")
      |> Map.put("EXT_ENDPOINT", "http://#{harbor_host(state)}")
      |> Map.put("REGISTRY_STORAGE_PROVIDER_NAME", "filesystem")
      |> Map.put(
        "_REDIS_URL_CORE",
        "redis+sentinel://rfs-harbor:26379/mymaster/0?idle_timeout_seconds=30"
      )
      |> Map.put("CHART_REPOSITORY_URL", "http://harbor-chartmuseum")
      |> Map.put("METRIC_NAMESPACE", "harbor")
      |> Map.put("JOBSERVICE_URL", "http://harbor-jobservice")
      |> Map.put("METRIC_PATH", "/metrics")
      |> Map.put(
        "PERMITTED_REGISTRY_TYPES_FOR_PROXY_CACHE",
        "docker-hub,harbor,azure-acr,aws-ecr,google-gcr,quay,docker-registry"
      )
      |> Map.put("HTTPS_PROXY", "")
      |> Map.put("CORE_LOCAL_URL", "http://127.0.0.1:8080")
      |> Map.put("WITH_CHARTMUSEUM", "false")
      |> Map.put("DATABASE_TYPE", "postgresql")
      |> Map.put("POSTGRESQL_DATABASE", "registry")
      |> Map.put("POSTGRESQL_MAX_IDLE_CONNS", "100")
      |> Map.put("POSTGRESQL_PORT", "5432")
      |> Map.put("POSTGRESQL_HOST", "pg-harbor")
      |> Map.put("POSTGRESQL_SSLMODE", "require")
      |> Map.put("POSTGRESQL_MAX_OPEN_CONNS", "900")
      |> Map.put("REGISTRY_URL", "http://harbor-registry:5000")
      |> Map.put("HTTP_PROXY", "")
      |> Map.put("LOG_LEVEL", "info")
      |> Map.put("TOKEN_SERVICE_URL", "http://harbor-core:80/service/token")
      |> Map.put("REGISTRY_CONTROLLER_URL", "http://harbor-registry:8080")
      |> Map.put("METRIC_ENABLE", "true")
      |> Map.put(
        "_REDIS_URL_REG",
        "redis+sentinel://rfs-harbor:26379/mymaster/2?idle_timeout_seconds=30"
      )
      |> Map.put("WITH_TRIVY", "true")
      |> Map.put("TRIVY_ADAPTER_URL", "http://harbor-trivy:8080")
      |> Map.put(
        "app.conf",
        "appname = Harbor\nrunmode = prod\nenablegzip = true\n\n[prod]\nhttpport = 8080\n"
      )
      |> Map.put("WITH_NOTARY", "false")
      |> Map.put("CHART_CACHE_DRIVER", "redis")
      |> Map.put("CORE_URL", "http://harbor-core:80")
      |> Map.put("METRIC_PORT", "8001")
      |> Map.put("METRIC_SUBSYSTEM", "core")
      |> Map.put("PORTAL_URL", "http://harbor-portal")
      |> Map.put("PORT", "8080")
      |> Map.put("REGISTRY_CREDENTIAL_USERNAME", "harbor_registry_user")
      |> Map.put("NOTARY_URL", "http://harbor-notary-server:4443")
      |> Map.put("NO_PROXY", get_resource(:no_proxy))

    :config_map
    |> B.build_resource()
    |> B.name("harbor-core")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_exporter_env, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("HARBOR_DATABASE_DBNAME", "registry")
      |> Map.put("HARBOR_DATABASE_HOST", "pg-harbor")
      |> Map.put("HARBOR_DATABASE_MAX_IDLE_CONNS", "100")
      |> Map.put("HARBOR_DATABASE_MAX_OPEN_CONNS", "900")
      |> Map.put("HARBOR_DATABASE_PORT", "5432")
      |> Map.put("HARBOR_DATABASE_SSLMODE", "require")
      |> Map.put("HARBOR_EXPORTER_CACHE_CLEAN_INTERVAL", "14400")
      |> Map.put("HARBOR_EXPORTER_CACHE_TIME", "23")
      |> Map.put("HARBOR_EXPORTER_METRICS_ENABLED", "true")
      |> Map.put("HARBOR_EXPORTER_METRICS_PATH", "/metrics")
      |> Map.put("HARBOR_EXPORTER_PORT", "8001")
      |> Map.put("HARBOR_METRIC_NAMESPACE", "harbor")
      |> Map.put("HARBOR_METRIC_SUBSYSTEM", "exporter")
      |> Map.put("HARBOR_REDIS_NAMESPACE", "harbor_job_service_namespace")
      |> Map.put("HARBOR_REDIS_TIMEOUT", "3600")
      |> Map.put("HARBOR_REDIS_URL", "redis+sentinel://rfs-harbor:26379/mymaster/1")
      |> Map.put("HARBOR_SERVICE_HOST", "harbor-core")
      |> Map.put("HARBOR_SERVICE_PORT", "80")
      |> Map.put("HARBOR_SERVICE_SCHEME", "http")
      |> Map.put("HTTPS_PROXY", "")
      |> Map.put("HTTP_PROXY", "")
      |> Map.put("LOG_LEVEL", "debug")
      |> Map.put("NO_PROXY", get_resource(:no_proxy))

    :config_map
    |> B.build_resource()
    |> B.name("harbor-exporter-env")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_jobservice, _battery, state) do
    namespace = core_namespace(state)
    data = %{"config.yml" => get_resource(:jobservice_config_yml)}

    :config_map
    |> B.build_resource()
    |> B.name("harbor-jobservice")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_jobservice_env, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("CORE_URL", "http://harbor-core:80")
      |> Map.put("HTTPS_PROXY", "")
      |> Map.put("HTTP_PROXY", "")
      |> Map.put("METRIC_NAMESPACE", "harbor")
      |> Map.put("METRIC_SUBSYSTEM", "jobservice")
      |> Map.put("REGISTRY_CONTROLLER_URL", "http://harbor-registry:8080")
      |> Map.put("REGISTRY_CREDENTIAL_USERNAME", "harbor_registry_user")
      |> Map.put("REGISTRY_URL", "http://harbor-registry:5000")
      |> Map.put("TOKEN_SERVICE_URL", "http://harbor-core:80/service/token")
      |> Map.put("NO_PROXY", get_resource(:no_proxy))

    :config_map
    |> B.build_resource()
    |> B.name("harbor-jobservice-env")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_portal, _battery, state) do
    namespace = core_namespace(state)
    data = %{"nginx.conf" => get_resource(:nginx_conf)}

    :config_map
    |> B.build_resource()
    |> B.name("harbor-portal")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_registry, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put(
        "ctl-config.yml",
        "---\nprotocol: \"http\"\nport: 8080\nlog_level: info\nregistry_config: \"/etc/registry/config.yml\"\n"
      )
      |> Map.put("config.yml", get_resource(:registry_config_yml))

    :config_map
    |> B.build_resource()
    |> B.name("harbor-registry")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_registryctl, _battery, state) do
    namespace = core_namespace(state)
    data = %{}

    :config_map
    |> B.build_resource()
    |> B.name("harbor-registryctl")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_core, battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("CSRF_KEY", battery.config.csrf_key)
      |> Map.put("HARBOR_ADMIN_PASSWORD", "BatteryHarbor12345")
      |> Map.put("REGISTRY_CREDENTIAL_PASSWORD", "harbor_registry_password")
      |> Map.put("secret", battery.config.secret)
      |> Map.put("secretKey", "not-a-secure-key-really")
      |> Map.put("tls.crt", get_resource(:tls_crt))
      |> Map.put("tls.key", get_resource(:tls_key))
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("harbor-core")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_exporter, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("HARBOR_ADMIN_PASSWORD", "BatteryHarbor12345")
      |> Map.put("tls.crt", get_resource(:tls_crt))
      |> Map.put("tls.key", get_resource(:tls_key))
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("harbor-exporter")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_jobservice, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("JOBSERVICE_SECRET", "wpnBNVBDJV7pj63J")
      |> Map.put("REGISTRY_CREDENTIAL_PASSWORD", "harbor_registry_password")
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("harbor-jobservice")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_registry, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("REGISTRY_HTTP_SECRET", "3m8GeLYglFqRckMu")
      |> Map.put("REGISTRY_REDIS_PASSWORD", "")
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("harbor-registry")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_registry_htpasswd, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put(
        "REGISTRY_HTPASSWD",
        "harbor_registry_user:$2a$10$GdMvorhxJZ6nFiD9w/AsbOkKocAcN5NnwTfJp32yD3Gc2cGA9w.om"
      )
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("harbor-registry-htpasswd")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_registryctl, _battery, state) do
    namespace = core_namespace(state)
    data = %{}

    :secret
    |> B.build_resource()
    |> B.name("harbor-registryctl")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_trivy, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("gitHubToken", "")
      |> Map.put(
        "redisURL",
        "redis+sentinel://rfs-harbor:26379/mymaster/5?idle_timeout_seconds=30"
      )
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("harbor-trivy")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:deployment_core, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "core"}}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true",
              "battery/component" => "core"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => false,
            "containers" => [
              %{
                "env" => [
                  %{
                    "name" => "CORE_SECRET",
                    "valueFrom" => %{
                      "secretKeyRef" => %{"key" => "secret", "name" => "harbor-core"}
                    }
                  },
                  %{
                    "name" => "JOBSERVICE_SECRET",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "JOBSERVICE_SECRET",
                        "name" => "harbor-jobservice"
                      }
                    }
                  },
                  %{
                    "name" => "POSTGRESQL_USERNAME",
                    "valueFrom" => B.secret_key_ref(@postgres_credentials, "username")
                  },
                  %{
                    "name" => "POSTGRESQL_PASSWORD",
                    "valueFrom" => B.secret_key_ref(@postgres_credentials, "password")
                  }
                ],
                "envFrom" => [
                  %{"configMapRef" => %{"name" => "harbor-core"}},
                  %{"secretRef" => %{"name" => "harbor-core"}}
                ],
                "image" => battery.config.core_image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "failureThreshold" => 2,
                  "httpGet" => %{"path" => "/api/v2.0/ping", "port" => 8080, "scheme" => "HTTP"},
                  "periodSeconds" => 10
                },
                "name" => "core",
                "ports" => [%{"containerPort" => 8080}],
                "readinessProbe" => %{
                  "failureThreshold" => 2,
                  "httpGet" => %{"path" => "/api/v2.0/ping", "port" => 8080, "scheme" => "HTTP"},
                  "periodSeconds" => 10
                },
                "startupProbe" => %{
                  "failureThreshold" => 360,
                  "httpGet" => %{"path" => "/api/v2.0/ping", "port" => 8080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 10,
                  "periodSeconds" => 10
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/etc/core/app.conf",
                    "name" => "config",
                    "subPath" => "app.conf"
                  },
                  %{"mountPath" => "/etc/core/key", "name" => "secret-key", "subPath" => "key"},
                  %{
                    "mountPath" => "/etc/core/private_key.pem",
                    "name" => "token-service-private-key",
                    "subPath" => "tls.key"
                  },
                  %{"mountPath" => "/etc/core/token", "name" => "psc"}
                ]
              }
            ],
            "securityContext" => %{"fsGroup" => 10_000, "runAsUser" => 10_000},
            "terminationGracePeriodSeconds" => 120,
            "volumes" => [
              %{
                "configMap" => %{
                  "items" => [%{"key" => "app.conf", "path" => "app.conf"}],
                  "name" => "harbor-core"
                },
                "name" => "config"
              },
              %{
                "name" => "secret-key",
                "secret" => %{
                  "items" => [%{"key" => "secretKey", "path" => "key"}],
                  "secretName" => "harbor-core"
                }
              },
              %{
                "name" => "token-service-private-key",
                "secret" => %{"secretName" => "harbor-core"}
              },
              %{"emptyDir" => %{}, "name" => "psc"}
            ]
          }
        }
      )

    :deployment
    |> B.build_resource()
    |> B.name("harbor-core")
    |> B.namespace(namespace)
    |> B.component_label("core")
    |> B.spec(spec)
  end

  resource(:deployment_exporter, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "exporter"}}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true",
              "battery/component" => "exporter"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => false,
            "containers" => [
              %{
                "args" => ["-log-level", "info"],
                "env" => [
                  %{
                    "name" => "HARBOR_DATABASE_USERNAME",
                    "valueFrom" => B.secret_key_ref(@postgres_credentials, "username")
                  },
                  %{
                    "name" => "HARBOR_DATABASE_PASSWORD",
                    "valueFrom" => B.secret_key_ref(@postgres_credentials, "password")
                  }
                ],
                "envFrom" => [
                  %{"configMapRef" => %{"name" => "harbor-exporter-env"}},
                  %{"secretRef" => %{"name" => "harbor-exporter"}}
                ],
                "image" => battery.config.exporter_image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "httpGet" => %{"path" => "/", "port" => 8001},
                  "initialDelaySeconds" => 300,
                  "periodSeconds" => 10
                },
                "name" => "exporter",
                "ports" => [%{"containerPort" => 8080}],
                "readinessProbe" => %{
                  "httpGet" => %{"path" => "/", "port" => 8001},
                  "initialDelaySeconds" => 30,
                  "periodSeconds" => 10
                }
              }
            ],
            "securityContext" => %{"fsGroup" => 10_000, "runAsUser" => 10_000},
            "volumes" => [%{"name" => "config", "secret" => %{"secretName" => "harbor-exporter"}}]
          }
        }
      )

    :deployment
    |> B.build_resource()
    |> B.name("harbor-exporter")
    |> B.namespace(namespace)
    |> B.component_label("exporter")
    |> B.spec(spec)
  end

  resource(:deployment_jobservice, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "jobservice"}}
      )
      |> Map.put("strategy", %{"type" => "RollingUpdate"})
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true",
              "battery/component" => "jobservice"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => false,
            "containers" => [
              %{
                "env" => [
                  %{
                    "name" => "CORE_SECRET",
                    "valueFrom" => %{
                      "secretKeyRef" => %{"key" => "secret", "name" => "harbor-core"}
                    }
                  }
                ],
                "envFrom" => [
                  %{"configMapRef" => %{"name" => "harbor-jobservice-env"}},
                  %{"secretRef" => %{"name" => "harbor-jobservice"}}
                ],
                "image" => battery.config.jobservice_image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "httpGet" => %{"path" => "/api/v1/stats", "port" => 8080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 300,
                  "periodSeconds" => 10
                },
                "name" => "jobservice",
                "ports" => [%{"containerPort" => 8080}],
                "readinessProbe" => %{
                  "httpGet" => %{"path" => "/api/v1/stats", "port" => 8080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 20,
                  "periodSeconds" => 10
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/etc/jobservice/config.yml",
                    "name" => "jobservice-config",
                    "subPath" => "config.yml"
                  },
                  %{"mountPath" => "/var/log/jobs", "name" => "job-logs", "subPath" => nil},
                  %{
                    "mountPath" => "/var/scandata_exports",
                    "name" => "job-scandata-exports",
                    "subPath" => nil
                  }
                ]
              }
            ],
            "securityContext" => %{"fsGroup" => 10_000, "runAsUser" => 10_000},
            "terminationGracePeriodSeconds" => 120,
            "volumes" => [
              %{"configMap" => %{"name" => "harbor-jobservice"}, "name" => "jobservice-config"},
              %{
                "name" => "job-logs",
                "persistentVolumeClaim" => %{"claimName" => "harbor-jobservice"}
              },
              %{
                "name" => "job-scandata-exports",
                "persistentVolumeClaim" => %{"claimName" => "harbor-jobservice-scandata"}
              }
            ]
          }
        }
      )

    :deployment
    |> B.build_resource()
    |> B.name("harbor-jobservice")
    |> B.namespace(namespace)
    |> B.component_label("jobservice")
    |> B.spec(spec)
  end

  resource(:deployment_portal, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "portal"}}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true",
              "battery/component" => "portal"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => false,
            "containers" => [
              %{
                "image" => battery.config.portal_image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "httpGet" => %{"path" => "/", "port" => 8080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 300,
                  "periodSeconds" => 10
                },
                "name" => "portal",
                "ports" => [%{"containerPort" => 8080}],
                "readinessProbe" => %{
                  "httpGet" => %{"path" => "/", "port" => 8080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 1,
                  "periodSeconds" => 10
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/etc/nginx/nginx.conf",
                    "name" => "portal-config",
                    "subPath" => "nginx.conf"
                  }
                ]
              }
            ],
            "securityContext" => %{"fsGroup" => 10_000, "runAsUser" => 10_000},
            "volumes" => [
              %{"configMap" => %{"name" => "harbor-portal"}, "name" => "portal-config"}
            ]
          }
        }
      )

    :deployment
    |> B.build_resource()
    |> B.name("harbor-portal")
    |> B.namespace(namespace)
    |> B.component_label("portal")
    |> B.spec(spec)
  end

  resource(:deployment_registry, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "registry"}}
      )
      |> Map.put("strategy", %{"type" => "RollingUpdate"})
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true",
              "battery/component" => "registry"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => false,
            "containers" => [
              %{
                "args" => ["serve", "/etc/registry/config.yml"],
                "envFrom" => [%{"secretRef" => %{"name" => "harbor-registry"}}],
                "image" => battery.config.photon_image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "httpGet" => %{"path" => "/", "port" => 5000, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 300,
                  "periodSeconds" => 10
                },
                "name" => "registry",
                "ports" => [%{"containerPort" => 5000}, %{"containerPort" => 5001}],
                "readinessProbe" => %{
                  "httpGet" => %{"path" => "/", "port" => 5000, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 1,
                  "periodSeconds" => 10
                },
                "volumeMounts" => [
                  %{"mountPath" => "/storage", "name" => "registry-data", "subPath" => nil},
                  %{
                    "mountPath" => "/etc/registry/passwd",
                    "name" => "registry-htpasswd",
                    "subPath" => "passwd"
                  },
                  %{
                    "mountPath" => "/etc/registry/config.yml",
                    "name" => "registry-config",
                    "subPath" => "config.yml"
                  }
                ]
              },
              %{
                "env" => [
                  %{
                    "name" => "CORE_SECRET",
                    "valueFrom" => %{
                      "secretKeyRef" => %{"key" => "secret", "name" => "harbor-core"}
                    }
                  },
                  %{
                    "name" => "JOBSERVICE_SECRET",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "JOBSERVICE_SECRET",
                        "name" => "harbor-jobservice"
                      }
                    }
                  }
                ],
                "envFrom" => [
                  %{"configMapRef" => %{"name" => "harbor-registryctl"}},
                  %{"secretRef" => %{"name" => "harbor-registry"}},
                  %{"secretRef" => %{"name" => "harbor-registryctl"}}
                ],
                "image" => "goharbor/harbor-registryctl:v2.6.2",
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "httpGet" => %{"path" => "/api/health", "port" => 8080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 300,
                  "periodSeconds" => 10
                },
                "name" => "registryctl",
                "ports" => [%{"containerPort" => 8080}],
                "readinessProbe" => %{
                  "httpGet" => %{"path" => "/api/health", "port" => 8080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 1,
                  "periodSeconds" => 10
                },
                "volumeMounts" => [
                  %{"mountPath" => "/storage", "name" => "registry-data", "subPath" => nil},
                  %{
                    "mountPath" => "/etc/registry/config.yml",
                    "name" => "registry-config",
                    "subPath" => "config.yml"
                  },
                  %{
                    "mountPath" => "/etc/registryctl/config.yml",
                    "name" => "registry-config",
                    "subPath" => "ctl-config.yml"
                  }
                ]
              }
            ],
            "securityContext" => %{
              "fsGroup" => 10_000,
              "fsGroupChangePolicy" => "OnRootMismatch",
              "runAsUser" => 10_000
            },
            "terminationGracePeriodSeconds" => 120,
            "volumes" => [
              %{
                "name" => "registry-htpasswd",
                "secret" => %{
                  "items" => [%{"key" => "REGISTRY_HTPASSWD", "path" => "passwd"}],
                  "secretName" => "harbor-registry-htpasswd"
                }
              },
              %{"configMap" => %{"name" => "harbor-registry"}, "name" => "registry-config"},
              %{
                "name" => "registry-data",
                "persistentVolumeClaim" => %{"claimName" => "harbor-registry"}
              }
            ]
          }
        }
      )

    :deployment
    |> B.build_resource()
    |> B.name("harbor-registry")
    |> B.namespace(namespace)
    |> B.component_label("registry")
    |> B.spec(spec)
  end

  resource(:stateful_set_trivy, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "trivy"}}
      )
      |> Map.put("serviceName", "harbor-trivy")
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true",
              "battery/component" => "trivy"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => false,
            "containers" => [
              %{
                "env" => [
                  %{"name" => "HTTP_PROXY", "value" => ""},
                  %{"name" => "HTTPS_PROXY", "value" => ""},
                  %{
                    "name" => "NO_PROXY",
                    "value" => get_resource(:no_proxy)
                  },
                  %{"name" => "SCANNER_LOG_LEVEL", "value" => "info"},
                  %{"name" => "SCANNER_TRIVY_CACHE_DIR", "value" => "/home/scanner/.cache/trivy"},
                  %{
                    "name" => "SCANNER_TRIVY_REPORTS_DIR",
                    "value" => "/home/scanner/.cache/reports"
                  },
                  %{"name" => "SCANNER_TRIVY_DEBUG_MODE", "value" => "true"},
                  %{"name" => "SCANNER_TRIVY_VULN_TYPE", "value" => "os,library"},
                  %{"name" => "SCANNER_TRIVY_TIMEOUT", "value" => "5m0s"},
                  %{
                    "name" => "SCANNER_TRIVY_GITHUB_TOKEN",
                    "valueFrom" => %{
                      "secretKeyRef" => %{"key" => "gitHubToken", "name" => "harbor-trivy"}
                    }
                  },
                  %{
                    "name" => "SCANNER_TRIVY_SEVERITY",
                    "value" => "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL"
                  },
                  %{"name" => "SCANNER_TRIVY_IGNORE_UNFIXED", "value" => "false"},
                  %{"name" => "SCANNER_TRIVY_SKIP_UPDATE", "value" => "false"},
                  %{"name" => "SCANNER_TRIVY_OFFLINE_SCAN", "value" => "false"},
                  %{"name" => "SCANNER_TRIVY_SECURITY_CHECKS", "value" => "vuln"},
                  %{"name" => "SCANNER_TRIVY_INSECURE", "value" => "true"},
                  %{"name" => "SCANNER_API_SERVER_ADDR", "value" => ":8080"},
                  %{
                    "name" => "SCANNER_REDIS_URL",
                    "valueFrom" => %{
                      "secretKeyRef" => %{"key" => "redisURL", "name" => "harbor-trivy"}
                    }
                  },
                  %{
                    "name" => "SCANNER_STORE_REDIS_URL",
                    "valueFrom" => %{
                      "secretKeyRef" => %{"key" => "redisURL", "name" => "harbor-trivy"}
                    }
                  },
                  %{
                    "name" => "SCANNER_JOB_QUEUE_REDIS_URL",
                    "valueFrom" => %{
                      "secretKeyRef" => %{"key" => "redisURL", "name" => "harbor-trivy"}
                    }
                  }
                ],
                "image" => battery.config.trivy_adapter_image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "failureThreshold" => 10,
                  "httpGet" => %{
                    "path" => "/probe/healthy",
                    "port" => "api-server",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "successThreshold" => 1
                },
                "name" => "trivy",
                "ports" => [%{"containerPort" => 8080, "name" => "api-server"}],
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{
                    "path" => "/probe/ready",
                    "port" => "api-server",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "successThreshold" => 1
                },
                "resources" => %{
                  "limits" => %{"cpu" => 1, "memory" => "1Gi"},
                  "requests" => %{"cpu" => "200m", "memory" => "512Mi"}
                },
                "securityContext" => %{"allowPrivilegeEscalation" => false, "privileged" => false},
                "volumeMounts" => [
                  %{
                    "mountPath" => "/home/scanner/.cache",
                    "name" => "data",
                    "readOnly" => false,
                    "subPath" => nil
                  }
                ]
              }
            ],
            "securityContext" => %{"fsGroup" => 10_000, "runAsUser" => 10_000}
          }
        }
      )
      |> Map.put("volumeClaimTemplates", [
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "chart" => "harbor",
              "heritage" => "Helm",
              "release" => "harbor"
            },
            "name" => "data"
          },
          "spec" => %{
            "accessModes" => ["ReadWriteOnce"],
            "resources" => %{"requests" => %{"storage" => "5Gi"}}
          }
        }
      ])

    :stateful_set
    |> B.build_resource()
    |> B.name("harbor-trivy")
    |> B.namespace(namespace)
    |> B.component_label("trivy")
    |> B.spec(spec)
  end

  resource(:persistent_volume_claim_jobservice, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("accessModes", ["ReadWriteOnce"])
      |> Map.put("resources", %{"requests" => %{"storage" => "1Gi"}})

    :persistent_volume_claim
    |> B.build_resource()
    |> B.name("harbor-jobservice")
    |> B.namespace(namespace)
    |> B.component_label("jobservice")
    |> B.spec(spec)
  end

  resource(:persistent_volume_claim_jobservice_scandata, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("accessModes", ["ReadWriteOnce"])
      |> Map.put("resources", %{"requests" => %{"storage" => "1Gi"}})

    :persistent_volume_claim
    |> B.build_resource()
    |> B.name("harbor-jobservice-scandata")
    |> B.namespace(namespace)
    |> B.component_label("jobservice")
    |> B.spec(spec)
  end

  resource(:persistent_volume_claim_registry, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("accessModes", ["ReadWriteOnce"])
      |> Map.put("resources", %{"requests" => %{"storage" => "5Gi"}})

    :persistent_volume_claim
    |> B.build_resource()
    |> B.name("harbor-registry")
    |> B.namespace(namespace)
    |> B.component_label("registry")
    |> B.spec(spec)
  end

  resource(:service_core, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-web", "port" => 80, "targetPort" => 8080},
        %{"name" => "http-metrics", "port" => 8001}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "core"})

    :service
    |> B.build_resource()
    |> B.name("harbor-core")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_exporter, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"name" => "http-metrics", "port" => 8001}])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "exporter"})

    :service
    |> B.build_resource()
    |> B.name("harbor-exporter")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_jobservice, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-jobservice", "port" => 80, "targetPort" => 8080},
        %{"name" => "http-metrics", "port" => 8001}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "jobservice"})

    :service
    |> B.build_resource()
    |> B.name("harbor-jobservice")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_portal, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"port" => 80, "targetPort" => 8080}])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "portal"})

    :service
    |> B.build_resource()
    |> B.name("harbor-portal")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_registry, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-registry", "port" => 5000},
        %{"name" => "http-controller", "port" => 8080},
        %{"name" => "http-metrics", "port" => 8001}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "registry"})

    :service
    |> B.build_resource()
    |> B.name("harbor-registry")
    |> B.namespace(namespace)
    |> B.component_label("registry")
    |> B.spec(spec)
  end

  resource(:service_trivy, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"name" => "http-trivy", "port" => 8080, "protocol" => "TCP"}])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "trivy"})

    :service
    |> B.build_resource()
    |> B.name("harbor-trivy")
    |> B.namespace(namespace)
    |> B.component_label("trivy")
    |> B.spec(spec)
  end
end
