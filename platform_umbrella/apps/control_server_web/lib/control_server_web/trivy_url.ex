defmodule ControlServerWeb.TrivyURL do
  @moduledoc """
  Utilities for creating and parsing Trivy report URLs.

  This module centralizes URL generation for both cluster-wide and namespaced
  trivy resources, ensuring consistent URL patterns across the application.
  """

  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  alias CommonCore.ApiVersionKind

  @doc """
  Generates a show URL for a trivy report resource.

  Automatically determines if the resource is cluster-wide or namespaced
  and generates the appropriate URL pattern.

  ## Examples

      iex> report_url(cluster_rbac_report)
      "/trivy_reports/clusterrbacassessmentreports/report-name"

      iex> report_url(namespaced_config_audit_report)
      "/trivy_reports/aqua_config_audit_report/namespace/report-name"
  """
  def report_url(report) do
    kind = ApiVersionKind.resource_type!(report)

    if cluster_resource?(kind) do
      cluster_report_url(report, kind)
    else
      namespaced_report_url(report, kind)
    end
  end

  @doc """
  Parses a cluster trivy report URL path to extract the resource type atom.

  ## Examples

      iex> parse_cluster_resource_type("/trivy_reports/clusterrbacassessmentreports/report-name")
      :aqua_cluster_rbac_assessment_report
  """
  def parse_cluster_resource_type(path) do
    case path do
      "/trivy_reports/clustercompliancereports/" <> _ -> :aqua_cluster_compliance_report
      "/trivy_reports/clusterconfigauditreports/" <> _ -> :aqua_cluster_config_audit_config_report
      "/trivy_reports/clusterinfraassessmentreports/" <> _ -> :aqua_cluster_infra_assesment_report
      "/trivy_reports/clusterrbacassessmentreports/" <> _ -> :aqua_cluster_rbac_assessment_report
      "/trivy_reports/clustersbomreports/" <> _ -> :aqua_cluster_sbom_report
      "/trivy_reports/clustervulnerabilityreports/" <> _ -> :aqua_cluster_vulnerability_report
    end
  end

  # Private functions

  defp cluster_resource?(kind) do
    kind in [
      :aqua_cluster_compliance_report,
      :aqua_cluster_config_audit_config_report,
      :aqua_cluster_infra_assesment_report,
      :aqua_cluster_rbac_assessment_report,
      :aqua_cluster_sbom_report,
      :aqua_cluster_vulnerability_report
    ]
  end

  defp cluster_report_url(report, kind) do
    resource_name = cluster_resource_name(kind)
    "/trivy_reports/#{resource_name}/#{name(report)}"
  end

  defp namespaced_report_url(report, kind) do
    "/trivy_reports/#{kind}/#{namespace(report)}/#{name(report)}"
  end

  defp cluster_resource_name(kind) do
    case kind do
      :aqua_cluster_compliance_report -> "clustercompliancereports"
      :aqua_cluster_config_audit_config_report -> "clusterconfigauditreports"
      :aqua_cluster_infra_assesment_report -> "clusterinfraassessmentreports"
      :aqua_cluster_rbac_assessment_report -> "clusterrbacassessmentreports"
      :aqua_cluster_sbom_report -> "clustersbomreports"
      :aqua_cluster_vulnerability_report -> "clustervulnerabilityreports"
      # fallback for unknown cluster types
      _ -> Atom.to_string(kind)
    end
  end
end
