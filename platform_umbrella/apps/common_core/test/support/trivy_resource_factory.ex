defmodule CommonCore.TrivyResourceFactory do
  @moduledoc false
  use ExMachina

  alias CommonCore.Resources.Builder, as: B

  def aqua_vulnerability_report_factory do
    namespace = sequence(:vuln_namespace, ["test-ns", "app-ns", "service-ns"])
    report_name = sequence(:vuln_name, &"deployment-app-#{&1}")
    repo = sequence(:repo, ["nginx", "redis", "postgres", "alpine"])
    tag = sequence(:tag, ["1.21", "6.2", "13.4", "3.16"])

    :aqua_vulnerability_report
    |> B.build_resource()
    |> B.name(report_name)
    |> B.namespace(namespace)
    |> Map.put("report", %{
      "artifact" => %{
        "digest" => sequence(:digest, &"sha256:#{String.duplicate("a", 32)}#{&1}"),
        "repository" => repo,
        "tag" => tag
      },
      "registry" => %{
        "server" => "docker.io"
      },
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.65.0"
      },
      "summary" => %{
        "criticalCount" => sequence(:critical, [0, 1, 2]),
        "highCount" => sequence(:high, [0, 1, 2, 3]),
        "lowCount" => sequence(:low, [0, 1, 2]),
        "mediumCount" => sequence(:medium, [0, 1, 2, 3]),
        "noneCount" => 0,
        "unknownCount" => 0
      },
      "vulnerabilities" => [
        %{
          "fixedVersion" => "1.24.4",
          "installedVersion" => "v1.24.3",
          "lastModifiedDate" => "2025-06-12T16:06:20Z",
          "primaryLink" => sequence(:cve_link, &"https://avd.aquasec.com/nvd/cve-2025-#{&1}"),
          "publishedDate" => "2025-06-11T17:15:42Z",
          "resource" => sequence(:vuln_resource, ["stdlib", "openssl", "glibc"]),
          "score" => sequence(:score, [7.5, 5.5, 8.1, 6.2]),
          "severity" => sequence(:severity, ["HIGH", "MEDIUM", "CRITICAL", "LOW"]),
          "title" => sequence(:vuln_title, &"Security vulnerability #{&1}"),
          "vulnerabilityID" => sequence(:vuln_id, &"CVE-2025-#{&1}")
        }
      ]
    })
  end

  def aqua_cluster_vulnerability_report_factory do
    report_name = sequence(:cluster_vuln_name, &"cluster-vuln-#{&1}")

    :aqua_cluster_vulnerability_report
    |> B.build_resource()
    |> B.name(report_name)
    |> Map.put("report", %{
      "artifact" => %{
        "repository" => "kubernetes",
        "tag" => sequence(:k8s_version, ["1.28.1", "1.29.2", "1.30.1", "1.31.12", "1.32.8", "1.33.4", "1.34.0"])
      },
      "os" => %{
        "family" => "debian",
        "name" => sequence(:os_version, ["11", "12"])
      },
      "registry" => %{
        "server" => "k8s.io"
      },
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.65.0"
      },
      "summary" => %{
        "criticalCount" => sequence(:cluster_critical, [0, 1]),
        "highCount" => sequence(:cluster_high, [1, 2, 3]),
        "lowCount" => 0,
        "mediumCount" => sequence(:cluster_medium, [0, 1, 2]),
        "noneCount" => 0,
        "unknownCount" => 0
      },
      "vulnerabilities" => [
        %{
          "fixedVersion" => sequence(:cluster_fixed, ["2.4.1", "3.1.2"]),
          "installedVersion" => sequence(:cluster_installed, ["2.4.0", "3.1.1"]),
          "lastModifiedDate" => "2025-05-15T10:30:00Z",
          "primaryLink" => sequence(:cluster_cve_link, &"https://avd.aquasec.com/nvd/cve-2025-#{&1}"),
          "publishedDate" => "2025-05-14T08:15:00Z",
          "resource" => "kubernetes",
          "score" => sequence(:cluster_score, [9.1, 8.5, 7.8]),
          "severity" => sequence(:cluster_severity, ["CRITICAL", "HIGH"]),
          "title" => sequence(:cluster_vuln_title, &"Kubernetes vulnerability #{&1}"),
          "vulnerabilityID" => sequence(:cluster_vuln_id, &"CVE-2025-#{&1}")
        }
      ]
    })
  end

  def aqua_exposed_secret_report_factory do
    namespace = sequence(:secret_namespace, ["test-ns", "app-ns", "service-ns"])
    report_name = sequence(:secret_name, &"deployment-app-#{&1}")

    :aqua_exposed_secret_report
    |> B.build_resource()
    |> B.name(report_name)
    |> B.namespace(namespace)
    |> Map.put("report", %{
      "artifact" => %{
        "digest" => sequence(:secret_digest, &"sha256:#{String.duplicate("f", 32)}#{&1}"),
        "repository" => sequence(:secret_repo, ["myapp/backend", "myapp/frontend"]),
        "tag" => sequence(:secret_tag, ["v1.2.3", "v2.1.0"])
      },
      "registry" => %{
        "server" => sequence(:secret_registry, ["docker.io", "quay.io"])
      },
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.65.0"
      },
      "secrets" => [
        %{
          "category" => "secret",
          "endLine" => sequence(:secret_end_line, [15, 23, 31]),
          "match" => sequence(:secret_match, ["AKIA****EXAMPLE", "sk_test_****", "ghp_****"]),
          "ruleID" => sequence(:secret_rule, ["aws-access-key-id", "stripe-secret-key", "github-token"]),
          "severity" => sequence(:secret_severity, ["CRITICAL", "HIGH", "MEDIUM"]),
          "startLine" => sequence(:secret_start_line, [15, 23, 31]),
          "target" => sequence(:secret_target, ["config/secrets.yaml", "app/config.py", ".env"]),
          "title" => sequence(:secret_title, ["AWS Access Key", "Stripe Secret Key", "GitHub Token"])
        }
      ],
      "summary" => %{
        "criticalCount" => sequence(:secret_critical_count, [0, 1]),
        "highCount" => sequence(:secret_high_count, [0, 1, 2]),
        "lowCount" => 0,
        "mediumCount" => sequence(:secret_medium_count, [0, 1])
      }
    })
  end

  def aqua_sbom_report_factory do
    namespace = sequence(:sbom_namespace, ["test-ns", "app-ns", "service-ns"])
    report_name = sequence(:sbom_name, &"deployment-app-#{&1}")

    :aqua_sbom_report
    |> B.build_resource()
    |> B.name(report_name)
    |> B.namespace(namespace)
    |> Map.put("report", %{
      "artifact" => %{
        "digest" => sequence(:sbom_digest, &"sha256:#{String.duplicate("b", 32)}#{&1}"),
        "repository" => sequence(:sbom_repo, ["nginx", "alpine", "ubuntu"]),
        "tag" => sequence(:sbom_tag, ["1.21", "3.16", "20.04"])
      },
      "components" => %{
        "bomFormat" => "CycloneDX",
        "components" => [
          %{
            "bom-ref" => sequence(:component_ref, &"component-#{&1}"),
            "name" => sequence(:component_name, ["alpine", "openssl", "curl", "wget"]),
            "properties" => [
              %{
                "name" => "aquasecurity:trivy:Class",
                "value" => "os-pkgs"
              },
              %{
                "name" => "aquasecurity:trivy:Type",
                "value" => sequence(:component_type, ["alpine", "debian", "ubuntu"])
              }
            ],
            "supplier" => %{},
            "type" => sequence(:component_category, ["operating-system", "library"]),
            "version" => sequence(:component_version, ["3.16.2", "1.1.1q", "7.81.0"])
          }
        ]
      },
      "registry" => %{
        "server" => sequence(:sbom_registry, ["docker.io", "quay.io"])
      },
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.65.0"
      }
    })
  end

  def aqua_cluster_sbom_report_factory do
    report_name = sequence(:cluster_sbom_name, &"cluster-sbom-#{&1}")

    :aqua_cluster_sbom_report
    |> B.build_resource()
    |> B.name(report_name)
    |> Map.put("report", %{
      "artifact" => %{
        "digest" => sequence(:cluster_sbom_digest, &"sha256:#{String.duplicate("c", 32)}#{&1}"),
        "repository" => sequence(:cluster_sbom_repo, ["istio/install-cni", "calico/node"]),
        "tag" => sequence(:cluster_sbom_tag, ["1.27.0", "v3.26.0"])
      },
      "components" => %{
        "bomFormat" => "CycloneDX",
        "components" => [
          %{
            "bom-ref" => sequence(:cluster_component_ref, &"cluster-component-#{&1}"),
            "name" => sequence(:cluster_component_name, ["sigs.k8s.io/json", "k8s.io/api"]),
            "properties" => [
              %{
                "name" => "aquasecurity:trivy:PkgType",
                "value" => "gobinary"
              }
            ],
            "purl" => sequence(:cluster_purl, &"pkg:golang/k8s.io/component@v0.#{&1}.0"),
            "type" => "library",
            "version" => sequence(:cluster_component_version, &"v0.#{&1}.0")
          }
        ]
      },
      "registry" => %{
        "server" => "docker.io"
      },
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.65.0"
      }
    })
  end

  def aqua_config_audit_report_factory do
    namespace = sequence(:config_namespace, ["test-ns", "app-ns", "service-ns"])
    report_name = sequence(:config_name, &"deployment-app-#{&1}")

    :aqua_config_audit_report
    |> B.build_resource()
    |> B.name(report_name)
    |> B.namespace(namespace)
    |> Map.put("report", %{
      "checks" => [
        %{
          "category" => "Kubernetes Security Check",
          "checkID" => sequence(:config_check_id, ["KSV020", "KSV016", "KSV011"]),
          "description" =>
            sequence(:config_desc, [
              "Force the container to run with user ID > 10000 to avoid conflicts with the host's user table.",
              "When containers have memory requests specified, Kubernetes can make better decisions for scheduling.",
              "CPU limits should be set to prevent containers from consuming too many resources."
            ]),
          "messages" => [
            sequence(:config_message, &"Container 'app' should set security context #{&1}")
          ],
          "remediation" =>
            sequence(:config_remediation, [
              "Set 'containers[].securityContext.runAsUser' to an integer > 10000.",
              "Set 'containers[].resources.requests.memory'.",
              "Set 'containers[].resources.limits.cpu'."
            ]),
          "severity" => sequence(:config_severity, ["LOW", "MEDIUM", "HIGH"]),
          "success" => false,
          "title" =>
            sequence(:config_title, [
              "Runs with UID <= 10000",
              "Memory requests not specified",
              "CPU limits not specified"
            ])
        }
      ],
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.23.1"
      },
      "summary" => %{
        "criticalCount" => 0,
        "highCount" => sequence(:config_high_count, [0, 1]),
        "lowCount" => sequence(:config_low_count, [1, 2]),
        "mediumCount" => sequence(:config_medium_count, [0, 1])
      }
    })
  end

  def aqua_rbac_assessment_report_factory do
    namespace = sequence(:rbac_namespace, ["test-ns", "app-ns", "service-ns"])
    report_name = sequence(:rbac_name, &"role-test-role-#{&1}")

    :aqua_rbac_assessment_report
    |> B.build_resource()
    |> B.name(report_name)
    |> B.namespace(namespace)
    |> Map.put("report", %{
      "checks" => [
        %{
          "category" => "Kubernetes Security Check",
          "checkID" => sequence(:rbac_check_id, ["KSV113", "KSV114", "KSV115"]),
          "description" =>
            sequence(:rbac_desc, [
              "Viewing secrets at the namespace scope can lead to escalation.",
              "Escalate verb allows creating new ClusterRoleBindings or RoleBindings.",
              "Impersonate verb allows acting as other users or service accounts."
            ]),
          "messages" => [
            sequence(:rbac_message, &"Role shouldn't have dangerous permission #{&1}")
          ],
          "remediation" =>
            sequence(:rbac_remediation, [
              "Remove resource 'secrets' from role",
              "Remove verb 'escalate' from role",
              "Remove verb 'impersonate' from role"
            ]),
          "severity" => sequence(:rbac_severity, ["MEDIUM", "HIGH", "CRITICAL"]),
          "success" => false,
          "title" =>
            sequence(:rbac_title, [
              "Manage namespace secrets",
              "Role allows escalation",
              "Role allows impersonation"
            ])
        }
      ],
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.23.1"
      },
      "summary" => %{
        "criticalCount" => sequence(:rbac_critical_count, [0, 1]),
        "highCount" => sequence(:rbac_high_count, [0, 1]),
        "lowCount" => 0,
        "mediumCount" => sequence(:rbac_medium_count, [0, 1])
      }
    })
  end

  def aqua_cluster_rbac_assessment_report_factory do
    report_name = sequence(:cluster_rbac_name, &"clusterrole-system-role-#{&1}")

    :aqua_cluster_rbac_assessment_report
    |> B.build_resource()
    |> B.name(report_name)
    |> Map.put("report", %{
      "checks" => [
        %{
          "category" => "Kubernetes Security Check",
          "checkID" => sequence(:cluster_rbac_check_id, ["KSV115", "KSV116"]),
          "description" =>
            sequence(:cluster_rbac_desc, [
              "Bind verb allows creating new ClusterRoleBindings or RoleBindings.",
              "Create verb on ClusterRoles allows privilege escalation."
            ]),
          "messages" => [
            sequence(:cluster_rbac_message, &"ClusterRole shouldn't have dangerous permission #{&1}")
          ],
          "remediation" =>
            sequence(:cluster_rbac_remediation, [
              "Remove verb 'bind' from clusterrole",
              "Remove verb 'create' on clusterroles from clusterrole"
            ]),
          "severity" => sequence(:cluster_rbac_severity, ["HIGH", "CRITICAL"]),
          "success" => false,
          "title" =>
            sequence(:cluster_rbac_title, [
              "ClusterRole allows bind escalation",
              "ClusterRole allows creating ClusterRoles"
            ])
        }
      ],
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.23.1"
      },
      "summary" => %{
        "criticalCount" => sequence(:cluster_rbac_critical_count, [0, 1]),
        "highCount" => sequence(:cluster_rbac_high_count, [1, 2]),
        "lowCount" => 0,
        "mediumCount" => 0
      }
    })
  end

  def aqua_infra_assessment_report_factory do
    namespace = sequence(:infra_namespace, ["kube-system", "test-ns", "app-ns"])
    report_name = sequence(:infra_name, &"pod-system-pod-#{&1}")

    :aqua_infra_assessment_report
    |> B.build_resource()
    |> B.name(report_name)
    |> B.namespace(namespace)
    |> Map.put("report", %{
      "checks" => [
        %{
          "category" => "Kubernetes Security Check",
          "checkID" => sequence(:infra_check_id, ["KCV0001", "KCV0002", "KCV0003"]),
          "description" =>
            sequence(:infra_desc, [
              "Ensure that the API server pod specification file permissions are set to 644 or more restrictive.",
              "Ensure that the API server pod specification file ownership is set to root:root.",
              "Ensure that the controller manager pod specification file permissions are set to 644 or more restrictive."
            ]),
          "messages" => [
            sequence(:infra_message, &"Infrastructure security check #{&1} failed")
          ],
          "remediation" =>
            sequence(:infra_remediation, [
              "Run: chmod 644 /etc/kubernetes/manifests/kube-apiserver.yaml",
              "Run: chown root:root /etc/kubernetes/manifests/kube-apiserver.yaml",
              "Run: chmod 644 /etc/kubernetes/manifests/kube-controller-manager.yaml"
            ]),
          "severity" => sequence(:infra_severity, ["HIGH", "MEDIUM", "LOW"]),
          "success" => false,
          "title" =>
            sequence(:infra_title, [
              "API server pod file permissions",
              "API server pod file ownership",
              "Controller manager pod file permissions"
            ])
        }
      ],
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.23.1"
      },
      "summary" => %{
        "criticalCount" => 0,
        "highCount" => sequence(:infra_high_count, [1, 2]),
        "lowCount" => sequence(:infra_low_count, [0, 1]),
        "mediumCount" => sequence(:infra_medium_count, [0, 1])
      }
    })
  end

  def aqua_cluster_infra_assesment_report_factory do
    report_name = sequence(:cluster_infra_name, &"node-worker-#{&1}")

    :aqua_cluster_infra_assesment_report
    |> B.build_resource()
    |> B.name(report_name)
    |> Map.put("report", %{
      "checks" => [
        %{
          "category" => "Kubernetes Security Check",
          "checkID" => sequence(:cluster_infra_check_id, ["KCV0077", "KCV0075", "KCV0078"]),
          "description" =>
            sequence(:cluster_infra_desc, [
              "Ensure that if the kubelet refers to a configuration file with the --config argument, that file has permissions of 600 or more restrictive.",
              "Ensure that the certificate authorities file has permissions of 600 or more restrictive.",
              "Ensure that the client certificate authorities file has permissions of 644 or more restrictive."
            ]),
          "messages" => [
            sequence(:cluster_infra_message, &"Node security check #{&1} failed")
          ],
          "remediation" =>
            sequence(:cluster_infra_remediation, [
              "Change the kubelet config yaml permissions to 600 or more restrictive if exist",
              "Run: chmod 600 /etc/kubernetes/pki/ca.crt",
              "Run: chmod 644 /etc/kubernetes/pki/ca.crt"
            ]),
          "severity" => sequence(:cluster_infra_severity, ["HIGH", "MEDIUM"]),
          "success" => false,
          "title" =>
            sequence(:cluster_infra_title, [
              "Kubelet config file permissions",
              "Certificate authorities file permissions",
              "Client certificate authorities file permissions"
            ])
        }
      ],
      "scanner" => %{
        "name" => "Trivy",
        "vendor" => "Aqua Security",
        "version" => "0.23.1"
      },
      "summary" => %{
        "criticalCount" => 0,
        "highCount" => sequence(:cluster_infra_high_count, [2, 3]),
        "lowCount" => 0,
        "mediumCount" => sequence(:cluster_infra_medium_count, [1, 2])
      }
    })
  end
end
