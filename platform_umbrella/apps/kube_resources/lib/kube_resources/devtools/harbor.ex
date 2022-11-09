defmodule KubeResources.Harbor do
  @moduledoc false
  use KubeExt.IncludeResource, nginx_conf: "priv/raw_files/harbor/nginx.conf"
  use KubeExt.ResourceGenerator

  alias KubeResources.DevtoolsSettings, as: Settings
  alias KubeResources.IstioConfig.VirtualService
  alias KubeResources.IstioConfig.HttpRoute
  alias KubeExt.Secret
  alias Ymlr.Encoder, as: YamlEncoder
  alias KubeExt.KubeState.Hosts

  @app "harbor"

  @core_secret "harbor-core"
  @jobservice_secret "harbor-jobservice"
  @registry_secret "harbor-registry"
  @registry_htpasswd_secret "harbor-registry-htpasswd"
  @registryctl_secret "harbor-registryctl"
  @trivy_secret "harbor-trivy"

  @core_config "harbor-core"

  @postgres_credentials "harbor.pg-harbor.credentials.postgresql.acid.zalan.do"

  def view_url, do: view_url(KubeExt.cluster_type())

  # TODO: Figure out if we can mount the virtual service a few times.
  def view_url(:dev), do: url()

  def view_url(_), do: url()

  def url, do: "//#{Hosts.harbor_host()}"

  resource(:virtual_service, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("harbor-host-vs")
    |> B.spec(
      VirtualService.new(
        http: [
          HttpRoute.prefix("/api/", "harbor-core"),
          HttpRoute.prefix("/service/", "harbor-core"),
          HttpRoute.prefix("/v2", "harbor-core"),
          HttpRoute.prefix("/c/", "harbor-core"),
          HttpRoute.fallback("harbor-portal")
        ],
        hosts: [Hosts.harbor_host()]
      )
    )
  end

  defp build_secret(name, namespace, data) do
    B.build_resource(:secret)
    |> B.name(name)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.data(Secret.encode(data))
  end

  resource(:secret, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{
      "CSRF_KEY" => "nSwN8m7nun4jCiMjwesQtp3hhWxfYdPW",
      "HARBOR_ADMIN_PASSWORD" => "BatteryHarbor12345",
      "REGISTRY_CREDENTIAL_PASSWORD" => "harbor_registry_password",
      "secret" => "lUSSxLWl07Z4AaG4",
      "secretKey" => "not-a-secure-key-really",
      "tls.crt" => "",
      "tls.key" => ""
    }

    build_secret(@core_secret, namespace, data)
  end

  resource(:secret_1, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{
      "JOBSERVICE_SECRET" => "dzWy6TktiYJ3BKu2",
      "REGISTRY_CREDENTIAL_PASSWORD" => "harbor_registry_password"
    }

    build_secret(@jobservice_secret, namespace, data)
  end

  resource(:secret_2, battery, _state) do
    namespace = Settings.namespace(battery.config)
    data = %{"REGISTRY_HTTP_SECRET" => "Jjk0Ig28EsLo6w6V", "REGISTRY_REDIS_PASSWORD" => ""}

    build_secret(@registry_secret, namespace, data)
  end

  resource(:secret_3, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{
      "REGISTRY_HTPASSWD" =>
        "harbor_registry_user:$2a$10$54x05QL8nPjsMm/pXovCme2E1dJpbFadO8FL2WuPkCCuUKk8iKJGW"
    }

    build_secret(@registry_htpasswd_secret, namespace, data)
  end

  resource(:secret_4, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:secret)
    |> B.name(@registryctl_secret)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
  end

  resource(:secret_5, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{
      "gitHubToken" => "",
      "redisURL" => "redis+sentinel://rfs-harbor:26379/mymaster/5?idle_timeout_seconds=30"
    }

    build_secret(@trivy_secret, namespace, data)
  end

  resource(:config_map, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{
      "CHART_CACHE_DRIVER" => "redis",
      "CHART_REPOSITORY_URL" => "http://harbor-chartmuseum",
      "CONFIG_PATH" => "/etc/core/app.conf",
      "CORE_LOCAL_URL" => "http://127.0.0.1:8080",
      "CORE_URL" => "http://harbor-core:80",
      "DATABASE_TYPE" => "postgresql",
      "EXT_ENDPOINT" => "http://core.harbor.domain",
      "HTTPS_PROXY" => "",
      "HTTP_PROXY" => "",
      "JOBSERVICE_URL" => "http://harbor-jobservice",
      "LOG_LEVEL" => "info",
      "NOTARY_URL" => "http://harbor-notary-server:4443",
      "NO_PROXY" =>
        "harbor-core,harbor-jobservice,harbor-database,harbor-chartmuseum,harbor-notary-server,harbor-notary-signer,harbor-registry,harbor-portal,harbor-trivy,harbor-exporter,127.0.0.1,localhost,.local,.internal",
      "PERMITTED_REGISTRY_TYPES_FOR_PROXY_CACHE" =>
        "docker-hub,harbor,azure-acr,aws-ecr,google-gcr,quay,docker-registry",
      "PORT" => "8080",
      "PORTAL_URL" => "http://harbor-portal",
      "POSTGRESQL_DATABASE" => "harbor",
      "POSTGRESQL_HOST" => "pg-harbor",
      "POSTGRESQL_MAX_IDLE_CONNS" => "100",
      "POSTGRESQL_MAX_OPEN_CONNS" => "900",
      "POSTGRESQL_PORT" => "5432",
      "POSTGRESQL_SSLMODE" => "require",
      "POSTGRESQL_USERNAME" => "harbor",
      "REGISTRY_CONTROLLER_URL" => "http://harbor-registry:8080",
      "REGISTRY_CREDENTIAL_USERNAME" => "harbor_registry_user",
      "REGISTRY_STORAGE_PROVIDER_NAME" => "filesystem",
      "REGISTRY_URL" => "http://harbor-registry:5000",
      "TOKEN_SERVICE_URL" => "http://harbor-core:80/service/token",
      "TRIVY_ADAPTER_URL" => "http://harbor-trivy:8080",
      "WITH_CHARTMUSEUM" => "false",
      "WITH_NOTARY" => "false",
      "WITH_TRIVY" => "true",
      "_REDIS_URL_CORE" => "redis+sentinel://rfs-harbor:26379/mymaster/0?idle_timeout_seconds=30",
      "_REDIS_URL_REG" => "redis+sentinel://rfs-harbor:26379/mymaster/2?idle_timeout_seconds=30",
      "app.conf" =>
        "appname = Harbor\nrunmode = prod\nenablegzip = true\n\n[prod]\nhttpport = 8080\n"
    }

    B.build_resource(:config_map)
    |> B.name(@core_config)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_1, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{
      "CORE_URL" => "http://harbor-core:80",
      "HTTPS_PROXY" => "",
      "HTTP_PROXY" => "",
      "NO_PROXY" =>
        "harbor-core,harbor-jobservice,harbor-database,harbor-chartmuseum,harbor-notary-server,harbor-notary-signer,harbor-registry,harbor-portal,harbor-trivy,harbor-exporter,127.0.0.1,localhost,.local,.internal",
      "REGISTRY_CONTROLLER_URL" => "http://harbor-registry:8080",
      "REGISTRY_CREDENTIAL_USERNAME" => "harbor_registry_user",
      "REGISTRY_URL" => "http://harbor-registry:5000",
      "TOKEN_SERVICE_URL" => "http://harbor-core:80/service/token"
    }

    B.build_resource(:config_map)
    |> B.name("harbor-jobservice-env")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_2, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{
      "config.yml" => jobservice_config_yml()
    }

    B.build_resource(:config_map)
    |> B.name("harbor-jobservice")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.data(data)
  end

  defp jobservice_config_yml do
    config = %{
      "job_loggers" => [
        %{
          "level" => "INFO",
          "name" => "FILE",
          "settings" => %{"base_dir" => "/var/log/jobs"},
          "sweeper" => %{
            "duration" => 14,
            "settings" => %{"work_dir" => "/var/log/jobs"}
          }
        }
      ],
      "loggers" => [%{"level" => "INFO", "name" => "STD_OUTPUT"}],
      "metric" => %{"enabled" => false, "path" => "/metrics", "port" => 8001},
      "port" => 8080,
      "protocol" => "http",
      "worker_pool" => %{
        "backend" => "redis",
        "redis_pool" => %{
          "idle_timeout_second" => 3600,
          "namespace" => "harbor_job_service_namespace",
          "redis_url" => "redis+sentinel://rfs-harbor:26379/mymaster/1"
        },
        "workers" => 10
      }
    }

    YamlEncoder.to_s!(config)
  end

  resource(:config_map_3, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{"nginx.conf" => get_resource(:nginx_conf)}

    B.build_resource(:config_map)
    |> B.name("harbor-portal")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_4, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data = %{
      "config.yml" => registry_config_yml(),
      "ctl-config.yml" => ctl_config_yml()
    }

    B.build_resource(:config_map)
    |> B.name("harbor-registry")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.data(data)
  end

  defp ctl_config_yml do
    ctl_config = %{
      "log_level" => "info",
      "port" => 8080,
      "protocol" => "http",
      "registry_config" => "/etc/registry/config.yml"
    }

    # It really needs to look like this list format.
    "---\n" <> YamlEncoder.to_s!(ctl_config)
  end

  defp registry_config_yml do
    config = %{
      "auth" => %{
        "htpasswd" => %{
          "path" => "/etc/registry/passwd",
          "realm" => "harbor-registry-basic-realm"
        }
      },
      "compatibility" => %{"schema1" => %{"enabled" => true}},
      "http" => %{
        "addr" => ":5000",
        "debug" => %{"addr" => "localhost:5001"},
        "relativeurls" => false
      },
      "log" => %{"fields" => %{"service" => "registry"}, "level" => "info"},
      "redis" => %{
        "addr" => "rfs-harbor:26379",
        "db" => 2,
        "dialtimeout" => "10s",
        "pool" => %{"idletimeout" => "60s", "maxactive" => 500, "maxidle" => 100},
        "readtimeout" => "10s",
        "sentinelMasterSet" => "mymaster",
        "writetimeout" => "10s"
      },
      "storage" => %{
        "cache" => %{"layerinfo" => "redis"},
        "delete" => %{"enabled" => true},
        "filesystem" => %{"rootdirectory" => "/storage"},
        "maintenance" => %{
          "uploadpurging" => %{
            "age" => "168h",
            "dryrun" => false,
            "enabled" => true,
            "interval" => "24h"
          }
        },
        "redirect" => %{"disable" => true}
      },
      "validation" => %{"disabled" => true},
      "version" => 0.1
    }

    YamlEncoder.to_s!(config)
  end

  resource(:config_map_5, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:config_map)
    |> B.name("harbor-registryctl")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
  end

  resource(:persistent_volume_claim, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec = %{
      "accessModes" => [
        "ReadWriteOnce"
      ],
      "resources" => %{
        "requests" => %{
          "storage" => "1Gi"
        }
      }
    }

    B.build_resource(:persistent_volume_claim)
    |> B.name("harbor-jobservice")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.app_labels(@app)
    |> B.label("component", "jobservice")
  end

  resource(:persistent_volume_claim_1, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec = %{
      "accessModes" => [
        "ReadWriteOnce"
      ],
      "resources" => %{
        "requests" => %{
          "storage" => "5Gi"
        }
      }
    }

    B.build_resource(:persistent_volume_claim)
    |> B.name("harbor-registry")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.app_labels(@app)
    |> B.label("component", "registry")
  end

  resource(:service, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec = %{
      "ports" => [
        %{
          "name" => "http-web",
          "port" => 80,
          "targetPort" => 8080
        }
      ],
      "selector" => %{
        "battery/app" => "harbor",
        "component" => "core"
      }
    }

    B.build_resource(:service)
    |> B.name("harbor-core")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.app_labels(@app)
  end

  resource(:service_1, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec = %{
      "ports" => [
        %{
          "name" => "http-jobservice",
          "port" => 80,
          "targetPort" => 8080
        }
      ],
      "selector" => %{
        "battery/app" => "harbor",
        "component" => "jobservice"
      }
    }

    B.build_resource(:service)
    |> B.name("harbor-jobservice")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.app_labels(@app)
  end

  resource(:service_2, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec = %{
      "ports" => [
        %{
          "port" => 80,
          "targetPort" => 8080
        }
      ],
      "selector" => %{
        "battery/app" => "harbor",
        "component" => "portal"
      }
    }

    B.build_resource(:service)
    |> B.name("harbor-portal")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.app_labels(@app)
  end

  resource(:service_3, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec = %{
      "ports" => [
        %{
          "name" => "http-registry",
          "port" => 5000
        },
        %{
          "name" => "http-controller",
          "port" => 8080
        }
      ],
      "selector" => %{
        "battery/app" => "harbor",
        "component" => "registry"
      }
    }

    B.build_resource(:service)
    |> B.name("harbor-registry")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.app_labels(@app)
  end

  resource(:service_4, battery, _state) do
    namespace = Settings.namespace(battery.config)

    spec = %{
      "ports" => [
        %{
          "name" => "http-trivy",
          "port" => 8080,
          "protocol" => "TCP"
        }
      ],
      "selector" => %{
        "battery/app" => "harbor",
        "component" => "trivy"
      }
    }

    B.build_resource(:service)
    |> B.name("harbor-trivy")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.app_labels(@app)
  end

  resource(:deployment, battery, _state) do
    namespace = Settings.namespace(battery.config)
    core_image = Settings.harbor_core_image(battery.config)

    spec = %{
      "replicas" => 1,
      "revisionHistoryLimit" => 10,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "harbor",
          "battery/managed" => "true",
          "component" => "core"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "harbor",
            "battery/managed" => "true",
            "component" => "core"
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
                    "secretKeyRef" => %{
                      "key" => "secret",
                      "name" => @core_secret
                    }
                  }
                },
                %{
                  "name" => "JOBSERVICE_SECRET",
                  "valueFrom" => %{
                    "secretKeyRef" => %{
                      "key" => "JOBSERVICE_SECRET",
                      "name" => @jobservice_secret
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
                %{
                  "configMapRef" => %{
                    "name" => @core_config
                  }
                },
                %{
                  "secretRef" => %{
                    "name" => @core_secret
                  }
                }
              ],
              "image" => core_image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "failureThreshold" => 2,
                "httpGet" => %{
                  "path" => "/api/v2.0/ping",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
                "periodSeconds" => 10
              },
              "name" => "core",
              "ports" => [
                %{
                  "containerPort" => 8080
                }
              ],
              "readinessProbe" => %{
                "failureThreshold" => 2,
                "httpGet" => %{
                  "path" => "/api/v2.0/ping",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
                "periodSeconds" => 10
              },
              "startupProbe" => %{
                "failureThreshold" => 360,
                "httpGet" => %{
                  "path" => "/api/v2.0/ping",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 10,
                "periodSeconds" => 10
              },
              "volumeMounts" => [
                %{
                  "mountPath" => "/etc/core/app.conf",
                  "name" => "config",
                  "subPath" => "app.conf"
                },
                %{
                  "mountPath" => "/etc/core/key",
                  "name" => "secret-key",
                  "subPath" => "key"
                },
                %{
                  "mountPath" => "/etc/core/private_key.pem",
                  "name" => "token-service-private-key",
                  "subPath" => "tls.key"
                },
                %{
                  "mountPath" => "/etc/core/token",
                  "name" => "psc"
                }
              ]
            }
          ],
          "securityContext" => %{
            "fsGroup" => 10_000,
            "runAsUser" => 10_000
          },
          "terminationGracePeriodSeconds" => 120,
          "volumes" => [
            %{
              "configMap" => %{
                "items" => [
                  %{
                    "key" => "app.conf",
                    "path" => "app.conf"
                  }
                ],
                "name" => @core_config
              },
              "name" => "config"
            },
            %{
              "name" => "secret-key",
              "secret" => %{
                "items" => [
                  %{
                    "key" => "secretKey",
                    "path" => "key"
                  }
                ],
                "secretName" => @core_secret
              }
            },
            %{
              "name" => "token-service-private-key",
              "secret" => %{
                "secretName" => "harbor-core"
              }
            },
            %{
              "emptyDir" => %{},
              "name" => "psc"
            }
          ]
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("harbor-core")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("component", "core")
    |> B.spec(spec)
  end

  resource(:deployment_1, battery, _state) do
    namespace = Settings.namespace(battery.config)
    jobservice_image = Settings.harbor_jobservice_image(battery.config)

    spec = %{
      "replicas" => 1,
      "revisionHistoryLimit" => 10,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "harbor",
          "battery/managed" => "true",
          "component" => "jobservice"
        }
      },
      "strategy" => %{
        "type" => "RollingUpdate"
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "harbor",
            "battery/managed" => "true",
            "component" => "jobservice"
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
                    "secretKeyRef" => %{
                      "key" => "secret",
                      "name" => @core_secret
                    }
                  }
                },
                %{
                  "name" => "POSTGRESQL_USERNAME",
                  "valueFrom" => B.secret_key_ref(@postgres_credentials, "username")
                },
                %{
                  "name" => "POSTGRES_PASSWORD",
                  "valueFrom" => B.secret_key_ref(@postgres_credentials, "password")
                }
              ],
              "envFrom" => [
                %{
                  "configMapRef" => %{
                    "name" => "harbor-jobservice-env"
                  }
                },
                %{
                  "secretRef" => %{
                    "name" => @jobservice_secret
                  }
                }
              ],
              "image" => jobservice_image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{
                  "path" => "/api/v1/stats",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 300,
                "periodSeconds" => 10
              },
              "name" => "jobservice",
              "ports" => [
                %{
                  "containerPort" => 8080
                }
              ],
              "readinessProbe" => %{
                "httpGet" => %{
                  "path" => "/api/v1/stats",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 20,
                "periodSeconds" => 10
              },
              "volumeMounts" => [
                %{
                  "mountPath" => "/etc/jobservice/config.yml",
                  "name" => "jobservice-config",
                  "subPath" => "config.yml"
                },
                %{
                  "mountPath" => "/var/log/jobs",
                  "name" => "job-logs"
                }
              ]
            }
          ],
          "securityContext" => %{
            "fsGroup" => 10_000,
            "runAsUser" => 10_000
          },
          "terminationGracePeriodSeconds" => 120,
          "volumes" => [
            %{
              "configMap" => %{
                "name" => "harbor-jobservice"
              },
              "name" => "jobservice-config"
            },
            %{
              "name" => "job-logs",
              "persistentVolumeClaim" => %{
                "claimName" => "harbor-jobservice"
              }
            }
          ]
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("harbor-jobservice")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("component", "jobservice")
    |> B.spec(spec)
  end

  resource(:deployment_2, battery, _state) do
    namespace = Settings.namespace(battery.config)
    image = Settings.harbor_portal_image(battery.config)

    spec = %{
      "replicas" => 1,
      "revisionHistoryLimit" => 10,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "harbor",
          "component" => "portal"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "harbor",
            "battery/managed" => "true",
            "component" => "portal"
          }
        },
        "spec" => %{
          "automountServiceAccountToken" => false,
          "containers" => [
            %{
              "image" => image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{
                  "path" => "/",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 300,
                "periodSeconds" => 10
              },
              "name" => "portal",
              "ports" => [
                %{
                  "containerPort" => 8080
                }
              ],
              "readinessProbe" => %{
                "httpGet" => %{
                  "path" => "/",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
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
          "securityContext" => %{
            "fsGroup" => 10_000,
            "runAsUser" => 10_000
          },
          "volumes" => [
            %{
              "configMap" => %{
                "name" => "harbor-portal"
              },
              "name" => "portal-config"
            }
          ]
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("harbor-portal")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("component", "portal")
    |> B.spec(spec)
  end

  resource(:deployment_3, battery, _state) do
    namespace = Settings.namespace(battery.config)
    registry_image = Settings.harbor_registry_photon_image(battery.config)
    ctl_image = Settings.harbor_registry_ctl_image(battery.config)

    spec = %{
      "replicas" => 1,
      "revisionHistoryLimit" => 10,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "harbor",
          "component" => "registry"
        }
      },
      "strategy" => %{
        "type" => "RollingUpdate"
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "harbor",
            "battery/managed" => "true",
            "component" => "registry"
          }
        },
        "spec" => %{
          "automountServiceAccountToken" => false,
          "containers" => [
            %{
              "args" => [
                "serve",
                "/etc/registry/config.yml"
              ],
              "envFrom" => [
                %{
                  "secretRef" => %{
                    "name" => "harbor-registry"
                  }
                }
              ],
              "image" => registry_image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{
                  "path" => "/",
                  "port" => 5000,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 300,
                "periodSeconds" => 10
              },
              "name" => "registry",
              "ports" => [
                %{
                  "containerPort" => 5000
                },
                %{
                  "containerPort" => 5001
                }
              ],
              "readinessProbe" => %{
                "httpGet" => %{
                  "path" => "/",
                  "port" => 5000,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 1,
                "periodSeconds" => 10
              },
              "volumeMounts" => [
                %{
                  "mountPath" => "/storage",
                  "name" => "registry-data"
                },
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
                    "secretKeyRef" => %{
                      "key" => "secret",
                      "name" => @core_secret
                    }
                  }
                },
                %{
                  "name" => "JOBSERVICE_SECRET",
                  "valueFrom" => %{
                    "secretKeyRef" => %{
                      "key" => "JOBSERVICE_SECRET",
                      "name" => @jobservice_secret
                    }
                  }
                },
                %{
                  "name" => "POSTGRES_USER",
                  "valueFrom" => B.secret_key_ref(@postgres_credentials, "username")
                },
                %{
                  "name" => "POSTGRES_PASSWORD",
                  "valueFrom" => B.secret_key_ref(@postgres_credentials, "password")
                }
              ],
              "envFrom" => [
                %{
                  "configMapRef" => %{
                    "name" => "harbor-registryctl"
                  }
                },
                %{
                  "secretRef" => %{
                    "name" => @registry_secret
                  }
                },
                %{
                  "secretRef" => %{
                    "name" => @registryctl_secret
                  }
                }
              ],
              "image" => ctl_image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "httpGet" => %{
                  "path" => "/api/health",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 300,
                "periodSeconds" => 10
              },
              "name" => "registryctl",
              "ports" => [
                %{
                  "containerPort" => 8080
                }
              ],
              "readinessProbe" => %{
                "httpGet" => %{
                  "path" => "/api/health",
                  "port" => 8080,
                  "scheme" => "HTTP"
                },
                "initialDelaySeconds" => 1,
                "periodSeconds" => 10
              },
              "volumeMounts" => [
                %{
                  "mountPath" => "/storage",
                  "name" => "registry-data"
                },
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
            "runAsUser" => 10_000
          },
          "terminationGracePeriodSeconds" => 120,
          "volumes" => [
            %{
              "name" => "registry-htpasswd",
              "secret" => %{
                "items" => [
                  %{
                    "key" => "REGISTRY_HTPASSWD",
                    "path" => "passwd"
                  }
                ],
                "secretName" => @registry_htpasswd_secret
              }
            },
            %{
              "configMap" => %{
                "name" => "harbor-registry"
              },
              "name" => "registry-config"
            },
            %{
              "name" => "registry-data",
              "persistentVolumeClaim" => %{
                "claimName" => "harbor-registry"
              }
            }
          ]
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("harbor-registry")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("component", "registry")
    |> B.spec(spec)
  end

  resource(:stateful_set, battery, _state) do
    namespace = Settings.namespace(battery.config)
    trivy_adapter_image = Settings.harbor_trivy_adapter_image(battery.config)

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "harbor",
          "component" => "trivy"
        }
      },
      "serviceName" => "harbor-trivy",
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "harbor",
            "battery/managed" => "true",
            "component" => "trivy"
          }
        },
        "spec" => %{
          "automountServiceAccountToken" => false,
          "containers" => [
            %{
              "env" => [
                %{
                  "name" => "HTTP_PROXY",
                  "value" => ""
                },
                %{
                  "name" => "HTTPS_PROXY",
                  "value" => ""
                },
                %{
                  "name" => "NO_PROXY",
                  "value" =>
                    "harbor-core,harbor-jobservice,harbor-database,harbor-chartmuseum,harbor-notary-server,harbor-notary-signer,harbor-registry,harbor-portal,harbor-trivy,harbor-exporter,127.0.0.1,localhost,.local,.internal"
                },
                %{
                  "name" => "SCANNER_LOG_LEVEL",
                  "value" => "info"
                },
                %{
                  "name" => "SCANNER_TRIVY_CACHE_DIR",
                  "value" => "/home/scanner/.cache/trivy"
                },
                %{
                  "name" => "SCANNER_TRIVY_REPORTS_DIR",
                  "value" => "/home/scanner/.cache/reports"
                },
                %{
                  "name" => "SCANNER_TRIVY_DEBUG_MODE",
                  "value" => "true"
                },
                %{
                  "name" => "SCANNER_TRIVY_VULN_TYPE",
                  "value" => "os,library"
                },
                %{
                  "name" => "SCANNER_TRIVY_TIMEOUT",
                  "value" => "5m0s"
                },
                %{
                  "name" => "SCANNER_TRIVY_GITHUB_TOKEN",
                  "valueFrom" => %{
                    "secretKeyRef" => %{
                      "key" => "gitHubToken",
                      "name" => "harbor-trivy"
                    }
                  }
                },
                %{
                  "name" => "SCANNER_TRIVY_SEVERITY",
                  "value" => "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL"
                },
                %{
                  "name" => "SCANNER_TRIVY_IGNORE_UNFIXED",
                  "value" => "false"
                },
                %{
                  "name" => "SCANNER_TRIVY_SKIP_UPDATE",
                  "value" => "false"
                },
                %{
                  "name" => "SCANNER_TRIVY_OFFLINE_SCAN",
                  "value" => "false"
                },
                %{
                  "name" => "SCANNER_TRIVY_INSECURE",
                  "value" => "true"
                },
                %{
                  "name" => "SCANNER_API_SERVER_ADDR",
                  "value" => ":8080"
                },
                %{
                  "name" => "SCANNER_REDIS_URL",
                  "valueFrom" => %{
                    "secretKeyRef" => %{
                      "key" => "redisURL",
                      "name" => @trivy_secret
                    }
                  }
                },
                %{
                  "name" => "SCANNER_STORE_REDIS_URL",
                  "valueFrom" => %{
                    "secretKeyRef" => %{
                      "key" => "redisURL",
                      "name" => @trivy_secret
                    }
                  }
                },
                %{
                  "name" => "SCANNER_JOB_QUEUE_REDIS_URL",
                  "valueFrom" => %{
                    "secretKeyRef" => %{
                      "key" => "redisURL",
                      "name" => @trivy_secret
                    }
                  }
                }
              ],
              "image" => trivy_adapter_image,
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
              "ports" => [
                %{
                  "containerPort" => 8080,
                  "name" => "api-server"
                }
              ],
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
                "limits" => %{
                  "memory" => "1Gi"
                },
                "requests" => %{
                  "cpu" => "200m",
                  "memory" => "512Mi"
                }
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "privileged" => false
              },
              "volumeMounts" => [
                %{
                  "mountPath" => "/home/scanner/.cache",
                  "name" => "scanner-cache",
                  "readOnly" => false
                }
              ]
            }
          ],
          "securityContext" => %{
            "fsGroup" => 10_000,
            "runAsUser" => 10_000
          }
        }
      },
      "volumeClaimTemplates" => [
        %{
          "metadata" => %{
            "labels" => %{
              "component" => "trivy",
              "battery/app" => "harbor",
              "battery/managed" => "true"
            },
            "name" => "scanner-cache"
          },
          "spec" => %{
            "accessModes" => [
              "ReadWriteOnce"
            ],
            "resources" => %{
              "requests" => %{
                "storage" => "5Gi"
              }
            }
          }
        }
      ]
    }

    B.build_resource(:stateful_set)
    |> B.name("harbor-trivy")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("component", "trivy")
    |> B.spec(spec)
  end
end
