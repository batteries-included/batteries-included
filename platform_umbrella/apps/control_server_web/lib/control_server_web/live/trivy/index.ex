defmodule ControlServerWeb.Live.TrivyReportsIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Trivy.TrivyListTable

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    live_action = socket.assigns.live_action

    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(live_action)
    end

    {:ok,
     socket
     |> assign(:current_action, live_action)
     |> assign(:objects, objects(live_action))
     |> assign(:page_title, title_text(live_action))
     |> assign_current_page()}
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

    case Map.get(socket.assigns, :current_action) do
      nil ->
        :ok

      topic ->
        # unsubscribe from previous resource
        KubeEventCenter.unsubscribe(topic)
    end

    # subscribe to current resource
    :ok = KubeEventCenter.subscribe(live_action)

    {:noreply,
     socket
     |> assign(:current_action, live_action)
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

  defp title_text(:aqua_cluster_infra_assessment_report) do
    "Cluster Kube Infra Report"
  end

  defp title_text(:aqua_exposed_secret_report) do
    "Exposed Secrets Report"
  end

  defp title_text(:aqua_sbom_report) do
    "SBOM Report"
  end

  defp title_text(:aqua_cluster_sbom_report) do
    "Cluster SBOM Report"
  end

  defp title_text(:aqua_cluster_vulnerability_report) do
    "Cluster Vulnerability Report"
  end

  defp title_text(:aqua_vulnerability_report) do
    "Vulnerability Report"
  end

  @report_tabs [
    {"Vulnerability", "/trivy_reports/vulnerability_report", :aqua_vulnerability_report},
    {"Cluster Vuln", "/trivy_reports/cluster_vulnerability_report", :aqua_cluster_vulnerability_report},
    {"Exposed Secrets", "/trivy_reports/exposed_secret_report", :aqua_exposed_secret_report},
    {"SBOM", "/trivy_reports/sbom_report", :aqua_sbom_report},
    {"Cluster SBOM", "/trivy_reports/cluster_sbom_report", :aqua_cluster_sbom_report},
    {"Config Audit", "/trivy_reports/config_audit_report", :aqua_config_audit_report},
    {"RBAC", "/trivy_reports/rbac_assessment_report", :aqua_rbac_assessment_report},
    {"Cluster RBAC", "/trivy_reports/cluster_rbac_assessment_report", :aqua_cluster_rbac_assessment_report},
    {"Kube Infra", "/trivy_reports/infra_assessment_report", :aqua_infra_assessment_report},
    {"Cluster Infra", "/trivy_reports/cluster_infra_assessment_report", :aqua_cluster_infra_assessment_report}
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
        <.trivy_list_table
          id="config-audit-reports-table"
          reports={@objects}
          columns={[:name, :namespace, :critical, :high, :medium, :low, :checks]}
        />
      <% :aqua_cluster_rbac_assessment_report -> %>
        <.trivy_list_table
          id="cluster-rbac-assessment-reports-table"
          reports={@objects}
          columns={[:name, :critical, :high, :medium, :low, :checks]}
        />
      <% :aqua_rbac_assessment_report -> %>
        <.trivy_list_table
          id="rbac-assessment-reports-table"
          reports={@objects}
          columns={[:name, :namespace, :critical, :high, :medium, :low, :checks]}
        />
      <% :aqua_infra_assessment_report -> %>
        <.trivy_list_table
          id="infra-assessment-reports-table"
          reports={@objects}
          columns={[:name, :namespace, :critical, :high, :medium, :low, :checks]}
        />
      <% :aqua_cluster_infra_assessment_report -> %>
        <.trivy_list_table
          id="cluster-infra-assessment-reports-table"
          reports={@objects}
          columns={[:name, :critical, :high, :medium, :low, :checks]}
        />
      <% :aqua_exposed_secret_report -> %>
        <.trivy_list_table
          id="exposed-secret-reports-table"
          reports={@objects}
          columns={[:name, :namespace, :image, :critical, :high, :medium, :low]}
        />
      <% :aqua_sbom_report -> %>
        <.trivy_list_table
          id="sbom-reports-table"
          reports={@objects}
          columns={[:name, :namespace, :image, :components]}
        />
      <% :aqua_cluster_sbom_report -> %>
        <.trivy_list_table
          id="cluster-sbom-reports-table"
          reports={@objects}
          columns={[:name, :image, :components]}
        />
      <% :aqua_cluster_vulnerability_report -> %>
        <.trivy_list_table
          id="cluster-vulnerability-reports-table"
          reports={@objects}
          columns={[:name, :image, :critical, :high, :medium, :low]}
        />
      <% :aqua_vulnerability_report -> %>
        <.trivy_list_table
          id="vulnerability-reports-table"
          reports={@objects}
          columns={[:name, :namespace, :image, :critical, :high, :medium, :low]}
        />
    <% end %>
    """
  end
end
