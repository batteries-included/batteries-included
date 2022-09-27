defmodule KubeResources.Loki do
  use KubeExt.IncludeResource,
    datasource_yaml: "priv/raw_files/loki/datasource.yaml",
    grafanaagents_monitoring_grafana_com:
      "priv/manifests/loki/grafanaagents_monitoring_grafana_com.yaml",
    integrations_monitoring_grafana_com:
      "priv/manifests/loki/integrations_monitoring_grafana_com.yaml",
    logsinstances_monitoring_grafana_com:
      "priv/manifests/loki/logsinstances_monitoring_grafana_com.yaml",
    metricsinstances_monitoring_grafana_com:
      "priv/manifests/loki/metricsinstances_monitoring_grafana_com.yaml",
    podlogs_monitoring_grafana_com: "priv/manifests/loki/podlogs_monitoring_grafana_com.yaml",
    podmonitors_monitoring_coreos_com:
      "priv/manifests/loki/podmonitors_monitoring_coreos_com.yaml",
    probes_monitoring_coreos_com: "priv/manifests/loki/probes_monitoring_coreos_com.yaml",
    prometheusrules_monitoring_coreos_com:
      "priv/manifests/loki/prometheusrules_monitoring_coreos_com.yaml",
    servicemonitors_monitoring_coreos_com:
      "priv/manifests/loki/servicemonitors_monitoring_coreos_com.yaml",
    dashboard_json: "priv/raw_files/loki/loki-dashboard_rev1.json",
    config_yaml: "priv/raw_files/loki/config.yaml"

  use KubeExt.ResourceGenerator

  import KubeExt.Yaml

  alias KubeResources.MonitoringSettings, as: Settings

  @app "loki"

  resource(:cluster_role_binding_grafana_agent, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name("loki-grafana-agent")
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref("loki-grafana-agent"))
    |> B.subject(B.build_service_account("loki-grafana-agent", namespace))
  end

  resource(:cluster_role_binding_grafana_agent_operator, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name("loki-grafana-agent-operator")
    |> B.app_labels(@app)
    |> B.component_label("grafana-agent-operator")
    |> B.role_ref(B.build_cluster_role_ref("loki-grafana-agent-operator"))
    |> B.subject(B.build_service_account("loki-grafana-agent-operator", namespace))
  end

  resource(:cluster_role_grafana_agent) do
    B.build_resource(:cluster_role)
    |> B.name("loki-grafana-agent")
    |> B.app_labels(@app)
    |> B.rules([
      %{
        "apiGroups" => [""],
        "resources" => [
          "nodes",
          "nodes/proxy",
          "nodes/metrics",
          "services",
          "endpoints",
          "pods",
          "events"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"nonResourceURLs" => ["/metrics", "/metrics/cadvisor"], "verbs" => ["get"]}
    ])
  end

  resource(:cluster_role_grafana_agent_operator) do
    B.build_resource(:cluster_role)
    |> B.name("loki-grafana-agent-operator")
    |> B.app_labels(@app)
    |> B.component_label("grafana-agent-operator")
    |> B.rules([
      %{
        "apiGroups" => ["monitoring.grafana.com"],
        "resources" => [
          "grafanaagents",
          "metricsinstances",
          "logsinstances",
          "podlogs",
          "integrations"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["monitoring.grafana.com"],
        "resources" => [
          "grafanaagents/finalizers",
          "metricsinstances/finalizers",
          "logsinstances/finalizers",
          "podlogs/finalizers",
          "integrations/finalizers"
        ],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => ["monitoring.coreos.com"],
        "resources" => ["podmonitors", "probes", "servicemonitors"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["monitoring.coreos.com"],
        "resources" => [
          "podmonitors/finalizers",
          "probes/finalizers",
          "servicemonitors/finalizers"
        ],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces", "nodes"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["secrets", "services", "configmaps", "endpoints"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["statefulsets", "daemonsets", "deployments"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      }
    ])
  end

  resource(:config_map_main, config) do
    namespace = Settings.namespace(config)
    data = %{"config.yaml" => get_resource(:config_yaml)}

    B.build_resource(:config_map)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  resource(:crd_grafanaagents_monitoring_grafana_com) do
    yaml(get_resource(:grafanaagents_monitoring_grafana_com))
  end

  resource(:crd_integrations_monitoring_grafana_com) do
    yaml(get_resource(:integrations_monitoring_grafana_com))
  end

  resource(:crd_logsinstances_monitoring_grafana_com) do
    yaml(get_resource(:logsinstances_monitoring_grafana_com))
  end

  resource(:crd_metricsinstances_monitoring_grafana_com) do
    yaml(get_resource(:metricsinstances_monitoring_grafana_com))
  end

  resource(:crd_podlogs_monitoring_grafana_com) do
    yaml(get_resource(:podlogs_monitoring_grafana_com))
  end

  resource(:crd_podmonitors_monitoring_coreos_com) do
    yaml(get_resource(:podmonitors_monitoring_coreos_com))
  end

  resource(:crd_probes_monitoring_coreos_com) do
    yaml(get_resource(:probes_monitoring_coreos_com))
  end

  resource(:crd_prometheusrules_monitoring_coreos_com) do
    yaml(get_resource(:prometheusrules_monitoring_coreos_com))
  end

  resource(:crd_servicemonitors_monitoring_coreos_com) do
    yaml(get_resource(:servicemonitors_monitoring_coreos_com))
  end

  resource(:deployment_grafana_agent_operator, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:deployment)
    |> B.name("loki-grafana-agent-operator")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.component_label("grafana-agent-operator")
    |> B.spec(%{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "loki",
          "battery/component" => "grafana-agent-operator"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "loki",
            "battery/component" => "grafana-agent-operator",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => ["--kubelet-service=default/kubelet"],
              "image" => "docker.io/grafana/agent-operator:v0.25.1",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "grafana-agent-operator"
            }
          ],
          "serviceAccountName" => "loki-grafana-agent-operator"
        }
      }
    })
  end

  resource(:grafana_agent_main, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:grafana_agent)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label("loki")
    |> B.spec(%{
      "enableConfigReadAPI" => false,
      "logs" => %{
        "instanceSelector" => %{
          "matchLabels" => %{
            "battery/app" => @app,
            "battery/component" => "loki"
          }
        }
      },
      "serviceAccountName" => "loki-grafana-agent"
    })
  end

  resource(:logs_instance_main, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:logs_instance)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label("loki")
    |> B.spec(%{
      "clients" => [
        %{
          "externalLabels" => %{"cluster" => "loki"},
          "url" => "http://loki.battery-core.svc.cluster.local:3100/loki/api/v1/push"
        }
      ],
      "podLogsSelector" => %{"matchLabels" => %{"instance" => "primary"}}
    })
  end

  resource(:pod_logs_main, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:pod_logs)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("instance", "primary")
    |> B.spec(%{
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "pipelineStages" => [%{"cri" => %{}}],
      "relabelings" => [
        %{"sourceLabels" => ["__meta_kubernetes_pod_node_name"], "targetLabel" => "__host__"},
        %{"action" => "labelmap", "regex" => "__meta_kubernetes_pod_label_(.+)"},
        %{
          "action" => "replace",
          "replacement" => "battery-core/$1",
          "sourceLabels" => ["__meta_kubernetes_pod_controller_name"],
          "targetLabel" => "job"
        },
        %{
          "action" => "replace",
          "sourceLabels" => ["__meta_kubernetes_pod_container_name"],
          "targetLabel" => "container"
        },
        %{"replacement" => "loki", "targetLabel" => "cluster"}
      ],
      "selector" => %{"matchLabels" => %{"battery/app" => @app, "battery/component" => "loki"}}
    })
  end

  resource(:prometheus_rule_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("loki-rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "loki_rules",
          "rules" => [
            %{
              "expr" =>
                "histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job))",
              "record" => "job:loki_request_duration_seconds:99quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.50, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job))",
              "record" => "job:loki_request_duration_seconds:50quantile"
            },
            %{
              "expr" =>
                "sum(rate(loki_request_duration_seconds_sum[1m])) by (job) / sum(rate(loki_request_duration_seconds_count[1m])) by (job)",
              "record" => "job:loki_request_duration_seconds:avg"
            },
            %{
              "expr" => "sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job)",
              "record" => "job:loki_request_duration_seconds_bucket:sum_rate"
            },
            %{
              "expr" => "sum(rate(loki_request_duration_seconds_sum[1m])) by (job)",
              "record" => "job:loki_request_duration_seconds_sum:sum_rate"
            },
            %{
              "expr" => "sum(rate(loki_request_duration_seconds_count[1m])) by (job)",
              "record" => "job:loki_request_duration_seconds_count:sum_rate"
            },
            %{
              "expr" =>
                "histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job, route))",
              "record" => "job_route:loki_request_duration_seconds:99quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.50, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job, route))",
              "record" => "job_route:loki_request_duration_seconds:50quantile"
            },
            %{
              "expr" =>
                "sum(rate(loki_request_duration_seconds_sum[1m])) by (job, route) / sum(rate(loki_request_duration_seconds_count[1m])) by (job, route)",
              "record" => "job_route:loki_request_duration_seconds:avg"
            },
            %{
              "expr" => "sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job, route)",
              "record" => "job_route:loki_request_duration_seconds_bucket:sum_rate"
            },
            %{
              "expr" => "sum(rate(loki_request_duration_seconds_sum[1m])) by (job, route)",
              "record" => "job_route:loki_request_duration_seconds_sum:sum_rate"
            },
            %{
              "expr" => "sum(rate(loki_request_duration_seconds_count[1m])) by (job, route)",
              "record" => "job_route:loki_request_duration_seconds_count:sum_rate"
            },
            %{
              "expr" =>
                "histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, namespace, job, route))",
              "record" => "namespace_job_route:loki_request_duration_seconds:99quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.50, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, namespace, job, route))",
              "record" => "namespace_job_route:loki_request_duration_seconds:50quantile"
            },
            %{
              "expr" =>
                "sum(rate(loki_request_duration_seconds_sum[1m])) by (namespace, job, route) / sum(rate(loki_request_duration_seconds_count[1m])) by (namespace, job, route)",
              "record" => "namespace_job_route:loki_request_duration_seconds:avg"
            },
            %{
              "expr" =>
                "sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, namespace, job, route)",
              "record" => "namespace_job_route:loki_request_duration_seconds_bucket:sum_rate"
            },
            %{
              "expr" =>
                "sum(rate(loki_request_duration_seconds_sum[1m])) by (namespace, job, route)",
              "record" => "namespace_job_route:loki_request_duration_seconds_sum:sum_rate"
            },
            %{
              "expr" =>
                "sum(rate(loki_request_duration_seconds_count[1m])) by (namespace, job, route)",
              "record" => "namespace_job_route:loki_request_duration_seconds_count:sum_rate"
            }
          ]
        },
        %{
          "name" => "loki_alerts",
          "rules" => [
            %{
              "alert" => "LokiRequestErrors",
              "annotations" => %{
                "message" =>
                  "{{ $labels.job }} {{ $labels.route }} is experiencing {{ printf \"%.2f\" $value }}% errors.\n"
              },
              "expr" =>
                "100 * sum(rate(loki_request_duration_seconds_count{status_code=~\"5..\"}[1m])) by (namespace, job, route)\n  /\nsum(rate(loki_request_duration_seconds_count[1m])) by (namespace, job, route)\n  > 10\n",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "LokiRequestPanics",
              "annotations" => %{
                "message" =>
                  "{{ $labels.job }} is experiencing {{ printf \"%.2f\" $value }}% increase of panics.\n"
              },
              "expr" => "sum(increase(loki_panic_total[10m])) by (namespace, job) > 0\n",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "LokiRequestLatency",
              "annotations" => %{
                "message" =>
                  "{{ $labels.job }} {{ $labels.route }} is experiencing {{ printf \"%.2f\" $value }}s 99th percentile latency.\n"
              },
              "expr" =>
                "namespace_job_route:loki_request_duration_seconds:99quantile{route!~\"(?i).*tail.*\"} > 1\n",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "LokiTooManyCompactorsRunning",
              "annotations" => %{
                "message" =>
                  "{{ $labels.namespace }} has had {{ printf \"%.0f\" $value }} compactors running for more than 5m. Only one compactor should run at a time.\n"
              },
              "expr" => "sum(loki_boltdb_shipper_compactor_running) by (namespace) > 1\n",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            }
          ]
        }
      ]
    })
  end

  resource(:service_account_grafana_agent, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("loki-grafana-agent")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  resource(:service_account_grafana_agent_operator, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("loki-grafana-agent-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label("grafana-agent-operator")
  end

  resource(:service_account_main, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> Map.put("automountServiceAccountToken", true)
  end

  resource(:service_headless, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service)
    |> B.name("loki-headless")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("variant", "headless")
    |> B.spec(%{
      "clusterIP" => "None",
      "ports" => [
        %{
          "name" => "http-metrics",
          "port" => 3100,
          "protocol" => "TCP",
          "targetPort" => "http-metrics"
        }
      ],
      "selector" => %{"battery/app" => "loki", "battery/component" => "loki"}
    })
  end

  resource(:service_main, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "ports" => [
        %{
          "name" => "http-metrics",
          "port" => 3100,
          "protocol" => "TCP",
          "targetPort" => "http-metrics"
        },
        %{"name" => "grpc", "port" => 9095, "protocol" => "TCP", "targetPort" => "grpc"}
      ],
      "selector" => %{"battery/app" => "loki", "battery/component" => "loki"},
      "type" => "ClusterIP"
    })
  end

  resource(:service_memberlist, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service)
    |> B.name("loki-memberlist")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "ports" => [
        %{"name" => "tcp", "port" => 7946, "protocol" => "TCP", "targetPort" => "http-memberlist"}
      ],
      "selector" => %{"battery/app" => "loki", "battery/component" => "loki"},
      "type" => "ClusterIP"
    })
  end

  resource(:service_monitor_read, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_monitor)
    |> B.name("loki-read")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label("read")
    |> B.spec(%{
      "endpoints" => [
        %{
          "port" => "http-metrics",
          "relabelings" => [
            %{
              "replacement" => "battery-core/$1",
              "sourceLabels" => ["job"],
              "targetLabel" => "job"
            },
            %{"replacement" => "loki", "targetLabel" => "cluster"}
          ],
          "scheme" => "http"
        }
      ],
      "selector" => %{"matchLabels" => %{"battery/app" => "loki", "battery/component" => "loki"}}
    })
  end

  resource(:stateful_set_main, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:stateful_set)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label("loki")
    |> B.spec(%{
      "podManagementPolicy" => "Parallel",
      "replicas" => 1,
      "revisionHistoryLimit" => 10,
      "selector" => %{"matchLabels" => %{"battery/app" => "loki", "battery/component" => "loki"}},
      "serviceName" => "loki-headless",
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "loki",
            "battery/component" => "loki",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "affinity" => %{
            "podAntiAffinity" => %{
              "requiredDuringSchedulingIgnoredDuringExecution" => [
                %{
                  "labelSelector" => %{
                    "matchLabels" => %{
                      "battery/component" => "loki",
                      "battery/app" => "loki"
                    }
                  },
                  "topologyKey" => "kubernetes.io/hostname"
                }
              ]
            }
          },
          "containers" => [
            %{
              "args" => ["-config.file=/etc/loki/config/config.yaml", "-target=all"],
              "image" => "docker.io/grafana/loki:2.6.1",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "single-binary",
              "ports" => [
                %{"containerPort" => 3100, "name" => "http-metrics", "protocol" => "TCP"},
                %{"containerPort" => 9095, "name" => "grpc", "protocol" => "TCP"},
                %{"containerPort" => 7946, "name" => "http-memberlist", "protocol" => "TCP"}
              ],
              "readinessProbe" => %{
                "httpGet" => %{"path" => "/ready", "port" => "http-metrics"},
                "initialDelaySeconds" => 30,
                "timeoutSeconds" => 1
              },
              "resources" => %{},
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "readOnlyRootFilesystem" => true
              },
              "volumeMounts" => [
                %{"mountPath" => "/etc/loki/config", "name" => "config"},
                %{"mountPath" => "/var/loki", "name" => "storage"}
              ]
            }
          ],
          "securityContext" => %{
            "fsGroup" => 10_001,
            "runAsGroup" => 10_001,
            "runAsNonRoot" => true,
            "runAsUser" => 10_001
          },
          "serviceAccountName" => "loki",
          "terminationGracePeriodSeconds" => 30,
          "volumes" => [%{"configMap" => %{"name" => "loki"}, "name" => "config"}]
        }
      },
      "updateStrategy" => %{"rollingUpdate" => %{"partition" => 0}},
      "volumeClaimTemplates" => [
        %{
          "metadata" => %{"name" => "storage"},
          "spec" => %{
            "accessModes" => ["ReadWriteOnce"],
            "resources" => %{"requests" => %{"storage" => "10Gi"}}
          }
        }
      ]
    })
  end

  resource(:config_map_grafana_datasource, config) do
    namespace = Settings.namespace(config)
    data = %{"datasource.yaml" => get_resource(:datasource_yaml)}

    B.build_resource(:config_map)
    |> B.name("battery-prometheus-grafana-loki-datasource")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_datasource", "1")
    |> B.data(data)
  end

  resource(:config_map_dashboard, config) do
    namespace = Settings.namespace(config)
    data = %{"dashboard.json" => get_resource(:dashboard_json)}

    B.build_resource(:config_map)
    |> B.name("battery-loki-dashdoard")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end
end
