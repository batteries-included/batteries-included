defmodule ControlServerWeb.Live.TrivyReportsIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ConfigAuditReportTable
  import ControlServerWeb.InfraAssessmentReportTable
  import ControlServerWeb.RBACReportTable
  import ControlServerWeb.VulnerabilityReportTable

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    live_action = socket.assigns.live_action
    subscribe(live_action)

    {:ok,
     socket
     |> assign(:objects, objects(live_action))
     |> assign(:page_title, title_text(live_action))
     |> assign_current_page()}
  end

  defp subscribe(resource_type) do
    :ok = KubeEventCenter.subscribe(resource_type)
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :net_sec)
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign(socket, :objects, objects(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    live_action = socket.assigns.live_action

    {:noreply,
     socket
     |> assign(:objects, objects(live_action))
     |> assign(:page_title, title_text(live_action))}
  end

  defp objects(type) do
    type
    |> KubeState.get_all()
    |> Enum.sort_by(fn r -> get_in(r, ~w(report summary highCount)) end, :desc)
    |> Enum.sort_by(fn r -> get_in(r, ~w(report summary criticalCount)) end, :desc)
  end

  defp title_text(:aqua_config_audit_report) do
    "Audit Report"
  end

  defp title_text(:aqua_cluster_rbac_assessment_report) do
    "Cluster RBAC Report"
  end

  defp title_text(:aqua_rbac_assessment_report) do
    "RBAC Report"
  end

  defp title_text(:aqua_infra_assessment_report) do
    "Kube Infra Report"
  end

  defp title_text(:aqua_vulnerability_report) do
    "Vulnerability Report"
  end

  @report_tabs [
    {"Audit", "/trivy_reports/config_audit_report", :aqua_config_audit_report},
    {"Cluster RBAC", "/trivy_reports/cluster_rbac_assessment_report", :aqua_cluster_rbac_assessment_report},
    {"RBAC", "/trivy_reports/rbac_assessment_report", :aqua_rbac_assessment_report},
    {"Kube Infra", "/trivy_reports/infra_assessment_report", :aqua_infra_assessment_report},
    {"Vulnerability", "/trivy_reports/vulnerability_report", :aqua_vulnerability_report}
  ]

  defp report_tabs, do: @report_tabs

  defp tabs(assigns) do
    ~H"""
    <.tab_bar>
      <:tab
        :for={{title, path, live_action} <- report_tabs()}
        selected={@live_action == live_action}
        patch={path}
      >
        {title}
      </:tab>
    </.tab_bar>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.tabs live_action={@live_action} />
    <%= case @live_action do %>
      <% :aqua_config_audit_report -> %>
        <.config_audit_reports_table reports={@objects} />
      <% :aqua_cluster_rbac_assessment_report -> %>
        <.cluster_rbac_reports_table reports={@objects} />
      <% :aqua_rbac_assessment_report -> %>
        <.rbac_reports_table reports={@objects} />
      <% :aqua_infra_assessment_report -> %>
        <.infra_assessment_reports_table reports={@objects} />
      <% :aqua_vulnerability_report -> %>
        <.vulnerability_reports_table reports={@objects} />
    <% end %>
    """
  end
end
