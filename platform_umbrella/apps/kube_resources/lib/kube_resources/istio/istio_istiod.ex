defmodule KubeResources.IstioIstiod do
  use CommonCore.IncludeResource,
    config: "priv/raw_files/istio_istiod/config",
    values: "priv/raw_files/istio_istiod/values"

  use KubeExt.ResourceGenerator, app_name: "istiod"

  import CommonCore.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  resource(:cluster_role_binding_istio_reader_clusterrole_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("istio-reader-clusterrole-battery-istio")
    |> B.component_label("istio-reader")
    |> B.role_ref(B.build_cluster_role_ref("istio-reader-clusterrole-battery-istio"))
    |> B.subject(B.build_service_account("istio-reader-service-account", namespace))
  end

  resource(:cluster_role_binding_istiod_clusterrole_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("istiod-clusterrole-battery-istio")
    |> B.component_label("istiod")
    |> B.role_ref(B.build_cluster_role_ref("istiod-clusterrole-battery-istio"))
    |> B.subject(B.build_service_account("istiod", namespace))
  end

  resource(:cluster_role_binding_istiod_gateway_controller_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("istiod-gateway-controller-battery-istio")
    |> B.component_label("istiod")
    |> B.role_ref(B.build_cluster_role_ref("istiod-gateway-controller-battery-istio"))
    |> B.subject(B.build_service_account("istiod", namespace))
  end

  resource(:cluster_role_istio_reader_clusterrole_battery_istio) do
    B.build_resource(:cluster_role)
    |> B.name("istio-reader-clusterrole-battery-istio")
    |> B.component_label("istio-reader")
    |> B.rules([
      %{
        "apiGroups" => [
          "config.istio.io",
          "security.istio.io",
          "networking.istio.io",
          "authentication.istio.io",
          "rbac.istio.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "endpoints",
          "pods",
          "services",
          "nodes",
          "replicationcontrollers",
          "namespaces",
          "secrets"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceexports"],
        "verbs" => ["get", "list", "watch", "create", "delete"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceimports"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["replicasets"],
        "verbs" => ["get", "list", "watch"]
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
      }
    ])
  end

  resource(:cluster_role_istiod_clusterrole_battery_istio) do
    B.build_resource(:cluster_role)
    |> B.name("istiod-clusterrole-battery-istio")
    |> B.component_label("istiod")
    |> B.rules([
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["mutatingwebhookconfigurations"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations"],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => [
          "config.istio.io",
          "security.istio.io",
          "networking.istio.io",
          "authentication.istio.io",
          "rbac.istio.io",
          "telemetry.istio.io",
          "extensions.istio.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries/status"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["pods", "nodes", "services", "namespaces", "endpoints"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses", "ingressclasses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses/status"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["create", "get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => ["certificates.k8s.io"],
        "resources" => [
          "certificatesigningrequests",
          "certificatesigningrequests/approval",
          "certificatesigningrequests/status"
        ],
        "verbs" => ["update", "create", "get", "delete", "watch"]
      },
      %{
        "apiGroups" => ["certificates.k8s.io"],
        "resourceNames" => ["kubernetes.io/legacy-unknown"],
        "resources" => ["signers"],
        "verbs" => ["approve"]
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
        "apiGroups" => ["networking.x-k8s.io", "gateway.networking.k8s.io"],
        "resources" => ["*"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["networking.x-k8s.io", "gateway.networking.k8s.io"],
        "resources" => ["*"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => ["gatewayclasses"],
        "verbs" => ["create", "update", "patch", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "watch", "list"]},
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceexports"],
        "verbs" => ["get", "watch", "list", "create", "delete"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceimports"],
        "verbs" => ["get", "watch", "list"]
      }
    ])
  end

  resource(:cluster_role_istiod_gateway_controller_battery_istio) do
    B.build_resource(:cluster_role)
    |> B.name("istiod-gateway-controller-battery-istio")
    |> B.component_label("istiod")
    |> B.rules([
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["services"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      }
    ])
  end

  resource(:config_map_istio, _battery, state) do
    namespace = istio_namespace(state)

    data =
      %{}
      |> Map.put(
        "mesh",
        "defaultConfig:\n  discoveryAddress: istiod.#{namespace}.svc:15012\n  tracing:\n    zipkin:\n      address: zipkin.battery-istio:9411\nenablePrometheusMerge: true\nrootNamespace: null\ntrustDomain: cluster.local"
      )
      |> Map.put("meshNetworks", "networks: {}")

    B.build_resource(:config_map)
    |> B.name("istio")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.data(data)
  end

  resource(:config_map_istio_sidecar_injector, _battery, state) do
    namespace = istio_namespace(state)

    data =
      %{} |> Map.put("config", get_resource(:config)) |> Map.put("values", get_resource(:values))

    B.build_resource(:config_map)
    |> B.name("istio-sidecar-injector")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.data(data)
  end

  resource(:deployment_istiod, battery, state) do
    namespace = istio_namespace(state)

    volumes = [
      %{"emptyDir" => %{"medium" => "Memory"}, "name" => "local-certs"},
      %{
        "name" => "istio-token",
        "projected" => %{
          "sources" => [
            %{
              "serviceAccountToken" => %{
                "audience" => "istio-ca",
                "expirationSeconds" => 43_200,
                "path" => "istio-token"
              }
            }
          ]
        }
      },
      %{"name" => "cacerts", "secret" => %{"optional" => true, "secretName" => "cacerts"}},
      %{
        "name" => "istio-kubeconfig",
        "secret" => %{"optional" => true, "secretName" => "istio-kubeconfig"}
      }
    ]

    # Every container shares the same env.
    env = [
      %{"name" => "REVISION", "value" => "default"},
      %{"name" => "JWT_POLICY", "value" => "third-party-jwt"},
      %{"name" => "PILOT_CERT_PROVIDER", "value" => "istiod"},
      %{
        "name" => "POD_NAME",
        "valueFrom" => %{
          "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.name"}
        }
      },
      %{
        "name" => "POD_NAMESPACE",
        "valueFrom" => %{
          "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.namespace"}
        }
      },
      %{
        "name" => "SERVICE_ACCOUNT",
        "valueFrom" => %{
          "fieldRef" => %{
            "apiVersion" => "v1",
            "fieldPath" => "spec.serviceAccountName"
          }
        }
      },
      %{"name" => "KUBECONFIG", "value" => "/var/run/secrets/remote/config"},
      %{"name" => "PILOT_TRACE_SAMPLING", "value" => "1"},
      %{"name" => "PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_OUTBOUND", "value" => "true"},
      %{"name" => "PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_INBOUND", "value" => "true"},
      %{"name" => "ISTIOD_ADDR", "value" => "istiod.#{namespace}.svc:15012"},
      %{"name" => "PILOT_ENABLE_ANALYSIS", "value" => "false"},
      %{"name" => "CLUSTER_ID", "value" => "Kubernetes"}
    ]

    args = [
      "discovery",
      "--monitoringAddr=:15014",
      "--log_output_level=default:info",
      "--domain",
      "cluster.local",
      "--keepaliveMaxServerConnectionAge",
      "30m"
    ]

    volume_mounts = [
      %{
        "mountPath" => "/var/run/secrets/tokens",
        "name" => "istio-token",
        "readOnly" => true
      },
      %{"mountPath" => "/var/run/secrets/istio-dns", "name" => "local-certs"},
      %{"mountPath" => "/etc/cacerts", "name" => "cacerts", "readOnly" => true},
      %{
        "mountPath" => "/var/run/secrets/remote",
        "name" => "istio-kubeconfig",
        "readOnly" => true
      }
    ]

    containers = [
      %{
        "args" => args,
        "env" => env,
        "image" => battery.config.pilot_image,
        "name" => "discovery",
        "ports" => [
          %{"containerPort" => 8080, "protocol" => "TCP"},
          %{"containerPort" => 15_010, "protocol" => "TCP"},
          %{"containerPort" => 15_017, "protocol" => "TCP"}
        ],
        "readinessProbe" => %{
          "httpGet" => %{"path" => "/ready", "port" => 8080},
          "initialDelaySeconds" => 1,
          "periodSeconds" => 3,
          "timeoutSeconds" => 5
        },
        "resources" => %{"requests" => %{"cpu" => "500m", "memory" => "2048Mi"}},
        "securityContext" => %{
          "allowPrivilegeEscalation" => false,
          "capabilities" => %{"drop" => ["ALL"]},
          "readOnlyRootFilesystem" => true,
          "runAsGroup" => 1337,
          "runAsNonRoot" => true,
          "runAsUser" => 1337
        },
        "volumeMounts" => volume_mounts
      }
    ]

    template = %{
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "sidecar.istio.io/inject" => "false"
        }
      },
      "spec" => %{
        "containers" => containers,
        "securityContext" => %{"fsGroup" => 1337},
        "serviceAccountName" => "istiod",
        "volumes" => volumes
      }
    }

    spec = %{
      "selector" => %{"matchLabels" => %{"istio" => "pilot"}},
      "strategy" => %{"rollingUpdate" => %{"maxSurge" => "100%", "maxUnavailable" => "25%"}},
      "template" => template
    }

    B.build_resource(:deployment)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.component_label("istiod")
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.label("sidecar.istio.io/inject", "false")
    |> B.spec(spec)
  end

  resource(:horizontal_pod_autoscaler_istiod, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:horizontal_pod_autoscaler)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.component_label("istiod")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.spec(%{
      "maxReplicas" => 5,
      "metrics" => [
        %{
          "resource" => %{
            "name" => "cpu",
            "target" => %{"averageUtilization" => 80, "type" => "Utilization"}
          },
          "type" => "Resource"
        }
      ],
      "minReplicas" => 1,
      "scaleTargetRef" => %{"apiVersion" => "apps/v1", "kind" => "Deployment", "name" => "istiod"}
    })
  end

  resource(:istio_envoy_filter_stats_1_13, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:istio_envoy_filter)
    |> B.name("stats-filter-1.13")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.spec(%{
      "configPatches" => [
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "SIDECAR_OUTBOUND",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.13.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_outbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "SIDECAR_INBOUND",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.13.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" =>
                        "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                    },
                    "root_id" => "stats_inbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_inbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "GATEWAY",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.13.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" =>
                        "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_outbound"
                    }
                  }
                }
              }
            }
          }
        }
      ],
      "priority" => -1
    })
  end

  resource(:istio_envoy_filter_stats_1_14, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:istio_envoy_filter)
    |> B.name("stats-filter-1.14")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.spec(%{
      "configPatches" => [
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "SIDECAR_OUTBOUND",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.14.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_outbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "SIDECAR_INBOUND",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.14.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" =>
                        "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                    },
                    "root_id" => "stats_inbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_inbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "GATEWAY",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.14.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" =>
                        "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_outbound"
                    }
                  }
                }
              }
            }
          }
        }
      ],
      "priority" => -1
    })
  end

  resource(:istio_envoy_filter_stats_1_15, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:istio_envoy_filter)
    |> B.name("stats-filter-1.15")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.spec(%{
      "configPatches" => [
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "SIDECAR_OUTBOUND",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.15.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_outbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "SIDECAR_INBOUND",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.15.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" =>
                        "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                    },
                    "root_id" => "stats_inbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_inbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "HTTP_FILTER",
          "match" => %{
            "context" => "GATEWAY",
            "listener" => %{
              "filterChain" => %{
                "filter" => %{
                  "name" => "envoy.filters.network.http_connection_manager",
                  "subFilter" => %{"name" => "envoy.filters.http.router"}
                }
              }
            },
            "proxy" => %{"proxyVersion" => "^1\\.15.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" =>
                        "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "stats_outbound"
                    }
                  }
                }
              }
            }
          }
        }
      ],
      "priority" => -1
    })
  end

  resource(:istio_envoy_filter_tcp_stats_1_13, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:istio_envoy_filter)
    |> B.name("tcp-stats-filter-1.13")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.spec(%{
      "configPatches" => [
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "SIDECAR_INBOUND",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.13.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_inbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_inbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "SIDECAR_OUTBOUND",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.13.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_outbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "GATEWAY",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.13.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_outbound"
                    }
                  }
                }
              }
            }
          }
        }
      ],
      "priority" => -1
    })
  end

  resource(:istio_envoy_filter_tcp_stats_1_14, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:istio_envoy_filter)
    |> B.name("tcp-stats-filter-1.14")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.spec(%{
      "configPatches" => [
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "SIDECAR_INBOUND",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.14.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_inbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_inbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "SIDECAR_OUTBOUND",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.14.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_outbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "GATEWAY",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.14.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_outbound"
                    }
                  }
                }
              }
            }
          }
        }
      ],
      "priority" => -1
    })
  end

  resource(:istio_envoy_filter_tcp_stats_1_15, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:istio_envoy_filter)
    |> B.name("tcp-stats-filter-1.15")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.spec(%{
      "configPatches" => [
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "SIDECAR_INBOUND",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.15.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_inbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_inbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "SIDECAR_OUTBOUND",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.15.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_outbound"
                    }
                  }
                }
              }
            }
          }
        },
        %{
          "applyTo" => "NETWORK_FILTER",
          "match" => %{
            "context" => "GATEWAY",
            "listener" => %{
              "filterChain" => %{"filter" => %{"name" => "envoy.filters.network.tcp_proxy"}}
            },
            "proxy" => %{"proxyVersion" => "^1\\.15.*"}
          },
          "patch" => %{
            "operation" => "INSERT_BEFORE",
            "value" => %{
              "name" => "istio.stats",
              "typed_config" => %{
                "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                "type_url" => "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                "value" => %{
                  "config" => %{
                    "configuration" => %{
                      "@type" => "type.googleapis.com/google.protobuf.StringValue",
                      "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                    },
                    "root_id" => "stats_outbound",
                    "vm_config" => %{
                      "code" => %{"local" => %{"inline_string" => "envoy.wasm.stats"}},
                      "runtime" => "envoy.wasm.runtime.null",
                      "vm_id" => "tcp_stats_outbound"
                    }
                  }
                }
              }
            }
          }
        }
      ],
      "priority" => -1
    })
  end

  resource(:mutating_webhook_config_istio_sidecar_injector_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:mutating_webhook_config)
    |> B.name("istio-sidecar-injector-battery-istio")
    |> B.component_label("sidecar-injector")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "istiod",
            "namespace" => namespace,
            "path" => "/inject",
            "port" => 443
          }
        },
        "failurePolicy" => "Fail",
        "name" => "rev.namespace.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "istio.io/rev", "operator" => "In", "values" => ["default"]},
            %{"key" => "istio-injection", "operator" => "DoesNotExist"}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "sidecar.istio.io/inject", "operator" => "NotIn", "values" => ["false"]}
          ]
        },
        "rules" => [
          %{
            "apiGroups" => [""],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE"],
            "resources" => ["pods"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "istiod",
            "namespace" => namespace,
            "path" => "/inject",
            "port" => 443
          }
        },
        "failurePolicy" => "Fail",
        "name" => "rev.object.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "istio.io/rev", "operator" => "DoesNotExist"},
            %{"key" => "istio-injection", "operator" => "DoesNotExist"}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "sidecar.istio.io/inject", "operator" => "NotIn", "values" => ["false"]},
            %{"key" => "istio.io/rev", "operator" => "In", "values" => ["default"]}
          ]
        },
        "rules" => [
          %{
            "apiGroups" => [""],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE"],
            "resources" => ["pods"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "istiod",
            "namespace" => namespace,
            "path" => "/inject",
            "port" => 443
          }
        },
        "failurePolicy" => "Fail",
        "name" => "namespace.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "istio-injection", "operator" => "In", "values" => ["enabled"]}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "sidecar.istio.io/inject", "operator" => "NotIn", "values" => ["false"]}
          ]
        },
        "rules" => [
          %{
            "apiGroups" => [""],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE"],
            "resources" => ["pods"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "istiod",
            "namespace" => namespace,
            "path" => "/inject",
            "port" => 443
          }
        },
        "failurePolicy" => "Fail",
        "name" => "object.sidecar-injector.istio.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "istio-injection", "operator" => "DoesNotExist"},
            %{"key" => "istio.io/rev", "operator" => "DoesNotExist"}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "sidecar.istio.io/inject", "operator" => "In", "values" => ["true"]},
            %{"key" => "istio.io/rev", "operator" => "DoesNotExist"}
          ]
        },
        "rules" => [
          %{
            "apiGroups" => [""],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE"],
            "resources" => ["pods"]
          }
        ],
        "sideEffects" => "None"
      }
    ])
  end

  resource(:pod_disruption_budget_istiod, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:pod_disruption_budget)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.component_label("istiod")
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.spec(%{
      "minAvailable" => 1,
      "selector" => %{"matchLabels" => %{"app" => "istiod", "istio" => "pilot"}}
    })
  end

  resource(:role_binding_istiod, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.component_label("istiod")
    |> B.role_ref(B.build_role_ref("istiod"))
    |> B.subject(B.build_service_account("istiod", namespace))
  end

  resource(:role_istiod, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:role)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.component_label("istiod")
    |> B.rules([
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["gateways"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["create", "get", "watch", "list", "update", "delete"]
      }
    ])
  end

  resource(:service_account_istiod, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:service_account)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.component_label("istiod")
  end

  resource(:service_istiod, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:service)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.component_label("istiod")
    |> B.label("istio", "pilot")
    |> B.label("istio.io/rev", "default")
    |> B.spec(%{
      "ports" => [
        %{"name" => "grpc-xds", "port" => 15_010, "protocol" => "TCP"},
        %{"name" => "https-dns", "port" => 15_012, "protocol" => "TCP"},
        %{"name" => "https-webhook", "port" => 443, "protocol" => "TCP", "targetPort" => 15_017},
        %{"name" => "http-monitoring", "port" => 15_014, "protocol" => "TCP"}
      ],
      "selector" => %{"app" => @app_name, "istio" => "pilot"}
    })
  end
end
