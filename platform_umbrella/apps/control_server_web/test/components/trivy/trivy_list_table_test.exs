defmodule ControlServerWeb.Trivy.TrivyListTableTest do
  use Heyya.SnapshotCase

  import CommonCore.TrivyResourceFactory
  import ControlServerWeb.Trivy.TrivyListTable

  describe "trivy_list_table/1" do
    component_snapshot_test "renders vulnerability report list table" do
      reports = [
        build(:aqua_vulnerability_report, %{
          "metadata" => %{"name" => "test-vuln-report", "namespace" => "default"},
          "report" => %{
            "artifact" => %{"repository" => "nginx"},
            "summary" => %{"criticalCount" => 2, "highCount" => 3, "mediumCount" => 1, "lowCount" => 0}
          }
        })
      ]

      assigns = %{
        id: "vulnerability-reports-table",
        reports: reports,
        columns: [:name, :namespace, :image, :critical, :high, :medium, :low]
      }

      ~H"""
      <.trivy_list_table
        id={@id}
        reports={@reports}
        columns={@columns}
      />
      """
    end

    component_snapshot_test "renders cluster vulnerability report list table" do
      reports = [
        build(:aqua_cluster_vulnerability_report, %{
          "metadata" => %{"name" => "cluster-vuln-report"},
          "report" => %{
            "artifact" => %{"repository" => "kubernetes"},
            "summary" => %{"criticalCount" => 1, "highCount" => 2, "mediumCount" => 0, "lowCount" => 1}
          }
        })
      ]

      assigns = %{
        id: "cluster-vulnerability-reports-table",
        reports: reports,
        columns: [:name, :image, :critical, :high, :medium, :low]
      }

      ~H"""
      <.trivy_list_table
        id={@id}
        reports={@reports}
        columns={@columns}
      />
      """
    end

    component_snapshot_test "renders exposed secret report list table" do
      reports = [
        build(:aqua_exposed_secret_report, %{
          "metadata" => %{"name" => "secret-report", "namespace" => "app-ns"},
          "report" => %{
            "artifact" => %{"repository" => "myapp/backend"},
            "summary" => %{"criticalCount" => 1, "highCount" => 0, "mediumCount" => 1, "lowCount" => 0},
            "secrets" => [%{"title" => "AWS Access Key"}, %{"title" => "GitHub Token"}]
          }
        })
      ]

      assigns = %{
        id: "exposed-secret-reports-table",
        reports: reports,
        columns: [:name, :namespace, :image, :critical, :high, :medium, :low, :secrets]
      }

      ~H"""
      <.trivy_list_table
        id={@id}
        reports={@reports}
        columns={@columns}
      />
      """
    end

    component_snapshot_test "renders sbom report list table" do
      reports = [
        build(:aqua_sbom_report, %{
          "metadata" => %{"name" => "sbom-report", "namespace" => "service-ns"},
          "report" => %{
            "artifact" => %{"repository" => "alpine"},
            "components" => %{
              "components" => [
                %{"name" => "openssl", "version" => "1.1.1"},
                %{"name" => "glibc", "version" => "2.31"}
              ]
            }
          }
        })
      ]

      assigns = %{
        id: "sbom-reports-table",
        reports: reports,
        columns: [:name, :namespace, :image, :components]
      }

      ~H"""
      <.trivy_list_table
        id={@id}
        reports={@reports}
        columns={@columns}
      />
      """
    end

    component_snapshot_test "renders config audit report list table" do
      reports = [
        build(:aqua_config_audit_report, %{
          "metadata" => %{"name" => "config-audit-report", "namespace" => "kube-system"},
          "report" => %{
            "summary" => %{"criticalCount" => 0, "highCount" => 1, "mediumCount" => 2, "lowCount" => 3}
          }
        })
      ]

      assigns = %{
        id: "config-audit-reports-table",
        reports: reports,
        columns: [:name, :namespace, :critical, :high, :medium, :low, :checks]
      }

      ~H"""
      <.trivy_list_table
        id={@id}
        reports={@reports}
        columns={@columns}
      />
      """
    end

    component_snapshot_test "renders rbac assessment report list table" do
      reports = [
        build(:aqua_rbac_assessment_report, %{
          "metadata" => %{"name" => "rbac-report", "namespace" => "kube-system"},
          "report" => %{
            "summary" => %{"criticalCount" => 1, "highCount" => 0, "mediumCount" => 1, "lowCount" => 0},
            "checks" => [
              %{"checkID" => "KSV113", "severity" => "CRITICAL"},
              %{"checkID" => "KSV114", "severity" => "MEDIUM"}
            ]
          }
        })
      ]

      assigns = %{
        id: "rbac-assessment-reports-table",
        reports: reports,
        columns: [:name, :namespace, :critical, :high, :medium, :low, :checks]
      }

      ~H"""
      <.trivy_list_table
        id={@id}
        reports={@reports}
        columns={@columns}
      />
      """
    end

    component_snapshot_test "renders infra assessment report list table" do
      reports = [
        build(:aqua_infra_assessment_report, %{
          "metadata" => %{"name" => "infra-report", "namespace" => "kube-system"},
          "report" => %{
            "summary" => %{"criticalCount" => 0, "highCount" => 2, "mediumCount" => 1, "lowCount" => 1},
            "checks" => [
              %{"checkID" => "CIS-1.1.1", "severity" => "HIGH"},
              %{"checkID" => "CIS-1.1.2", "severity" => "HIGH"},
              %{"checkID" => "CIS-1.2.1", "severity" => "MEDIUM"}
            ]
          }
        })
      ]

      assigns = %{
        id: "infra-assessment-reports-table",
        reports: reports,
        columns: [:name, :namespace, :critical, :high, :medium, :low, :checks]
      }

      ~H"""
      <.trivy_list_table
        id={@id}
        reports={@reports}
        columns={@columns}
      />
      """
    end

    component_snapshot_test "renders empty table" do
      assigns = %{
        id: "empty-reports-table",
        reports: [],
        columns: [:name, :namespace, :critical, :high]
      }

      ~H"""
      <.trivy_list_table
        id={@id}
        reports={@reports}
        columns={@columns}
      />
      """
    end
  end
end
