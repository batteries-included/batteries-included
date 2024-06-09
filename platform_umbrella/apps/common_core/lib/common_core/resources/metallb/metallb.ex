defmodule CommonCore.Resources.MetalLB do
  @moduledoc false
  use CommonCore.IncludeResource,
    addresspools_metallb_io: "priv/manifests/metallb/addresspools_metallb_io.yaml",
    bfdprofiles_metallb_io: "priv/manifests/metallb/bfdprofiles_metallb_io.yaml",
    bgpadvertisements_metallb_io: "priv/manifests/metallb/bgpadvertisements_metallb_io.yaml",
    bgppeers_metallb_io: "priv/manifests/metallb/bgppeers_metallb_io.yaml",
    communities_metallb_io: "priv/manifests/metallb/communities_metallb_io.yaml",
    ipaddresspools_metallb_io: "priv/manifests/metallb/ipaddresspools_metallb_io.yaml",
    l2advertisements_metallb_io: "priv/manifests/metallb/l2advertisements_metallb_io.yaml",
    daemons: "priv/raw_files/metallb/daemons",
    excludel2_yaml: "priv/raw_files/metallb/excludel2.yaml",
    frr_conf: "priv/raw_files/metallb/frr.conf"

  use CommonCore.Resources.ResourceGenerator, app_name: "metallb"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret

  resource(:cluster_role_binding_controller, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("metallb:controller")
    |> B.role_ref(B.build_cluster_role_ref("metallb:controller"))
    |> B.subject(B.build_service_account("metallb-controller", namespace))
  end

  resource(:cluster_role_binding_speaker, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("metallb:speaker")
    |> B.role_ref(B.build_cluster_role_ref("metallb:speaker"))
    |> B.subject(B.build_service_account("metallb-speaker", namespace))
  end

  resource(:cluster_role_controller) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["services", "namespaces"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["list"]},
      %{"apiGroups" => [""], "resources" => ["services/status"], "verbs" => ["update"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resourceNames" => ["metallb-webhook-configuration"],
        "resources" => ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"],
        "verbs" => ["list", "watch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resourceNames" => [
          "addresspools.metallb.io",
          "bfdprofiles.metallb.io",
          "bgpadvertisements.metallb.io",
          "bgppeers.metallb.io",
          "ipaddresspools.metallb.io",
          "l2advertisements.metallb.io",
          "communities.metallb.io"
        ],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["list", "watch"]
      }
    ]

    :cluster_role |> B.build_resource() |> B.name("metallb:controller") |> B.rules(rules)
  end

  resource(:cluster_role_speaker) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["services", "endpoints", "nodes", "namespaces"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => ["discovery.k8s.io"], "resources" => ["endpointslices"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    :cluster_role |> B.build_resource() |> B.name("metallb:speaker") |> B.rules(rules)
  end

  resource(:config_map_excludel2, _battery, state) do
    namespace = base_namespace(state)
    data = Map.put(%{}, "excludel2.yaml", get_resource(:excludel2_yaml))

    :config_map
    |> B.build_resource()
    |> B.name("metallb-excludel2")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_frr_startup, _battery, state) do
    namespace = base_namespace(state)

    data =
      %{}
      |> Map.put("vtysh.conf", "service integrated-vtysh-config\n")
      |> Map.put("daemons", get_resource(:daemons))
      |> Map.put("frr.conf", get_resource(:frr_conf))

    :config_map
    |> B.build_resource()
    |> B.name("metallb-frr-startup")
    |> B.namespace(namespace)
    |> B.component_labels("speaker")
    |> B.data(data)
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

    template =
      %{
        "metadata" => %{
          "labels" => %{"battery/app" => @app_name, "battery/component" => "speaker", "battery/managed" => "true"}
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => ["--port=7472", "--log-level=debug"],
              "env" => [
                %{"name" => "METALLB_NODE_NAME", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}},
                %{"name" => "METALLB_HOST", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.hostIP"}}},
                %{"name" => "METALLB_ML_BIND_ADDR", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}},
                %{
                  "name" => "METALLB_ML_LABELS",
                  "value" => "app.kubernetes.io/name=metallb,app.kubernetes.io/component=speaker"
                },
                %{"name" => "METALLB_ML_BIND_PORT", "value" => "7946"},
                %{"name" => "METALLB_ML_SECRET_KEY_PATH", "value" => "/etc/ml_secret_key"},
                %{"name" => "FRR_CONFIG_FILE", "value" => "/etc/frr_reloader/frr.conf"},
                %{"name" => "FRR_RELOADER_PID_FILE", "value" => "/etc/frr_reloader/reloader.pid"},
                %{"name" => "METALLB_BGP_TYPE", "value" => "frr"}
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
              },
              "volumeMounts" => [
                %{"mountPath" => "/etc/ml_secret_key", "name" => "memberlist"},
                %{"mountPath" => "/etc/frr_reloader", "name" => "reloader"},
                %{"mountPath" => "/etc/metallb", "name" => "metallb-excludel2"}
              ]
            },
            %{
              "command" => [
                "/bin/sh",
                "-c",
                "/sbin/tini -- /usr/lib/frr/docker-start &\nattempts=0\nuntil [[ -f /etc/frr/frr.log || $attempts -eq 60 ]]; do\n  sleep 1\n  attempts=$(( $attempts + 1 ))\ndone\ntail -f /etc/frr/frr.log\n"
              ],
              "env" => [%{"name" => "TINI_SUBREAPER", "value" => "true"}],
              "image" => battery.config.frrouting_image,
              "livenessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{"path" => "/livez", "port" => 7473},
                "initialDelaySeconds" => 10,
                "periodSeconds" => 10,
                "successThreshold" => 1,
                "timeoutSeconds" => 1
              },
              "name" => "frr",
              "securityContext" => %{
                "capabilities" => %{"add" => ["NET_ADMIN", "NET_RAW", "SYS_ADMIN", "NET_BIND_SERVICE"]}
              },
              "startupProbe" => %{
                "failureThreshold" => 30,
                "httpGet" => %{"path" => "/livez", "port" => 7473},
                "periodSeconds" => 5
              },
              "volumeMounts" => [
                %{"mountPath" => "/var/run/frr", "name" => "frr-sockets"},
                %{"mountPath" => "/etc/frr", "name" => "frr-conf"}
              ]
            },
            %{
              "command" => ["/etc/frr_reloader/frr-reloader.sh"],
              "image" => battery.config.frrouting_image,
              "name" => "reloader",
              "volumeMounts" => [
                %{"mountPath" => "/var/run/frr", "name" => "frr-sockets"},
                %{"mountPath" => "/etc/frr", "name" => "frr-conf"},
                %{"mountPath" => "/etc/frr_reloader", "name" => "reloader"}
              ]
            },
            %{
              "args" => ["--metrics-port=7473"],
              "command" => ["/etc/frr_metrics/frr-metrics"],
              "image" => battery.config.frrouting_image,
              "name" => "frr-metrics",
              "ports" => [%{"containerPort" => 7473, "name" => "monitoring"}],
              "volumeMounts" => [
                %{"mountPath" => "/var/run/frr", "name" => "frr-sockets"},
                %{"mountPath" => "/etc/frr", "name" => "frr-conf"},
                %{"mountPath" => "/etc/frr_metrics", "name" => "metrics"}
              ]
            }
          ],
          "hostNetwork" => true,
          "initContainers" => [
            %{
              "command" => ["/bin/sh", "-c", "cp -rLf /tmp/frr/* /etc/frr/"],
              "image" => battery.config.frrouting_image,
              "name" => "cp-frr-files",
              "securityContext" => %{"runAsGroup" => 101, "runAsUser" => 100},
              "volumeMounts" => [
                %{"mountPath" => "/tmp/frr", "name" => "frr-startup"},
                %{"mountPath" => "/etc/frr", "name" => "frr-conf"}
              ]
            },
            %{
              "command" => ["/bin/sh", "-c", "cp -f /frr-reloader.sh /etc/frr_reloader/"],
              "image" => battery.config.speaker_image,
              "name" => "cp-reloader",
              "volumeMounts" => [%{"mountPath" => "/etc/frr_reloader", "name" => "reloader"}]
            },
            %{
              "command" => ["/bin/sh", "-c", "cp -f /frr-metrics /etc/frr_metrics/"],
              "image" => battery.config.speaker_image,
              "name" => "cp-metrics",
              "volumeMounts" => [%{"mountPath" => "/etc/frr_metrics", "name" => "metrics"}]
            }
          ],
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "serviceAccountName" => "metallb-speaker",
          "shareProcessNamespace" => true,
          "terminationGracePeriodSeconds" => 0,
          "tolerations" => [
            %{"effect" => "NoSchedule", "key" => "node-role.kubernetes.io/master", "operator" => "Exists"},
            %{"effect" => "NoSchedule", "key" => "node-role.kubernetes.io/control-plane", "operator" => "Exists"}
          ],
          "volumes" => [
            %{"name" => "memberlist", "secret" => %{"defaultMode" => 420, "secretName" => "metallb-memberlist"}},
            %{"configMap" => %{"defaultMode" => 256, "name" => "metallb-excludel2"}, "name" => "metallb-excludel2"},
            %{"emptyDir" => %{}, "name" => "frr-sockets"},
            %{"configMap" => %{"name" => "metallb-frr-startup"}, "name" => "frr-startup"},
            %{"emptyDir" => %{}, "name" => "frr-conf"},
            %{"emptyDir" => %{}, "name" => "reloader"},
            %{"emptyDir" => %{}, "name" => "metrics"}
          ]
        }
      }
      |> B.app_labels(@app_name)
      |> B.component_labels("speaker")
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "speaker"}})
      |> B.template(template)
      |> Map.put("updateStrategy", %{"type" => "RollingUpdate"})

    :daemon_set
    |> B.build_resource()
    |> B.name("metallb-speaker")
    |> B.namespace(namespace)
    |> B.component_labels("speaker")
    |> B.spec(spec)
  end

  resource(:deployment_controller, battery, state) do
    namespace = base_namespace(state)

    template =
      %{
        "metadata" => %{
          "labels" => %{"battery/app" => @app_name, "battery/component" => "controller", "battery/managed" => "true"}
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => ["--port=7472", "--log-level=info", "--cert-service-name=metallb-webhook-service"],
              "env" => [
                %{"name" => "METALLB_ML_SECRET_NAME", "value" => "metallb-memberlist"},
                %{"name" => "METALLB_DEPLOYMENT", "value" => "metallb-controller"},
                %{"name" => "METALLB_BGP_TYPE", "value" => "frr"}
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
                %{"mountPath" => "/tmp/k8s-webhook-server/serving-certs", "name" => "cert", "readOnly" => true}
              ]
            }
          ],
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "securityContext" => %{"fsGroup" => 65_534, "runAsNonRoot" => true, "runAsUser" => 65_534},
          "serviceAccountName" => "metallb-controller",
          "terminationGracePeriodSeconds" => 0,
          "volumes" => [%{"name" => "cert", "secret" => %{"defaultMode" => 420, "secretName" => "webhook-server-cert"}}]
        }
      }
      |> B.app_labels(@app_name)
      |> B.component_labels("controller")
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "controller"}}
      )
      |> Map.put("strategy", %{"type" => "RollingUpdate"})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.component_labels("controller")
    |> B.spec(spec)
  end

  resource(:monitoring_pod_monitor_controller, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("jobLabel", "app.kubernetes.io/name")
      |> Map.put("podMetricsEndpoints", [%{"path" => "/metrics", "port" => "monitoring"}])
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "controller"}})

    :monitoring_pod_monitor
    |> B.build_resource()
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.component_labels("controller")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:monitoring_pod_monitor_speaker, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("jobLabel", "app.kubernetes.io/name")
      |> Map.put("podMetricsEndpoints", [%{"path" => "/metrics", "port" => "monitoring"}])
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "speaker"}})

    :monitoring_pod_monitor
    |> B.build_resource()
    |> B.name("metallb-speaker")
    |> B.namespace(namespace)
    |> B.component_labels("speaker")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:role_binding_controller, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("metallb-controller"))
    |> B.subject(B.build_service_account("metallb-controller", namespace))
  end

  resource(:role_binding_pod_lister, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("metallb-pod-lister")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("metallb-pod-lister"))
    |> B.subject(B.build_service_account("metallb-speaker", namespace))
  end

  resource(:role_controller, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["create", "get", "list", "watch"]},
      %{"apiGroups" => [""], "resourceNames" => ["metallb-memberlist"], "resources" => ["secrets"], "verbs" => ["list"]},
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
      %{"apiGroups" => ["metallb.io"], "resources" => ["addresspools"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["ipaddresspools"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["bgppeers"], "verbs" => ["get", "list"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["bgpadvertisements"], "verbs" => ["get", "list"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["l2advertisements"], "verbs" => ["get", "list"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["communities"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["bfdprofiles"], "verbs" => ["get", "list", "watch"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_pod_lister, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["list"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["addresspools"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["bfdprofiles"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["bgppeers"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["l2advertisements"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["bgpadvertisements"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["ipaddresspools"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["metallb.io"], "resources" => ["communities"], "verbs" => ["get", "list", "watch"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("metallb-pod-lister")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:secret_webhook_server_cert, _battery, state) do
    namespace = base_namespace(state)
    data = Secret.encode(%{})

    :secret
    |> B.build_resource()
    |> B.name("webhook-server-cert")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_account_controller, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("metallb-controller")
    |> B.namespace(namespace)
    |> B.component_labels("controller")
  end

  resource(:service_account_speaker, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("metallb-speaker")
    |> B.namespace(namespace)
    |> B.component_labels("speaker")
  end

  resource(:service_webhook, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"port" => 443, "targetPort" => 9443}])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "controller"})

    :service
    |> B.build_resource()
    |> B.name("metallb-webhook-service")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:validating_webhook_config_configuration, _battery, state) do
    namespace = base_namespace(state)

    :validating_webhook_config
    |> B.build_resource()
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
