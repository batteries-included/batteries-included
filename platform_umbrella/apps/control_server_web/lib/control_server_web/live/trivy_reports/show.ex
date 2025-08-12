defmodule ControlServerWeb.Live.TrivyReportShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.TrivyReports.ConfigAuditChecksTable
  import ControlServerWeb.TrivyReports.ExposedSecretsTable
  import ControlServerWeb.TrivyReports.InfraChecksTable
  import ControlServerWeb.TrivyReports.RBACChecksTable
  import ControlServerWeb.TrivyReports.SBOMTable
  import ControlServerWeb.TrivyReports.VulnerabilitiesTable

  alias ControlServerWeb.TrivyURL
  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"name" => name}, uri_string, socket) when socket.assigns.live_action == :cluster_show do
    # Parse the URI to get the path and extract resource type
    uri = URI.parse(uri_string)
    report_type_atom = TrivyURL.parse_cluster_resource_type(uri.path)

    # Cluster resources have no namespace
    report = report(report_type_atom, nil, name)

    {:noreply,
     socket
     |> assign_report(report)
     |> assign_artifact_tag(report)
     |> assign_artifact_repo(report)
     |> assign_vulnerabilities(report)
     |> assign_exposed_secrets(report)
     |> assign_sbom_components(report)
     |> assign_infra_checks(report)
     |> assign_rbac_checks(report)
     |> assign_config_audit_checks(report)
     |> assign_title(format_title(report_type_atom))
     |> assign_report_type(report_type_atom)
     |> assign_name(name)
     |> assign_namespace(nil)
     |> assign_current_page()}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"resource_type" => report_type, "namespace" => namespace, "name" => name}, _, socket) do
    report_type_atom = String.to_existing_atom(report_type)

    # Handle cluster-level resources that have "none" as namespace
    actual_namespace = if namespace == "none", do: nil, else: namespace

    report = report(report_type_atom, actual_namespace, name)

    {:noreply,
     socket
     |> assign_report(report)
     |> assign_artifact_tag(report)
     |> assign_artifact_repo(report)
     |> assign_vulnerabilities(report)
     |> assign_exposed_secrets(report)
     |> assign_sbom_components(report)
     |> assign_infra_checks(report)
     |> assign_rbac_checks(report)
     |> assign_config_audit_checks(report)
     |> assign_title(format_title(report_type_atom))
     |> assign_report_type(report_type_atom)
     |> assign_name(name)
     |> assign_namespace(actual_namespace)
     |> assign_current_page()}
  end

  def assign_title(socket, page_title) do
    assign(socket, :page_title, page_title)
  end

  def assign_name(socket, name) do
    assign(socket, :name, name)
  end

  def assign_namespace(socket, namespace) do
    assign(socket, :namespace, namespace)
  end

  def assign_report_type(socket, report_type) do
    assign(socket, :report_type, report_type)
  end

  def assign_report(socket, report) do
    assign(socket, :report, report)
  end

  def assign_artifact_repo(socket, report) do
    assign(socket, :artifact_repo, get_in(report, ~w(report artifact repository)))
  end

  def assign_artifact_tag(socket, report) do
    assign(socket, :artifact_tag, get_in(report, ~w(report artifact tag)))
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :net_sec)
  end

  def assign_vulnerabilities(socket, report) do
    vulnerabilities = extract_and_sort_vulnerabilities(report)
    assign(socket, :vulnerabilities, vulnerabilities)
  end

  def assign_exposed_secrets(socket, report) do
    exposed_secrets = extract_and_sort_exposed_secrets(report)
    assign(socket, :exposed_secrets, exposed_secrets)
  end

  def assign_sbom_components(socket, report) do
    sbom_components = extract_and_sort_sbom_components(report)
    assign(socket, :sbom_components, sbom_components)
  end

  def assign_infra_checks(socket, report) do
    infra_checks = extract_and_sort_infra_checks(report)
    assign(socket, :infra_checks, infra_checks)
  end

  def assign_rbac_checks(socket, report) do
    rbac_checks = extract_and_sort_rbac_checks(report)
    assign(socket, :rbac_checks, rbac_checks)
  end

  def assign_config_audit_checks(socket, report) do
    config_audit_checks = extract_and_sort_config_audit_checks(report)
    assign(socket, :config_audit_checks, config_audit_checks)
  end

  defp extract_and_sort_vulnerabilities(report) do
    case get_in(report, ~w(report vulnerabilities)) do
      nil -> []
      list when is_list(list) -> Enum.sort_by(list, fn v -> get_in(v, ~w(severity)) end)
      _ -> []
    end
  end

  defp extract_and_sort_exposed_secrets(report) do
    case get_in(report, ~w(report secrets)) do
      nil -> []
      list when is_list(list) -> Enum.sort_by(list, fn s -> get_in(s, ~w(severity)) end)
      _ -> []
    end
  end

  defp extract_and_sort_sbom_components(report) do
    case get_in(report, ~w(report components components)) do
      nil -> []
      list when is_list(list) -> Enum.sort_by(list, fn c -> get_in(c, ~w(name)) end)
      _ -> []
    end
  end

  defp extract_and_sort_infra_checks(report) do
    case get_in(report, ~w(report checks)) do
      nil -> []
      list when is_list(list) -> Enum.sort_by(list, fn c -> get_in(c, ~w(severity)) end, :desc)
      _ -> []
    end
  end

  defp extract_and_sort_rbac_checks(report) do
    case get_in(report, ~w(report checks)) do
      nil -> []
      list when is_list(list) -> Enum.sort_by(list, fn c -> get_in(c, ~w(severity)) end, :desc)
      _ -> []
    end
  end

  defp extract_and_sort_config_audit_checks(report) do
    case get_in(report, ~w(report checks)) do
      nil -> []
      list when is_list(list) -> Enum.sort_by(list, fn c -> get_in(c, ~w(severity)) end, :desc)
      _ -> []
    end
  end

  defp format_title(:aqua_vulnerability_report), do: "Vulnerability Report"
  defp format_title(:aqua_cluster_vulnerability_report), do: "Cluster Vulnerability Report"
  defp format_title(:aqua_exposed_secret_report), do: "Exposed Secrets Report"
  defp format_title(:aqua_sbom_report), do: "SBOM Report"
  defp format_title(:aqua_cluster_sbom_report), do: "Cluster SBOM Report"
  defp format_title(:aqua_config_audit_report), do: "Config Audit Report"
  defp format_title(:aqua_rbac_assessment_report), do: "RBAC Assessment Report"
  defp format_title(:aqua_cluster_rbac_assessment_report), do: "Cluster RBAC Assessment Report"
  defp format_title(:aqua_infra_assessment_report), do: "Infrastructure Assessment Report"
  defp format_title(:aqua_cluster_infra_assessment_report), do: "Cluster Infrastructure Assessment Report"
  defp format_title(_), do: "Trivy Report"

  defp back_link(:aqua_vulnerability_report), do: ~p"/trivy_reports/vulnerability_report"
  defp back_link(:aqua_cluster_vulnerability_report), do: ~p"/trivy_reports/cluster_vulnerability_report"
  defp back_link(:aqua_exposed_secret_report), do: ~p"/trivy_reports/exposed_secret_report"
  defp back_link(:aqua_sbom_report), do: ~p"/trivy_reports/sbom_report"
  defp back_link(:aqua_cluster_sbom_report), do: ~p"/trivy_reports/cluster_sbom_report"
  defp back_link(:aqua_config_audit_report), do: ~p"/trivy_reports/config_audit_report"
  defp back_link(:aqua_rbac_assessment_report), do: ~p"/trivy_reports/rbac_assessment_report"
  defp back_link(:aqua_cluster_rbac_assessment_report), do: ~p"/trivy_reports/cluster_rbac_assessment_report"
  defp back_link(:aqua_infra_assessment_report), do: ~p"/trivy_reports/infra_assessment_report"
  defp back_link(:aqua_cluster_infra_assessment_report), do: ~p"/trivy_reports/cluster_infra_assessment_report"
  defp back_link(_), do: ~p"/trivy_reports/vulnerability_report"

  def report(type, nil, name), do: KubeState.get!(type, nil, name)
  def report(type, namespace, name), do: KubeState.get!(type, namespace, name)

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={back_link(@report_type)}>
      <.badge>
        <:item label="Artifact">{@artifact_repo}/{@artifact_tag}</:item>
        <:item :if={@namespace} label="Namespace">{@namespace}</:item>
        <:item label="Created">
          <.relative_display time={creation_timestamp(@report)} />
        </:item>
      </.badge>
    </.page_header>

    <.panel title={@name}>
      <%= case @report_type do %>
        <% :aqua_vulnerability_report -> %>
          <.vulnerabilities_table rows={@vulnerabilities} />
        <% :aqua_cluster_vulnerability_report -> %>
          <.vulnerabilities_table rows={@vulnerabilities} />
        <% :aqua_exposed_secret_report -> %>
          <.exposed_secrets_table rows={@exposed_secrets} />
        <% :aqua_sbom_report -> %>
          <.sbom_table rows={@sbom_components} />
        <% :aqua_cluster_sbom_report -> %>
          <.sbom_table rows={@sbom_components} />
        <% :aqua_infra_assessment_report -> %>
          <.infra_checks_table rows={@infra_checks} />
        <% :aqua_cluster_infra_assessment_report -> %>
          <.infra_checks_table rows={@infra_checks} />
        <% :aqua_rbac_assessment_report -> %>
          <.rbac_checks_table rows={@rbac_checks} />
        <% :aqua_cluster_rbac_assessment_report -> %>
          <.rbac_checks_table rows={@rbac_checks} />
        <% :aqua_config_audit_report -> %>
          <.config_audit_checks_table rows={@config_audit_checks} />
        <% _ -> %>
          <div class="text-gray-500">
            Report details not yet implemented for this report type.
          </div>
      <% end %>
    </.panel>
    """
  end
end
