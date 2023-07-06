defmodule CommonCore.Resources.MetalLB do
  use CommonCore.IncludeResource,
    addresspools_metallb_io: "priv/manifests/metallb/addresspools_metallb_io.yaml",
    bfdprofiles_metallb_io: "priv/manifests/metallb/bfdprofiles_metallb_io.yaml",
    bgpadvertisements_metallb_io: "priv/manifests/metallb/bgpadvertisements_metallb_io.yaml",
    bgppeers_metallb_io: "priv/manifests/metallb/bgppeers_metallb_io.yaml",
    communities_metallb_io: "priv/manifests/metallb/communities_metallb_io.yaml",
    ipaddresspools_metallb_io: "priv/manifests/metallb/ipaddresspools_metallb_io.yaml",
    l2advertisements_metallb_io: "priv/manifests/metallb/l2advertisements_metallb_io.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "metallb"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  multi_resource(:ip_pool, _battery, state) do
    namespace = base_namespace(state)

    Enum.map(state.ip_address_pools, fn pool ->
      spec = %{
        addresses: [pool.subnet],
        # .0 and .255 are reserved for broadcast and network
        # when they are at the begining and ending of an ip
        # range historically.
        #
        # If there's no need for a broadcast
        # (for example on an explictly bridged network)
        # Or if there's no need for a network ip
        # (bridged network, or a split cidr range)
        # we could get away with using those ip's
        #
        # However there's enough crappy network equipmtment
        # that think these ips are bogons so, avoiding is better.
        avoidBuggyIPs: true
      }

      B.build_resource(:metal_ip_address_pool)
      |> B.name(pool.name)
      |> B.namespace(namespace)
      |> B.spec(spec)
    end)
  end

  resource(:l2, _battery, state) do
    namespace = base_namespace(state)
    spec = %{"ipAddressPools" => Enum.map(state.ip_address_pools, & &1.name)}

    B.build_resource(:metal_l2_advertisement)
    |> B.name("core")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:cluster_role_binding_controller, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("metallb:controller")
    |> B.role_ref(B.build_cluster_role_ref("metallb:controller"))
    |> B.subject(B.build_service_account("metallb-controller", namespace))
  end

  resource(:cluster_role_binding_speaker, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("metallb:speaker")
    |> B.role_ref(B.build_cluster_role_ref("metallb:speaker"))
    |> B.subject(B.build_service_account("metallb-speaker", namespace))
  end

  resource(:cluster_role_controller) do
    B.build_resource(:cluster_role)
    |> B.name("metallb:controller")
    |> B.rules([
      %{
        "apiGroups" => [""],
        "resources" => ["services", "namespaces"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["services/status"], "verbs" => ["update"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      }
    ])
  end

  resource(:cluster_role_speaker) do
    B.build_resource(:cluster_role)
    |> B.name("metallb:speaker")
    |> B.rules([
      %{
        "apiGroups" => [""],
        "resources" => ["services", "endpoints", "nodes", "namespaces"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ])
  end

  resource(:crd_addresspools_io) do
    YamlElixir.read_all_from_string!(get_resource(:addresspools_metallb_io))
  end

  resource(:crd_bfdprofiles_io) do
    YamlElixir.read_all_from_string!(get_resource(:bfdprofiles_metallb_io))
  end

  resource(:crd_bgpadvertisements_io) do
    YamlElixir.read_all_from_string!(get_resource(:bgpadvertisements_metallb_io))
  end

  resource(:crd_bgppeers_io) do
    YamlElixir.read_all_from_string!(get_resource(:bgppeers_metallb_io))
  end

  resource(:crd_communities_io) do
    YamlElixir.read_all_from_string!(get_resource(:communities_metallb_io))
  end

  resource(:crd_ipaddresspools_io) do
    YamlElixir.read_all_from_string!(get_resource(:ipaddresspools_metallb_io))
  end

  resource(:crd_l2advertisements_io) do
    YamlElixir.read_all_from_string!(get_resource(:l2advertisements_metallb_io))
  end

  resource(:daemon_set_speaker, battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:daemon_set)
    |> B.name("metallb-speaker")
    |> B.namespace(namespace)
    |> B.component_label("speaker")
    |> B.spec(%{
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "speaker"}
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app_name,
            "battery/component" => "speaker"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => ["--port=7472", "--log-level=info"],
              "env" => [
                %{
                  "name" => "METALLB_NODE_NAME",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
                },
                %{
                  "name" => "METALLB_HOST",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.hostIP"}}
                },
                %{
                  "name" => "METALLB_ML_BIND_ADDR",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
                },
                %{
                  "name" => "METALLB_ML_LABELS",
                  "value" => "battery/app=#{@app_name},battery/component=speaker"
                },
                %{"name" => "METALLB_ML_BIND_PORT", "value" => "7946"},
                %{
                  "name" => "METALLB_ML_SECRET_KEY",
                  "valueFrom" => %{
                    "secretKeyRef" => %{"key" => "secretkey", "name" => "metallb-memberlist"}
                  }
                }
              ],
              "image" => battery.config.speaker_image,
              "livenessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{"path" => "/metrics", "port" => "monitoring"},
                "initialDelaySeconds" => 10,
                "periodSeconds" => 10,
                "successThreshold" => 1,
                "timeoutSeconds" => 1
              },
              "name" => "speaker",
              "ports" => [
                %{"containerPort" => 7472, "name" => "monitoring"},
                %{"containerPort" => 7946, "name" => "memberlist-tcp", "protocol" => "TCP"},
                %{"containerPort" => 7946, "name" => "memberlist-udp", "protocol" => "UDP"}
              ],
              "readinessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{"path" => "/metrics", "port" => "monitoring"},
                "initialDelaySeconds" => 10,
                "periodSeconds" => 10,
                "successThreshold" => 1,
                "timeoutSeconds" => 1
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"add" => ["NET_RAW"], "drop" => ["ALL"]},
                "readOnlyRootFilesystem" => true
              }
            }
          ],
          "hostNetwork" => true,
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "serviceAccountName" => "metallb-speaker",
          "terminationGracePeriodSeconds" => 0,
          "tolerations" => [
            %{
              "effect" => "NoSchedule",
              "key" => "node-role.kubernetes.io/master",
              "operator" => "Exists"
            },
            %{
              "effect" => "NoSchedule",
              "key" => "node-role.kubernetes.io/control-plane",
              "operator" => "Exists"
            }
          ],
          "volumes" => nil
        }
      },
      "updateStrategy" => %{"type" => "RollingUpdate"}
    })
  end

  resource(:deployment_controller, battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:deployment)
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.component_label("controller")
    |> B.spec(%{
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "controller"}
      },
      "strategy" => %{"type" => "RollingUpdate"},
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app_name,
            "battery/component" => "controller",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "--port=7472",
                "--log-level=info",
                "--cert-service-name=metallb-webhook-service"
              ],
              "env" => [
                %{"name" => "METALLB_ML_SECRET_NAME", "value" => "metallb-memberlist"},
                %{"name" => "METALLB_DEPLOYMENT", "value" => "metallb-controller"}
              ],
              "image" => battery.config.controller_image,
              "livenessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{"path" => "/metrics", "port" => "monitoring"},
                "initialDelaySeconds" => 10,
                "periodSeconds" => 10,
                "successThreshold" => 1,
                "timeoutSeconds" => 1
              },
              "name" => "controller",
              "ports" => [
                %{"containerPort" => 7472, "name" => "monitoring"},
                %{"containerPort" => 9443, "name" => "webhook-server", "protocol" => "TCP"}
              ],
              "readinessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{"path" => "/metrics", "port" => "monitoring"},
                "initialDelaySeconds" => 10,
                "periodSeconds" => 10,
                "successThreshold" => 1,
                "timeoutSeconds" => 1
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "readOnlyRootFilesystem" => true
              },
              "volumeMounts" => [
                %{
                  "mountPath" => "/tmp/k8s-webhook-server/serving-certs",
                  "name" => "cert",
                  "readOnly" => true
                }
              ]
            }
          ],
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "securityContext" => %{
            "fsGroup" => 65_534,
            "runAsNonRoot" => true,
            "runAsUser" => 65_534
          },
          "serviceAccountName" => "metallb-controller",
          "terminationGracePeriodSeconds" => 0,
          "volumes" => [
            %{
              "name" => "cert",
              "secret" => %{"defaultMode" => 420, "secretName" => "webhook-server-cert"}
            }
          ]
        }
      }
    })
  end

  resource(:role_binding_controller, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.component_label("controller")
    |> B.role_ref(B.build_role_ref("metallb-controller"))
    |> B.subject(B.build_service_account("metallb-controller", namespace))
  end

  resource(:role_binding_pod_lister, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("metallb-pod-lister")
    |> B.namespace(namespace)
    |> B.component_label("speaker")
    |> B.role_ref(B.build_role_ref("metallb-pod-lister"))
    |> B.subject(B.build_service_account("metallb-speaker", namespace))
  end

  resource(:role_controller, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role)
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.rules([
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["create", "get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resourceNames" => ["metallb-memberlist"],
        "resources" => ["secrets"],
        "verbs" => ["list"]
      },
      %{
        "apiGroups" => ["apps"],
        "resourceNames" => ["metallb-controller"],
        "resources" => ["deployments"],
        "verbs" => ["get"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["addresspools"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["ipaddresspools"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => ["metallb.io"], "resources" => ["bgppeers"], "verbs" => ["get", "list"]},
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["bgpadvertisements"],
        "verbs" => ["get", "list"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["l2advertisements"],
        "verbs" => ["get", "list"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["communities"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["bfdprofiles"],
        "verbs" => ["get", "list", "watch"]
      }
    ])
  end

  resource(:role_pod_lister, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role)
    |> B.name("metallb-pod-lister")
    |> B.namespace(namespace)
    |> B.rules([
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["list"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["addresspools"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["bfdprofiles"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["bgppeers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["l2advertisements"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["bgpadvertisements"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["ipaddresspools"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["metallb.io"],
        "resources" => ["communities"],
        "verbs" => ["get", "list", "watch"]
      }
    ])
  end

  resource(:secret_webhook_server_cert, _battery, state) do
    namespace = base_namespace(state)
    data = %{}

    B.build_resource(:secret)
    |> B.name("webhook-server-cert")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_account_controller, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.component_label("controller")
  end

  resource(:service_account_speaker, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> B.name("metallb-speaker")
    |> B.namespace(namespace)
    |> B.component_label("speaker")
  end

  resource(:service_controller_monitor, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service)
    |> B.name("metallb-controller-monitor-service")
    |> B.namespace(namespace)
    |> B.component_label("controller")
    |> B.spec(%{
      "ports" => [%{"name" => "metrics", "port" => 7472, "targetPort" => 7472}],
      "selector" => %{"battery/app" => @app_name, "battery/component" => "controller"}
    })
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_monitor_controller, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:monitoring_service_monitor)
    |> B.name("metallb-controller-monitor")
    |> B.namespace(namespace)
    |> B.component_label("controller")
    |> B.spec(%{
      "jobLabel" => "app.kubernetes.io/name",
      "endpoints" => [%{"honorLabels" => true, "port" => "metrics"}],
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "controller"}
      }
    })
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_monitor_speaker, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:monitoring_service_monitor)
    |> B.name("metallb-speaker-monitor")
    |> B.namespace(namespace)
    |> B.component_label("speaker")
    |> B.spec(%{
      "jobLabel" => "app.kubernetes.io/name",
      "endpoints" => [%{"honorLabels" => true, "port" => "metrics"}],
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "speaker"}
      }
    })
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_speaker_monitor, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service)
    |> B.name("metallb-speaker-monitor-service")
    |> B.namespace(namespace)
    |> B.component_label("speaker")
    |> B.spec(%{
      "ports" => [%{"name" => "metrics", "port" => 7472, "targetPort" => 7472}],
      "selector" => %{"battery/app" => @app_name, "battery/component" => "speaker"}
    })
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:pod_monitor_controller, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:monitoring_pod_monitor)
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.component_label("controller")
    |> B.spec(%{
      "jobLabel" => "app.kubernetes.io/name",
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "podMetricsEndpoints" => [%{"path" => "/metrics", "port" => "monitoring"}],
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "controller"}
      }
    })
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:pod_monitor_speaker, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:monitoring_pod_monitor)
    |> B.name("metallb-speaker")
    |> B.namespace(namespace)
    |> B.component_label("speaker")
    |> B.spec(%{
      "jobLabel" => "app.kubernetes.io/name",
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "podMetricsEndpoints" => [%{"path" => "/metrics", "port" => "monitoring"}],
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "speaker"}
      }
    })
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_webhook, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service)
    |> B.name("metallb-webhook-service")
    |> B.namespace(namespace)
    |> B.spec(%{
      "ports" => [%{"port" => 443, "targetPort" => 9443}],
      "selector" => %{"battery/app" => @app_name, "battery/component" => "controller"}
    })
  end

  resource(:validating_webhook_config_configuration, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:validating_webhook_config)
    |> B.name("metallb-webhook-configuration")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "metallb-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-metallb-io-v1beta1-addresspool"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "addresspoolvalidationwebhook.metallb.io",
        "rules" => [
          %{
            "apiGroups" => ["metallb.io"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["addresspools"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "metallb-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-metallb-io-v1beta2-bgppeer"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "bgppeervalidationwebhook.metallb.io",
        "rules" => [
          %{
            "apiGroups" => ["metallb.io"],
            "apiVersions" => ["v1beta2"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["bgppeers"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "metallb-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-metallb-io-v1beta1-ipaddresspool"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "ipaddresspoolvalidationwebhook.metallb.io",
        "rules" => [
          %{
            "apiGroups" => ["metallb.io"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["ipaddresspools"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "metallb-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-metallb-io-v1beta1-bgpadvertisement"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "bgpadvertisementvalidationwebhook.metallb.io",
        "rules" => [
          %{
            "apiGroups" => ["metallb.io"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["bgpadvertisements"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "metallb-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-metallb-io-v1beta1-community"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "communityvalidationwebhook.metallb.io",
        "rules" => [
          %{
            "apiGroups" => ["metallb.io"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["communities"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "metallb-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-metallb-io-v1beta1-bfdprofile"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "bfdprofilevalidationwebhook.metallb.io",
        "rules" => [
          %{
            "apiGroups" => ["metallb.io"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "DELETE"],
            "resources" => ["bfdprofiles"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "metallb-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-metallb-io-v1beta1-l2advertisement"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "l2advertisementvalidationwebhook.metallb.io",
        "rules" => [
          %{
            "apiGroups" => ["metallb.io"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["l2advertisements"]
          }
        ],
        "sideEffects" => "None"
      }
    ])
  end
end
