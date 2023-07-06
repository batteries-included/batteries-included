defmodule CommonCore.Resources.TrivyOperator do
  use CommonCore.IncludeResource,
    clustercompliancereports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_clustercompliancereports.yaml",
    clusterconfigauditreports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_clusterconfigauditreports.yaml",
    clusterinfraassessmentreports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_clusterinfraassessmentreports.yaml",
    clusterrbacassessmentreports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_clusterrbacassessmentreports.yaml",
    configauditreports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_configauditreports.yaml",
    exposedsecretreports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_exposedsecretreports.yaml",
    infraassessmentreports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_infraassessmentreports.yaml",
    rbacassessmentreports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_rbacassessmentreports.yaml",
    vulnerabilityreports:
      "priv/manifests/trivy_operator/aquasecurity.github.io_vulnerabilityreports.yaml",
    cis: "priv/manifests/trivy_operator/cis-1.23.yaml",
    nsa: "priv/manifests/trivy_operator/nsa-1.0.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "trivy-operator"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  multi_resource(:crds) do
    [
      :clustercompliancereports,
      :clusterconfigauditreports,
      :clusterinfraassessmentreports,
      :clusterrbacassessmentreports,
      :configauditreports,
      :exposedsecretreports,
      :infraassessmentreports,
      :rbacassessmentreports,
      :vulnerabilityreports
    ]
    |> Enum.map(fn crd_name ->
      {to_string(crd_name),
       crd_name |> get_resource() |> YamlElixir.read_all_from_string!() |> hd()}
    end)
    |> Map.new()
  end

  resource(:aqua_cluster_compliance_report_cis) do
    :cis
    |> get_resource()
    |> YamlElixir.read_all_from_string!()
    |> hd()
  end

  resource(:aqua_cluster_compliance_report_nsa) do
    :nsa
    |> get_resource()
    |> YamlElixir.read_all_from_string!()
    |> hd()
  end

  resource(:cluster_role_aggregate_config_audit_reports_view) do
    rules = [
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["configauditreports"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("aggregate-config-audit-reports-view")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-cluster-reader", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-view", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_aggregate_exposed_secret_reports_view) do
    rules = [
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["exposedsecretreports"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("aggregate-exposed-secret-reports-view")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-cluster-reader", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-view", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_aggregate_vulnerability_reports_view) do
    rules = [
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["vulnerabilityreports"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("aggregate-vulnerability-reports-view")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-cluster-reader", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-view", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_trivy_operator) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["limitranges"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["pods/log"], "verbs" => ["get", "list"]},
      %{
        "apiGroups" => [""],
        "resources" => ["replicationcontrollers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["resourcequotas"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["daemonsets"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["replicasets"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["statefulsets"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["clustercompliancedetailreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["clustercompliancereports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["clustercompliancereports/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["clusterconfigauditreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["clusterinfraassessmentreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["clusterrbacassessmentreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["configauditreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["exposedsecretreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["infraassessmentreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["rbacassessmentreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["vulnerabilityreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["cronjobs"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["batch"],
        "resources" => ["jobs"],
        "verbs" => ["create", "delete", "get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["networkpolicies"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterrolebindings"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterroles"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["rolebindings"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["roles"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["create", "get", "update"]},
      %{"apiGroups" => [""], "resources" => ["serviceaccounts"], "verbs" => ["get"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name("trivy-operator")
    |> B.rules(rules)
  end

  resource(:cluster_role_binding_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("trivy-operator")
    |> B.role_ref(B.build_cluster_role_ref("trivy-operator"))
    |> B.subject(B.build_service_account("trivy-operator", namespace))
  end

  resource(:role_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["create", "get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["create", "get", "delete"]}
    ]

    B.build_resource(:role)
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_trivy_operator_leader_election, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["create", "get", "update"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create"]}
    ]

    B.build_resource(:role)
    |> B.name("trivy-operator-leader-election")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_binding_trivy_operator_leader_election, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("trivy-operator-leader-election")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("trivy-operator-leader-election"))
    |> B.subject(B.build_service_account("trivy-operator", namespace))
  end

  resource(:role_binding_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("trivy-operator"))
    |> B.subject(B.build_service_account("trivy-operator", namespace))
  end

  resource(:service_account_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
  end

  resource(:config_map_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    data =
      %{}
      |> Map.put("configAuditReports.scanner", "Trivy")
      |> Map.put("node.collector.imageRef", "ghcr.io/aquasecurity/node-collector:0.0.5")
      |> Map.put("report.recordFailedChecksOnly", "true")
      |> Map.put("scanJob.compressLogs", "true")
      |> Map.put(
        "scanJob.podTemplateContainerSecurityContext",
        "{\"allowPrivilegeEscalation\":false,\"capabilities\":{\"drop\":[\"ALL\"]},\"privileged\":false,\"readOnlyRootFilesystem\":true}"
      )
      |> Map.put("vulnerabilityReports.scanner", "Trivy")

    B.build_resource(:config_map)
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_trivy_operator_policies, _battery, state) do
    namespace = base_namespace(state)
    data = %{}

    B.build_resource(:config_map)
    |> B.name("trivy-operator-policies-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_trivy_operator_trivy, battery, state) do
    namespace = base_namespace(state)

    data =
      %{}
      |> Map.put("trivy.additionalVulnerabilityReportFields", "")
      |> Map.put("trivy.command", "image")
      |> Map.put("trivy.dbRepository", "ghcr.io/aquasecurity/trivy-db")
      |> Map.put("trivy.dbRepositoryInsecure", "false")
      |> Map.put("trivy.mode", "Standalone")
      |> Map.put("trivy.repository", "ghcr.io/aquasecurity/trivy")
      |> Map.put("trivy.resources.limits.cpu", "500m")
      |> Map.put("trivy.resources.limits.memory", "500M")
      |> Map.put("trivy.resources.requests.cpu", "100m")
      |> Map.put("trivy.resources.requests.memory", "100M")
      |> Map.put("trivy.severity", "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL")
      |> Map.put("trivy.slow", "true")
      |> Map.put(
        "trivy.supportedConfigAuditKinds",
        "Workload,Service,Role,ClusterRole,NetworkPolicy,Ingress,LimitRange,ResourceQuota"
      )
      |> Map.put("trivy.tag", battery.config.version_tag)
      |> Map.put("trivy.timeout", "5m0s")
      |> Map.put("trivy.useBuiltinRegoPolicies", "true")

    B.build_resource(:config_map)
    |> B.name("trivy-operator-trivy-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_trivy_operator, _battery, state) do
    namespace = base_namespace(state)
    data = %{}

    B.build_resource(:secret)
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_trivy_operator_trivy_config, _battery, state) do
    namespace = base_namespace(state)
    data = %{}

    B.build_resource(:secret)
    |> B.name("trivy-operator-trivy-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:deployment_trivy_operator, battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name
          }
        }
      )
      |> Map.put("strategy", %{"type" => "Recreate"})
      |> Map.put(
        "template",
        %{
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
                  %{"name" => "OPERATOR_NAMESPACE", "value" => namespace},
                  %{"name" => "OPERATOR_TARGET_NAMESPACES", "value" => ""},
                  %{"name" => "OPERATOR_EXCLUDE_NAMESPACES", "value" => ""},
                  %{
                    "name" => "OPERATOR_TARGET_WORKLOADS",
                    "value" =>
                      "pod,replicaset,replicationcontroller,statefulset,daemonset,cronjob,job"
                  },
                  %{"name" => "OPERATOR_SERVICE_ACCOUNT", "value" => "trivy-operator"},
                  %{"name" => "OPERATOR_LOG_DEV_MODE", "value" => "false"},
                  %{"name" => "OPERATOR_SCAN_JOB_TTL", "value" => ""},
                  %{"name" => "OPERATOR_SCAN_JOB_TIMEOUT", "value" => "5m"},
                  %{"name" => "OPERATOR_CONCURRENT_SCAN_JOBS_LIMIT", "value" => "10"},
                  %{"name" => "OPERATOR_SCAN_JOB_RETRY_AFTER", "value" => "30s"},
                  %{"name" => "OPERATOR_BATCH_DELETE_LIMIT", "value" => "10"},
                  %{"name" => "OPERATOR_BATCH_DELETE_DELAY", "value" => "10s"},
                  %{"name" => "OPERATOR_METRICS_BIND_ADDRESS", "value" => ":8080"},
                  %{"name" => "OPERATOR_METRICS_FINDINGS_ENABLED", "value" => "true"},
                  %{"name" => "OPERATOR_METRICS_VULN_ID_ENABLED", "value" => "false"},
                  %{"name" => "OPERATOR_HEALTH_PROBE_BIND_ADDRESS", "value" => ":9090"},
                  %{"name" => "OPERATOR_VULNERABILITY_SCANNER_ENABLED", "value" => "true"},
                  %{
                    "name" => "OPERATOR_VULNERABILITY_SCANNER_SCAN_ONLY_CURRENT_REVISIONS",
                    "value" => "true"
                  },
                  %{"name" => "OPERATOR_SCANNER_REPORT_TTL", "value" => "24h"},
                  %{"name" => "OPERATOR_CONFIG_AUDIT_SCANNER_ENABLED", "value" => "true"},
                  %{"name" => "OPERATOR_RBAC_ASSESSMENT_SCANNER_ENABLED", "value" => "true"},
                  %{"name" => "OPERATOR_INFRA_ASSESSMENT_SCANNER_ENABLED", "value" => "true"},
                  %{
                    "name" => "OPERATOR_CONFIG_AUDIT_SCANNER_SCAN_ONLY_CURRENT_REVISIONS",
                    "value" => "true"
                  },
                  %{"name" => "OPERATOR_EXPOSED_SECRET_SCANNER_ENABLED", "value" => "true"},
                  %{"name" => "OPERATOR_METRICS_EXPOSED_SECRET_INFO_ENABLED", "value" => "false"},
                  %{"name" => "OPERATOR_WEBHOOK_BROADCAST_URL", "value" => ""},
                  %{"name" => "OPERATOR_WEBHOOK_BROADCAST_TIMEOUT", "value" => "30s"},
                  %{"name" => "OPERATOR_PRIVATE_REGISTRY_SCAN_SECRETS_NAMES", "value" => "{}"},
                  %{
                    "name" => "OPERATOR_ACCESS_GLOBAL_SECRETS_SERVICE_ACCOUNTS",
                    "value" => "true"
                  },
                  %{"name" => "OPERATOR_BUILT_IN_TRIVY_SERVER", "value" => "false"},
                  %{"name" => "TRIVY_SERVER_HEALTH_CHECK_CACHE_EXPIRATION", "value" => "10h"},
                  %{"name" => "OPERATOR_MERGE_RBAC_FINDING_WITH_CONFIG_AUDIT", "value" => "false"}
                ],
                "image" => battery.config.image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "failureThreshold" => 10,
                  "httpGet" => %{"path" => "/healthz/", "port" => "probes"},
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "successThreshold" => 1
                },
                "name" => "trivy-operator",
                "ports" => [
                  %{"containerPort" => 8080, "name" => "metrics"},
                  %{"containerPort" => 9090, "name" => "probes"}
                ],
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/readyz/", "port" => "probes"},
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "successThreshold" => 1
                },
                "resources" => %{},
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]},
                  "privileged" => false,
                  "readOnlyRootFilesystem" => true
                }
              }
            ],
            "securityContext" => %{},
            "serviceAccountName" => "trivy-operator"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "metrics", "port" => 80, "protocol" => "TCP", "targetPort" => "metrics"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:monitoring_service_monitor_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"honorLabels" => true, "port" => "metrics", "scheme" => "http"}])
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})

    B.build_resource(:monitoring_service_monitor)
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
