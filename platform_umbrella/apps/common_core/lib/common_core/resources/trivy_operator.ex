defmodule CommonCore.Resources.TrivyOperator do
  @moduledoc false
  use CommonCore.IncludeResource,
    # CRDs
    clustercompliancereports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/clustercompliancereports_aquasecurity_github_io.yaml",
    clusterconfigauditreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/clusterconfigauditreports_aquasecurity_github_io.yaml",
    clusterinfraassessmentreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/clusterinfraassessmentreports_aquasecurity_github_io.yaml",
    clusterrbacassessmentreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/clusterrbacassessmentreports_aquasecurity_github_io.yaml",
    clustersbomreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/clustersbomreports_aquasecurity_github_io.yaml",
    clustervulnerabilityreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/clustervulnerabilityreports_aquasecurity_github_io.yaml",
    configauditreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/configauditreports_aquasecurity_github_io.yaml",
    exposedsecretreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/exposedsecretreports_aquasecurity_github_io.yaml",
    infraassessmentreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/infraassessmentreports_aquasecurity_github_io.yaml",
    rbacassessmentreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/rbacassessmentreports_aquasecurity_github_io.yaml",
    sbomreports_aquasecurity_github_io: "priv/manifests/trivy_operator/sbomreports_aquasecurity_github_io.yaml",
    vulnerabilityreports_aquasecurity_github_io:
      "priv/manifests/trivy_operator/vulnerabilityreports_aquasecurity_github_io.yaml",

    # raw files
    nodecollector_volumemounts: "priv/raw_files/trivy_operator/nodeCollector.volumeMounts",
    nodecollector_volumes: "priv/raw_files/trivy_operator/nodeCollector.volumes",
    cluster_compliance_cis_1_23: "priv/raw_files/trivy_operator/k8s-cis-1.23.yaml",
    cluster_compliance_nsa_1_0: "priv/raw_files/trivy_operator/k8s-nsa-1.0.yaml",
    cluster_compliance_pss_baseline_0_1: "priv/raw_files/trivy_operator/k8s-pss-baseline-0.1.yaml",
    cluster_compliance_pss_restricted_0_1: "priv/raw_files/trivy_operator/k8s-pss-restricted-0.1.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "trivy-operator"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret

  resource(:cluster_role_aggregate_config_audit_reports_view) do
    rules = [
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["configauditreports"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
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

    :cluster_role
    |> B.build_resource()
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

    :cluster_role
    |> B.build_resource()
    |> B.name("aggregate-vulnerability-reports-view")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-cluster-reader", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-view", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_binding_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.role_ref(B.build_cluster_role_ref("trivy-operator"))
    |> B.subject(B.build_service_account("trivy-operator", namespace))
  end

  resource(:cluster_role_trivy_operator) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["limitranges"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["pods/log"], "verbs" => ["get", "list"]},
      %{"apiGroups" => [""], "resources" => ["replicationcontrollers"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["resourcequotas"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => ["apps"], "resources" => ["daemonsets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["apps"], "resources" => ["deployments"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["apps"], "resources" => ["replicasets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["apps"], "resources" => ["statefulsets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["apps.openshift.io"], "resources" => ["deploymentconfigs"], "verbs" => ["get", "list", "watch"]},
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
        "resources" => ["clustersbomreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["clustervulnerabilityreports"],
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
        "resources" => ["sbomreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["aquasecurity.github.io"],
        "resources" => ["vulnerabilityreports"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{"apiGroups" => ["batch"], "resources" => ["cronjobs"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["batch"], "resources" => ["jobs"], "verbs" => ["create", "delete", "get", "list", "watch"]},
      %{"apiGroups" => ["networking.k8s.io"], "resources" => ["ingresses"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["networking.k8s.io"], "resources" => ["networkpolicies"], "verbs" => ["get", "list", "watch"]},
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
      %{"apiGroups" => ["rbac.authorization.k8s.io"], "resources" => ["roles"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["create", "get", "update"]},
      %{"apiGroups" => [""], "resources" => ["serviceaccounts"], "verbs" => ["get"]},
      %{"apiGroups" => [""], "resources" => ["nodes/proxy"], "verbs" => ["get"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.rules(rules)
  end

  resource(:config_map_trivy_operator, battery, state) do
    namespace = base_namespace(state)

    data =
      %{}
      |> Map.put("node.collector.imageRef", battery.config.node_collector_image)
      |> Map.put("policies.bundle.oci.ref", battery.config.trivy_checks_image)
      |> Map.put("compliance.failEntriesLimit", "10")
      |> Map.put("configAuditReports.scanner", "Trivy")
      |> Map.put("node.collector.nodeSelector", "true")
      |> Map.put("policies.bundle.insecure", "false")
      |> Map.put("report.recordFailedChecksOnly", "true")
      |> Map.put("scanJob.compressLogs", "true")
      |> Map.put(
        "scanJob.podTemplateContainerSecurityContext",
        ~s({"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true})
      )
      |> Map.put("vulnerabilityReports.scanner", "Trivy")
      |> Map.put("nodeCollector.volumeMounts", get_resource(:nodecollector_volumemounts))
      |> Map.put("nodeCollector.volumes", get_resource(:nodecollector_volumes))

    :config_map
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_trivy_operator_policies, _battery, state) do
    namespace = base_namespace(state)
    data = %{}

    :config_map
    |> B.build_resource()
    |> B.name("trivy-operator-policies-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:config_map_trivy_operator_trivy, battery, state) do
    namespace = base_namespace(state)

    data =
      %{}
      |> Map.put("trivy.repo", battery.config.trivy_repo)
      |> Map.put("trivy.tag", battery.config.trivy_version_tag)
      |> Map.put("trivy.additionalVulnerabilityReportFields", "")
      |> Map.put("trivy.command", "image")
      |> Map.put("trivy.dbRepository", "ghcr.io/aquasecurity/trivy-db")
      |> Map.put("trivy.dbRepositoryInsecure", "false")
      |> Map.put("trivy.filesystemScanCacheDir", "/var/trivyoperator/trivy-db")
      |> Map.put("trivy.imagePullPolicy", "IfNotPresent")
      |> Map.put("trivy.imageScanCacheDir", "/tmp/trivy/.cache")
      |> Map.put("trivy.includeDevDeps", "false")
      |> Map.put("trivy.javaDbRepository", "ghcr.io/aquasecurity/trivy-java-db")
      |> Map.put("trivy.mode", "Standalone")
      |> Map.put("trivy.repository", "ghcr.io/aquasecurity/trivy")
      |> Map.put("trivy.resources.limits.cpu", "500m")
      |> Map.put("trivy.resources.limits.memory", "500M")
      |> Map.put("trivy.resources.requests.cpu", "100m")
      |> Map.put("trivy.resources.requests.memory", "100M")
      |> Map.put("trivy.sbomSources", "")
      |> Map.put("trivy.severity", "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL")
      |> Map.put("trivy.skipJavaDBUpdate", "false")
      |> Map.put("trivy.slow", "true")
      |> Map.put("trivy.ignoreUnfixed", "true")
      |> Map.put(
        "trivy.supportedConfigAuditKinds",
        "Workload,Service,Role,ClusterRole,NetworkPolicy,Ingress,LimitRange,ResourceQuota"
      )
      |> Map.put("trivy.timeout", "5m0s")
      |> Map.put("trivy.useBuiltinRegoPolicies", "true")
      |> Map.put("trivy.useEmbeddedRegoPolicies", "false")

    :config_map
    |> B.build_resource()
    |> B.name("trivy-operator-trivy-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:crd_clustercompliancereports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:clustercompliancereports_aquasecurity_github_io))
  end

  resource(:crd_clusterconfigauditreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:clusterconfigauditreports_aquasecurity_github_io))
  end

  resource(:crd_clusterinfraassessmentreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:clusterinfraassessmentreports_aquasecurity_github_io))
  end

  resource(:crd_clusterrbacassessmentreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:clusterrbacassessmentreports_aquasecurity_github_io))
  end

  resource(:crd_clustersbomreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:clustersbomreports_aquasecurity_github_io))
  end

  resource(:crd_clustervulnerabilityreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:clustervulnerabilityreports_aquasecurity_github_io))
  end

  resource(:crd_configauditreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:configauditreports_aquasecurity_github_io))
  end

  resource(:crd_exposedsecretreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:exposedsecretreports_aquasecurity_github_io))
  end

  resource(:crd_infraassessmentreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:infraassessmentreports_aquasecurity_github_io))
  end

  resource(:crd_rbacassessmentreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:rbacassessmentreports_aquasecurity_github_io))
  end

  resource(:crd_sbomreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:sbomreports_aquasecurity_github_io))
  end

  resource(:crd_vulnerabilityreports_aquasecurity_github_io) do
    YamlElixir.read_all_from_string!(get_resource(:vulnerabilityreports_aquasecurity_github_io))
  end

  resource(:deployment_trivy_operator, battery, state) do
    namespace = base_namespace(state)

    template = %{
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
              %{"name" => "OPERATOR_NAMESPACE", "value" => namespace},
              %{"name" => "OPERATOR_TARGET_NAMESPACES", "value" => ""},
              %{"name" => "OPERATOR_EXCLUDE_NAMESPACES", "value" => ""},
              %{"name" => "OPERATOR_SERVICE_ACCOUNT", "value" => "trivy-operator"},
              %{"name" => "OPERATOR_LOG_DEV_MODE", "value" => "false"},
              %{"name" => "OPERATOR_VULNERABILITY_SCANNER_ENABLED", "value" => "true"},
              %{
                "name" => "OPERATOR_VULNERABILITY_SCANNER_SCAN_ONLY_CURRENT_REVISIONS",
                "value" => "true"
              },
              %{"name" => "OPERATOR_CONFIG_AUDIT_SCANNER_ENABLED", "value" => "true"},
              %{"name" => "OPERATOR_RBAC_ASSESSMENT_SCANNER_ENABLED", "value" => "true"},
              %{"name" => "OPERATOR_INFRA_ASSESSMENT_SCANNER_ENABLED", "value" => "true"},
              %{
                "name" => "OPERATOR_CONFIG_AUDIT_SCANNER_SCAN_ONLY_CURRENT_REVISIONS",
                "value" => "true"
              },
              %{"name" => "OPERATOR_EXPOSED_SECRET_SCANNER_ENABLED", "value" => "true"},
              %{"name" => "OPERATOR_PRIVATE_REGISTRY_SCAN_SECRETS_NAMES", "value" => "{}"},
              %{
                "name" => "OPERATOR_ACCESS_GLOBAL_SECRETS_SERVICE_ACCOUNTS",
                "value" => "true"
              },
              %{
                "name" => "OPERATOR_MERGE_RBAC_FINDING_WITH_CONFIG_AUDIT",
                "value" => "false"
              },
              %{"name" => "OPERATOR_CLUSTER_COMPLIANCE_ENABLED", "value" => "true"}
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
            },
            "volumeMounts" => [
              %{"mountPath" => "/tmp", "name" => "temp"}
            ]
          }
        ],
        "securityContext" => %{},
        "serviceAccountName" => "trivy-operator",
        "volumes" => [%{"emptyDir" => %{}, "name" => "temp"}]
      }
    }

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> Map.put("strategy", %{"type" => "Recreate"})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:role_binding_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("trivy-operator"))
    |> B.subject(B.build_service_account("trivy-operator", namespace))
  end

  resource(:role_binding_trivy_operator_leader_election, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("trivy-operator-leader-election")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("trivy-operator-leader-election"))
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

    :role
    |> B.build_resource()
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

    :role
    |> B.build_resource()
    |> B.name("trivy-operator-leader-election")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:secret_trivy_operator, _battery, state) do
    namespace = base_namespace(state)
    data = Secret.encode(%{})

    :secret
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_trivy_operator_trivy_config, _battery, state) do
    namespace = base_namespace(state)
    data = Secret.encode(%{})

    :secret
    |> B.build_resource()
    |> B.name("trivy-operator-trivy-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_account_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.component_labels("trivy-operator")
  end

  resource(:service_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "metrics", "port" => 80, "protocol" => "TCP", "targetPort" => "metrics"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.component_labels("trivy-operator")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:monitoring_service_monitor_trivy_operator, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"honorLabels" => true, "port" => "metrics", "scheme" => "http"}])
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("trivy-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
