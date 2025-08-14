defmodule ControlServerWeb.Trivy.TrivyShowTableTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.Trivy.TrivyShowTable

  describe "trivy_show_table/1" do
    component_snapshot_test "renders vulnerabilities table" do
      vulnerabilities = [
        %{
          "severity" => "HIGH",
          "title" => "Critical security vulnerability in OpenSSL",
          "primaryLink" => "https://avd.aquasec.com/nvd/cve-2023-12345",
          "resource" => "openssl",
          "installedVersion" => "1.1.1k",
          "fixedVersion" => "1.1.1l"
        }
      ]

      assigns = %{
        id: "vulnerabilities-table",
        type: :vulnerabilities,
        rows: vulnerabilities
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end

    component_snapshot_test "renders exposed secrets table" do
      secrets = [
        %{
          "severity" => "CRITICAL",
          "title" => "AWS Access Key",
          "ruleID" => "aws-access-key-id",
          "category" => "secret",
          "match" => "AKIA****EXAMPLE"
        }
      ]

      assigns = %{
        id: "exposed-secrets-table",
        type: :exposed_secrets,
        rows: secrets
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end

    component_snapshot_test "renders rbac checks table" do
      checks = [
        %{
          "severity" => "CRITICAL",
          "checkID" => "KSV113",
          "title" => "Dangerous RBAC permission",
          "category" => "Kubernetes Security Check",
          "success" => false,
          "description" => "Role shouldn't have dangerous permission on cluster level",
          "messages" => ["Role has dangerous permission '*' on '*'"],
          "remediation" => "Remove dangerous permissions from the role"
        }
      ]

      assigns = %{
        id: "rbac-checks-table",
        type: :rbac_checks,
        rows: checks
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end

    component_snapshot_test "renders config audit checks table" do
      checks = [
        %{
          "severity" => "MEDIUM",
          "checkID" => "KSV020",
          "title" => "Pod should set security context",
          "category" => "Kubernetes Security Check",
          "success" => false,
          "description" => "Pod containers should set security context to improve security",
          "remediation" => "Set securityContext in pod specification"
        }
      ]

      assigns = %{
        id: "config-audit-checks-table",
        type: :config_audit_checks,
        rows: checks
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end

    component_snapshot_test "renders infra checks table" do
      checks = [
        %{
          "severity" => "HIGH",
          "checkID" => "CIS-1.1.1",
          "title" => "Ensure API server is secured",
          "category" => "Kubernetes Security Check",
          "success" => false,
          "description" => "API server should use secure configuration"
        }
      ]

      assigns = %{
        id: "infra-checks-table",
        type: :infra_checks,
        rows: checks
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end

    component_snapshot_test "renders sbom components table" do
      components = [
        %{
          "name" => "openssl",
          "version" => "1.1.1k",
          "type" => "library",
          "group" => "security"
        }
      ]

      assigns = %{
        id: "sbom-components-table",
        type: :sbom_components,
        rows: components
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end

    component_snapshot_test "renders empty vulnerabilities table" do
      assigns = %{
        id: "empty-vulnerabilities-table",
        type: :vulnerabilities,
        rows: []
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end

    component_snapshot_test "renders empty exposed secrets table" do
      assigns = %{
        id: "empty-secrets-table",
        type: :exposed_secrets,
        rows: []
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end

    component_snapshot_test "renders empty rbac checks table" do
      assigns = %{
        id: "empty-rbac-table",
        type: :rbac_checks,
        rows: []
      }

      ~H"""
      <.trivy_show_table
        id={@id}
        type={@type}
        rows={@rows}
      />
      """
    end
  end
end
