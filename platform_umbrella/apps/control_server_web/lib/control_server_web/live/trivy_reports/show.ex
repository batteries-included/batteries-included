defmodule ControlServerWeb.Live.TrivyReportShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.TrivyReports.VulnerabilitiesTable

  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"resource_type" => report_type, "namespace" => namespace, "name" => name}, _, socket) do
    report_type_atom = String.to_existing_atom(report_type)
    report = report(report_type_atom, namespace, name)

    {:noreply,
     socket
     |> assign_report(report)
     |> assign_artifact_tag(report)
     |> assign_artifact_repo(report)
     |> assign_vulnerabilities(report)
     |> assign_title("Trivy Report")
     |> assign_report_type(report_type_atom)
     |> assign_name(name)
     |> assign_current_page()}
  end

  def assign_title(socket, page_title) do
    assign(socket, :page_title, page_title)
  end

  def assign_name(socket, name) do
    assign(socket, :name, name)
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
    assign(
      socket,
      :vulnerabilities,
      report
      |> get_in(~w(report vulnerabilities))
      |> Enum.sort_by(fn v -> get_in(v, ~w(severity)) end)
    )
  end

  def report(type, namespace, name), do: KubeState.get!(type, namespace, name)

  @impl Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/trivy_reports/vulnerability_report"}>
      <.badge>
        <:item label="Artifact">{@artifact_repo}/{@artifact_tag}</:item>
        <:item label="Created">
          <.relative_display time={creation_timestamp(@report)} />
        </:item>
      </.badge>
    </.page_header>

    <.panel title={@name}>
      <.vulnerabilities_table rows={@vulnerabilities} />
    </.panel>
    """
  end
end
